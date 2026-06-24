// Faithful OCaml Marshal encoder: the inverse of `decoder.mbt`, producing
// bytes byte-identical to OCaml 4.14.1 `Marshal.to_string v []` (default
// flags, i.e. with sharing) for the supported value types. Mirrors
// runtime/extern.c: smallest-fit encodings, the shared-object position table
// (backward-distance references), heap-word size accounting, and the 20-byte
// "small" header.
//
// Endianness note: floats are written in the platform-native order. These
// constants assume a little-endian host (x86-64 / arm64), matching
// `CODE_DOUBLE_NATIVE` on such platforms.

///|
priv struct MarshalEncoder {
  body : Array[Byte]
  // (node, position) for every recorded shareable object, in record order.
  // OCaml keeps an address-keyed hash table; a linear scan with
  // `physical_equal` is the simplest faithful equivalent (see `lookup`).
  shared : Array[(MarshalValue, Int)]
  mut obj_counter : Int // number of recorded objects (== OCaml obj_counter)
  mut size_32 : Int // heap words if read back on a 32-bit platform
  mut size_64 : Int // heap words if read back on a 64-bit platform
}

///|
fn MarshalEncoder::new() -> Self {
  { body: [], shared: [], obj_counter: 0, size_32: 0, size_64: 0 }
}

// --- Low-level big-endian writers into the body buffer ---

///|
fn MarshalEncoder::w8(self : Self, n : Int) -> Unit {
  self.body.push((n & 0xFF).to_byte())
}

///|
fn MarshalEncoder::w16(self : Self, n : Int) -> Unit {
  self.w8(n >> 8)
  self.w8(n)
}

///|
fn MarshalEncoder::w32(self : Self, n : Int) -> Unit {
  self.w8(n >> 24)
  self.w8(n >> 16)
  self.w8(n >> 8)
  self.w8(n)
}

///|
fn MarshalEncoder::w64(self : Self, n : Int64) -> Unit {
  for shift = 56; shift >= 0; shift = shift - 8 {
    self.w8((n >> shift).to_int())
  }
}

///|
/// Writes a double in little-endian order (native on x86-64 / arm64).
fn MarshalEncoder::w_double(self : Self, d : Double) -> Unit {
  let bits = d.reinterpret_as_int64()
  for shift = 0; shift < 64; shift = shift + 8 {
    self.w8((bits >> shift).to_int())
  }
}

// --- Code-tag emitters (mirror extern.c) ---

///|
fn MarshalEncoder::emit_int(self : Self, n : Int) -> Unit {
  if n >= 0 && n < 0x40 {
    self.w8(0x40 + n) // PREFIX_SMALL_INT
  } else if n >= -128 && n < 128 {
    self.w8(0x00) // CODE_INT8
    self.w8(n)
  } else if n >= -32768 && n < 32768 {
    self.w8(0x01) // CODE_INT16
    self.w16(n)
  } else if n < -(1 << 30) || n >= 1 << 30 {
    // 64-bit OCaml encodes ints of magnitude >= 2^30 as CODE_INT64.
    self.w8(0x03) // CODE_INT64
    self.w64(n.to_int64())
  } else {
    self.w8(0x02) // CODE_INT32
    self.w32(n)
  }
}

///|
fn MarshalEncoder::emit_string(self : Self, b : Bytes) -> Unit {
  let len = b.length()
  if len < 0x20 {
    self.w8(0x20 + len) // PREFIX_SMALL_STRING
  } else if len < 0x100 {
    self.w8(0x09) // CODE_STRING8
    self.w8(len)
  } else {
    self.w8(0x0A) // CODE_STRING32
    self.w32(len)
  }
  for byte in b {
    self.body.push(byte)
  }
  self.size_32 += 1 + (len + 4) / 4
  self.size_64 += 1 + (len + 8) / 8
}

///|
fn MarshalEncoder::emit_double(self : Self, d : Double) -> Unit {
  self.w8(0x0C) // CODE_DOUBLE_LITTLE (native)
  self.w_double(d)
  self.size_32 += 1 + 2
  self.size_64 += 1 + 1
}

///|
fn MarshalEncoder::emit_double_array(self : Self, a : Array[Double]) -> Unit {
  let n = a.length()
  if n < 0x100 {
    self.w8(0x0E) // CODE_DOUBLE_ARRAY8_LITTLE (native)
    self.w8(n)
  } else {
    self.w8(0x07) // CODE_DOUBLE_ARRAY32_LITTLE (native)
    self.w32(n)
  }
  for d in a {
    self.w_double(d)
  }
  self.size_32 += 1 + n * 2
  self.size_64 += 1 + n
}

///|
/// In-memory heap size (`bytes_32`, `bytes_64`) of a supported custom block,
/// used for the size accounting (NOT the serialized payload length). Matches
/// the `custom_fixed_length` values in OCaml runtime/ints.c.
fn custom_inmem_size(identifier : String) -> (Int, Int) raise {
  match identifier {
    "_i" => (4, 4) // Int32
    "_j" => (8, 8) // Int64
    "_n" => (4, 8) // Nativeint
    _ => fail("marshal: unsupported custom block identifier: \{identifier}")
  }
}

///|
/// Emits a custom block as `CODE_CUSTOM_FIXED`, the form OCaml uses for the
/// fixed-size scalars int32/int64/nativeint: code, null-terminated identifier,
/// then the raw serialized payload (for nativeint this already includes the
/// leading width tag, as stored by the decoder).
fn MarshalEncoder::emit_custom(
  self : Self,
  identifier : String,
  payload : Bytes,
) -> Unit raise {
  let (sz_32, sz_64) = custom_inmem_size(identifier)
  self.w8(0x19) // CODE_CUSTOM_FIXED
  for c in identifier {
    self.w8(c.to_int())
  }
  self.w8(0x00) // null terminator
  for byte in payload {
    self.body.push(byte)
  }
  self.size_32 += 2 + ((sz_32 + 3) >> 2) // header + ops + data words
  self.size_64 += 2 + ((sz_64 + 7) >> 3)
}

///|
/// Emits a block header (PREFIX_SMALL_BLOCK or CODE_BLOCK32/64). The OCaml
/// header word is `(size << 10) | tag` (GC color 0).
fn MarshalEncoder::emit_block_header(
  self : Self,
  tag : Int,
  size : Int,
) -> Unit {
  if tag < 16 && size < 8 {
    self.w8(0x80 + tag + (size << 4)) // PREFIX_SMALL_BLOCK
  } else {
    let hd = (size << 10) | tag
    self.w8(0x08) // CODE_BLOCK32
    self.w32(hd)
  }
}

// --- Sharing table ---

///|
/// Returns the recorded position of a physically-identical earlier object, or
/// `None`. Uses `physical_equal` to match OCaml's address-based sharing.
fn MarshalEncoder::lookup(self : Self, v : MarshalValue) -> Int? {
  for entry in self.shared {
    let (node, pos) = entry
    if physical_equal(node, v) {
      return Some(pos)
    }
  }
  None
}

///|
fn MarshalEncoder::record(self : Self, v : MarshalValue) -> Unit {
  self.shared.push((v, self.obj_counter))
  self.obj_counter += 1
}

///|
fn MarshalEncoder::emit_shared(self : Self, distance : Int) -> Unit {
  if distance < 0x100 {
    self.w8(0x04) // CODE_SHARED8
    self.w8(distance)
  } else if distance < 0x10000 {
    self.w8(0x05) // CODE_SHARED16
    self.w16(distance)
  } else {
    self.w8(0x06) // CODE_SHARED32
    self.w32(distance)
  }
}

///|
/// Returns true for values OCaml represents as atoms (size-0 blocks), which
/// are written inline, never shared, and not counted in `obj_counter`.
fn is_atom(v : MarshalValue) -> Bool {
  match v {
    MBlock(fields, ..) => fields.length() == 0
    MDoubleArray(a) => a.length() == 0
    _ => false
  }
}

///|
fn MarshalEncoder::encode(self : Self, v : MarshalValue) -> Unit raise {
  match v {
    MInt(n) => self.emit_int(n)
    _ =>
      if is_atom(v) {
        // Atom (empty block / empty float array): inline 0-size header only.
        let tag = match v {
          MDoubleArray(_) => 254 // Double_array_tag
          MBlock(tag~, _) => tag
          _ => 0
        }
        self.emit_block_header(tag, 0)
      } else {
        match self.lookup(v) {
          Some(pos) => self.emit_shared(self.obj_counter - pos)
          None =>
            match v {
              MString(b) => {
                self.emit_string(b)
                self.record(v)
              }
              MFloat(d) => {
                self.emit_double(d)
                self.record(v)
              }
              MDoubleArray(a) => {
                self.emit_double_array(a)
                self.record(v)
              }
              MBlock(tag~, fields) => {
                let sz = fields.length()
                self.emit_block_header(tag, sz)
                self.size_32 += 1 + sz
                self.size_64 += 1 + sz
                // Record before recursing so cyclic refs point back here.
                self.record(v)
                for field in fields {
                  self.encode(field)
                }
              }
              MCustom(identifier, payload) => {
                self.emit_custom(identifier, payload)
                self.record(v)
              }
              MInt(_) => abort("unreachable: MInt handled above")
            }
        }
      }
  }
}

///|
/// Serializes a `MarshalValue` to OCaml Marshal wire format (small header),
/// byte-identical to `Marshal.to_string v []` for supported types.
pub fn marshal(value : MarshalValue) -> Bytes raise {
  let enc = MarshalEncoder::new()
  enc.encode(value)
  let out : Array[Byte] = []
  fn push32(n : Int) {
    out.push(((n >> 24) & 0xFF).to_byte())
    out.push(((n >> 16) & 0xFF).to_byte())
    out.push(((n >> 8) & 0xFF).to_byte())
    out.push((n & 0xFF).to_byte())
  }

  push32(0x8495A6BE) // small magic number
  push32(enc.body.length()) // data length
  push32(enc.obj_counter) // number of shared objects
  push32(enc.size_32) // size in words on a 32-bit platform
  push32(enc.size_64) // size in words on a 64-bit platform
  for byte in enc.body {
    out.push(byte)
  }
  Bytes::from_array(out)
}
