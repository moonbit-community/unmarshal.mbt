// Prefix tags for compact representations

///|
// const PREFIX_SMALL_STRING : Byte = 0x20

///|
// const PREFIX_SMALL_BLOCK : Byte = 0x80

// Code tags for various data types

///|
// const CODE_INT8 : Byte = 0x00

///|
// const CODE_INT16 : Byte = 0x01

///|
// const CODE_INT32 : Byte = 0x02

///|
// const CODE_INT64 : Byte = 0x03

///|
const CODE_SHARED8 : Byte = 0x04

///|
const CODE_SHARED16 : Byte = 0x05

///|
const CODE_SHARED32 : Byte = 0x06

///|
const CODE_SHARED64 : Byte = 0x14

///|
const CODE_BLOCK32 : Byte = 0x08

///|
const CODE_BLOCK64 : Byte = 0x13

///|
const CODE_STRING8 : Byte = 0x09

///|
const CODE_STRING32 : Byte = 0x0A

///|
const CODE_STRING64 : Byte = 0x15

///|
const CODE_DOUBLE_BIG : Byte = 0x0B

///|
const CODE_DOUBLE_LITTLE : Byte = 0x0C

///|
const CODE_DOUBLE_ARRAY8_BIG : Byte = 0x0D

///|
const CODE_DOUBLE_ARRAY8_LITTLE : Byte = 0x0E

///|
const CODE_DOUBLE_ARRAY32_BIG : Byte = 0x0F

///|
const CODE_DOUBLE_ARRAY32_LITTLE : Byte = 0x07

///|
const CODE_DOUBLE_ARRAY64_BIG : Byte = 0x16

///|
const CODE_DOUBLE_ARRAY64_LITTLE : Byte = 0x17

///|
// Code pointers - not yet implemented
// const CODE_CODEPOINTER : Byte = 0x10

///|
// Infix pointers - not yet implemented
// const CODE_INFIXPOINTER : Byte = 0x11

///|
const CODE_CUSTOM_LEN : Byte = 0x18

///|
const CODE_CUSTOM_FIXED : Byte = 0x19

// Legacy tags (kept for reference)

///|
// OCaml internal tag for integers
// const Tag_int : Byte = 0x01

///|
// OCaml internal tag for pointers
// const Tag_pointer : Byte = 0x02

///|
// OCaml internal tag for strings
// const Tag_string : Byte = 0x09

///|
// OCaml internal tag for doubles
// const Tag_double : Byte = 0x0C

///|
// OCaml internal tag for double arrays
// const Tag_double_array : Byte = 0x0D

///|
// OCaml internal tag for custom blocks
// const Tag_custom : Byte = 0x12

///|
// OCaml internal tag for int64 values
// const Tag_int64 : Byte = 0x13

///|
// OCaml internal tag for shared values
// const Tag_shared : Byte = 0x04

///|
// OCaml internal tag for blocks
// const Tag_block : Byte = 0x10

///|
struct Decoder {
  object_array : Array[MarshalValue] // Shared object array - mutated via methods
  mut position : Int // Current parsing position
  data : Bytes
}

///|
pub fn Decoder::new(data : Bytes) -> Self {
  Decoder::{ object_array: [], position: 0, data }
}

///|
fn Decoder::view(self : Self) -> BytesView {
  self.data[self.position:]
}

///|
fn Decoder::update_view(self : Self, view : BytesView) -> Unit {
  self.position = view.start_offset()
}

///|
/// Adds a decoded object to the shared object array
/// 
/// Every decoded object (except shared references) is automatically registered
/// in the shared object array. This enables OCaml's sharing mechanism where
/// later references can point back to previously decoded objects.
/// 
/// ## Parameters
/// - `state`: Decoder state containing the shared object array
/// - `value`: The decoded MarshalValue to register
/// 
/// ## Returns
/// Nothing – the decoder stores the value for future shared references
/// 
fn Decoder::add_shared_object(state : Decoder, value : MarshalValue) -> Unit {
  state.object_array.push(value)
}

///|
/// Retrieves a previously decoded object from the shared object table
/// 
/// Used when encountering a shared reference (tag_shared) that points back
/// to an object decoded earlier in the stream. This is essential for OCaml's
/// sharing mechanism and cyclic reference support.
/// 
/// ## Parameters
/// - `state`: Decoder state containing the shared object table
/// - `distance`: Backward distance to the target object (>= 1)
///
/// ## Returns
/// The MarshalValue referenced by the shared pointer
///
/// ## Panics
/// Aborts if the distance is out of bounds (invalid shared reference)
///
/// ## Format note
/// OCaml encodes shared references as a *backward distance* from the current
/// object counter, not as an absolute forward index. At the point a shared
/// reference is read, `object_array` holds exactly the objects registered so
/// far (this count equals `obj_counter` in OCaml's runtime), so the target is
/// `object_array.length() - distance`. See `runtime/intern.c` in the OCaml
/// sources: `v = intern_obj_table[obj_counter - ofs]`.
fn get_shared_object(state : Decoder, distance : Int) -> MarshalValue raise {
  let index = state.object_array.length() - distance
  if distance < 1 || index < 0 {
    fail(
      "Invalid shared object reference: distance \{distance}, table size \{state.object_array.length()}",
    )
  }
  state.object_array[index]
}

///|
/// Parses the 20-byte OCaml Marshal format header
/// 
/// The header contains essential metadata about the marshaled data including
/// format validation, data size, and platform compatibility information.
/// 
/// ## Header Structure (20 bytes)
/// ``` text
/// [0-3]:   Magic number (0x8495A6BE little-endian, 0x8495A6BF big-endian)
/// [4-7]:   Data length (bytes following header)
/// [8-11]:  Number of objects that can be shared
/// [12-15]: Size of integers/pointers on 32-bit platform
/// [16-19]: Size of integers/pointers on 64-bit platform
/// ```
/// 
/// ## Parameters
/// - `data`: Byte view containing at least 20 bytes of marshal data
/// 
/// ## Returns
/// Parsed and validated MarshalHeader structure
/// 
/// ## Panics
/// - If data is shorter than 20 bytes
/// - If magic number is invalid (not a recognized OCaml marshal format)
/// 
/// ## Example
/// ``` text
/// let data = // ... marshal data bytes
/// let header = parse_marshal_header(data[:])
/// println("Data length: " + header.data_len.to_string())
/// ```
pub fn Decoder::decode_header(data : Self) -> MarshalHeader raise {
  match data.view() {
    [
      u32be(0x8495A6BE | 0x8495A6BF as magic),
      i32be(data_len),
      i32be(num_objects),
      i32be(size_32),
      i32be(size_64),
      .. rest,
    ] => {
      // TODO(upstream): improve error message when missing `{` and `}`
      data.update_view(rest)
      { magic, data_len, num_objects, size_32, size_64 }
    }
    _ => fail("Failed to parse marshal header")
  }
}

///|
pub fn Decoder::decode(self : Self) -> (MarshalHeader, MarshalValue) raise {
  let header = self.decode_header()
  let value = self.decode_value()
  (header, value)
}

///|
pub fn Decoder::decode_value(self : Self) -> MarshalValue raise {
  match self.view() {
    // Small integers (0-63): encoded as PREFIX_SMALL_INT + value
    [0x40..=0x7F as b, .. rest] => {
      self.update_view(rest)
      let value = b.to_int() - 0x40
      MInt(value)
    }
    // INT8: 8-bit signed integer
    [0x00, i8be(value), .. rest] => {
      self.update_view(rest)
      MInt(value)
    }

    // INT16: 16-bit signed integer (big-endian)
    [0x01, i16be(value), .. rest] => {
      self.update_view(rest)
      MInt(value)
    }

    // INT32: 32-bit signed integer (big-endian)
    [0x02, i32be(value), .. rest] => {
      self.update_view(rest)
      MInt(value)
    }

    // INT64: 64-bit signed integer (big-endian)
    [0x03, i64be(value), .. rest] => {
      // TODO: accomodate 64-bit platforms
      self.update_view(rest)
      MInt(value.to_int())
    }

    // Small strings (length < 32): PREFIX_SMALL_STRING + length
    [0x20..=0x3F as b, .. rest] => {
      self.update_view(rest)
      let len = b.to_int() - 0x20
      self.decode_string_with_length(len)
    }

    // STRING8: String with 8-bit length
    [CODE_STRING8, len_byte, .. rest] => {
      self.update_view(rest)
      self.decode_string_with_length(len_byte.to_int())
    }

    // STRING32: String with 32-bit length
    [CODE_STRING32, u32be(length), .. rest] => {
      self.update_view(rest)
      self.decode_string_with_length(length.reinterpret_as_int())
    }

    // STRING64: String with 64-bit length (64-bit platforms only)
    [CODE_STRING64, u64be(length), .. rest] => {
      self.update_view(rest)
      self.decode_string_with_length(length.reinterpret_as_int64().to_int())
    }
    // Small blocks (tag < 16, size < 8): PREFIX_SMALL_BLOCK + tag + (size << 4)
    [0x80..=0xFF as b, .. rest] => {
      self.update_view(rest)
      let byte_val = b.to_int() - 0x80
      let tag = byte_val & 0x0F // Lower 4 bits
      let size = byte_val >> 4 // Upper 4 bits
      self.decode_block_with_tag_size(tag, size)
    }
    // BLOCK32: Block with 32-bit header
    [CODE_BLOCK32, u32be(header), .. rest] => {
      self.update_view(rest)
      // OCaml header format: size in high bits, tag in low 8 bits
      let hdr = header.reinterpret_as_int()
      let tag = hdr & 0xFF
      let size = hdr >> 10 // Size is stored starting at bit 10
      self.decode_block_with_tag_size(tag, size)
    }

    // BLOCK64: Block with 64-bit header (64-bit platforms only)
    [CODE_BLOCK64, u64be(header), .. rest] => {
      self.update_view(rest)
      let hdr = header.reinterpret_as_int64().to_int()
      let tag = hdr & 0xFF
      let size = hdr >> 10
      self.decode_block_with_tag_size(tag, size)
    }

    // Double/Float
    [CODE_DOUBLE_LITTLE | CODE_DOUBLE_BIG as code, .. rest] => {
      self.update_view(rest)
      self.decode_double(code == CODE_DOUBLE_BIG)
    }

    // Double Arrays with 8-bit count
    [
      CODE_DOUBLE_ARRAY8_LITTLE
      | CODE_DOUBLE_ARRAY8_BIG as code,
      count_byte,
      .. rest,
    ] => {
      let count = count_byte.to_int()
      self.update_view(rest)
      self.decode_double_array(count, code == CODE_DOUBLE_ARRAY8_BIG)
    }

    // Double Arrays with 32-bit count
    [
      CODE_DOUBLE_ARRAY32_LITTLE
      | CODE_DOUBLE_ARRAY32_BIG as code,
      u32be(count),
      .. rest,
    ] => {
      self.update_view(rest)
      self.decode_double_array(
        count.reinterpret_as_int(),
        code == CODE_DOUBLE_ARRAY32_BIG,
      )
    }

    // Double Arrays with 64-bit count
    [
      CODE_DOUBLE_ARRAY64_LITTLE
      | CODE_DOUBLE_ARRAY64_BIG as code,
      u64be(count),
      .. rest,
    ] => {
      self.update_view(rest)
      self.decode_double_array(
        count.reinterpret_as_int64().to_int(),
        code == CODE_DOUBLE_ARRAY64_BIG,
      )
    }

    // Shared references
    [CODE_SHARED8, idx_byte, .. rest] => {
      self.update_view(rest)
      get_shared_object(self, idx_byte.to_int())
    }
    [CODE_SHARED16, u16be(index), .. rest] => {
      self.update_view(rest)
      get_shared_object(self, index.reinterpret_as_int())
    }
    [CODE_SHARED32, u32be(index), .. rest] => {
      self.update_view(rest)
      get_shared_object(self, index.reinterpret_as_int())
    }
    [CODE_SHARED64, u64be(index), .. rest] => {
      self.update_view(rest)
      get_shared_object(self, index.reinterpret_as_int64().to_int())
    }

    // Custom blocks with length-prefixed header
    [CODE_CUSTOM_LEN, .. rest] => {
      self.update_view(rest)
      self.decode_custom_block_len()
    }

    // Custom blocks with fixed size
    [CODE_CUSTOM_FIXED, .. rest] => {
      self.update_view(rest)
      self.decode_custom_block_fixed()
    }
    [tag, ..] =>
      fail(
        "Unknown or unsupported marshal tag \{tag} at position \{self.position}",
      )
    [] => fail("Unexpected end of data")
  }
}

///|
fn Decoder::decode_string_with_length(
  self : Self,
  len : Int,
) -> MarshalValue raise {
  let view = self.view()
  guard view.length() >= len else {
    fail("Insufficient data for string of length \{len}")
  }
  let string_bytes = view[:len]
  let remaining = view[len:]
  self.update_view(remaining)
  let marshal_value = MString(string_bytes.to_owned())
  self.add_shared_object(marshal_value)
  marshal_value
}

///|
// Helper function for decoding strings - currently unused
// fn Decoder::decode_string(self : Self) -> MarshalValue raise {
//   match self.view() {
//     [u32(length), .. rest] => {
//       let len = length.reinterpret_as_int()
//       self.update_view(rest)
//       self.decode_string_with_length(len)
//     }
//     _ => fail("Failed to parse string length")
//   }
// }

///|
/// Reads the 8 bytes of an IEEE-754 double from the view, honoring the
/// stream's endianness, and returns the raw bits.
///
/// The two branches would read more neatly as a single or-pattern
/// `(true, [u64be(v), .. rest]) | (false, [u64le(v), .. rest])`, but that
/// currently crashes the compiler (moonbitlang/core#3699: an or-pattern that
/// binds a `.. rest` tail across bits sub-patterns triggers an ICE in
/// codegen). Keep the explicit `if` until that is fixed.
fn Decoder::read_double_bits(self : Self, is_big_endian : Bool) -> UInt64 raise {
  if is_big_endian {
    match self.view() {
      [u64be(v), .. rest] => {
        self.update_view(rest)
        v
      }
      _ => fail("Insufficient data for double")
    }
  } else {
    match self.view() {
      [u64le(v), .. rest] => {
        self.update_view(rest)
        v
      }
      _ => fail("Insufficient data for double")
    }
  }
}

///|
fn Decoder::decode_double(
  self : Self,
  is_big_endian : Bool,
) -> MarshalValue raise {
  let marshal_value = MFloat(
    self.read_double_bits(is_big_endian).reinterpret_as_double(),
  )
  self.add_shared_object(marshal_value)
  marshal_value
}

///|
fn Decoder::decode_double_array(
  self : Self,
  count : Int,
  is_big_endian : Bool,
) -> MarshalValue raise {
  // The comprehension evaluates left to right, which matters because
  // `read_double_bits` advances the view as it reads each element.
  let doubles = [
    for _ in 0..<count => {
      self.read_double_bits(is_big_endian).reinterpret_as_double()
    }
  ]
  let marshal_value = MDoubleArray(doubles)
  self.add_shared_object(marshal_value)
  marshal_value
}

///|
fn Decoder::decode_block_with_tag_size(
  self : Self,
  tag : Int,
  size : Int,
) -> MarshalValue raise {
  // Register the block (before decoding fields, so recursive/cyclic shared
  // references can point back to it) — but only if it is non-empty. OCaml does
  // not register size-0 blocks (atoms) in the object table: see
  // runtime/intern.c `read_block` (`if (size == 0) v = Atom(tag)` skips the
  // `obj_counter++`), mirrored by `extern.c` (atoms are not recorded). Counting
  // an atom here would shift every later shared reference by one.
  let fields = []
  let marshal_value = MBlock(tag~, fields)
  if size > 0 {
    self.add_shared_object(marshal_value)
  }
  for _ in 0..<size {
    fields.push(self.decode_value())
  }
  marshal_value
}

///|
/// Serialized payload length, in bytes, for the custom block types we support.
///
/// OCaml's marshal format does not carry the serialized length of a custom
/// block in a generically usable way: the per-type sizes it does store (the
/// `CODE_CUSTOM_LEN` length header, and `custom_fixed_length`) are the
/// *in-memory* heap sizes from the type's `serialize`/`deserialize`, which can
/// differ from the serialized byte count — for e.g. a bigarray they stay
/// constant while the payload grows, and a nativeint serializes 5 or 9 bytes
/// while its fixed length reports 8. A reader therefore needs per-type
/// knowledge to find the payload boundary, exactly as OCaml's runtime does via
/// registered custom operations. We support the standard scalars and fail
/// clearly on anything else.
///
/// The view must be positioned at the start of the payload (some types, like
/// nativeint, need to peek the leading tag byte to determine the length).
fn Decoder::custom_payload_length(
  self : Self,
  identifier : String,
) -> Int raise {
  match identifier {
    "_i" => 4 // Int32: 4-byte big-endian value
    "_j" => 8 // Int64: 8-byte big-endian value
    // Nativeint (OCaml runtime/ints.c nativeint_serialize): a 1-byte tag
    // selects the width — 1 => a 4-byte int32, 2 => an 8-byte int64 —
    // followed by that value, so the payload is 5 or 9 bytes including the
    // tag, not the fixed in-memory size (8).
    "_n" =>
      match self.view() {
        [1, ..] => 5
        [2, ..] => 9
        [tag, ..] => fail("Invalid nativeint tag byte: \{tag}")
        [] => fail("Insufficient data for nativeint custom block")
      }
    _ => fail("Unsupported custom block identifier: \{identifier}")
  }
}

///|
/// Reads a null-terminated custom block identifier as a String.
fn Decoder::read_custom_identifier(self : Self) -> String raise {
  let identifier_bytes = self.read_null_terminated_string()
  String::from_array([ for b in identifier_bytes => b.to_char() ])
}

///|
/// Reads the payload of a supported custom block, builds the `MCustom` value
/// and registers it for sharing. Assumes the view is positioned at the start
/// of the serialized payload. The stored bytes are the raw serialized payload
/// (e.g. for nativeint this includes the leading width tag).
fn Decoder::read_custom_payload(
  self : Self,
  identifier : String,
) -> MarshalValue raise {
  let data_length = self.custom_payload_length(identifier)
  let view = self.view()
  guard view.length() >= data_length else {
    fail("Insufficient data for custom block '\{identifier}' payload")
  }
  let data_bytes = view[:data_length].to_owned()
  self.update_view(view[data_length:])
  let marshal_value = MCustom(identifier, data_bytes)
  self.add_shared_object(marshal_value)
  marshal_value
}

///|
/// Decodes a `CODE_CUSTOM_LEN` block.
///
/// Wire layout (after the 0x18 code byte), per OCaml `runtime/extern.c`
/// `extern_custom`: the null-terminated identifier, then a 12-byte length
/// header (`sz_32` as 4 bytes big-endian followed by `sz_64` as 8 bytes
/// big-endian), then the serialized payload. Those sizes are in-memory heap
/// sizes used for the header's size accounting, not the serialized length, so
/// the payload boundary is derived from the identifier — see
/// `custom_payload_length`.
fn Decoder::decode_custom_block_len(self : Self) -> MarshalValue raise {
  let identifier = self.read_custom_identifier()
  // Consume the 12-byte length header (sz_32: 4 bytes, sz_64: 8 bytes).
  match self.view() {
    [u32be(_sz_32), u64be(_sz_64), .. rest] => self.update_view(rest)
    _ =>
      fail("Insufficient data for custom block '\{identifier}' length header")
  }
  self.read_custom_payload(identifier)
}

///|
/// Decodes a `CODE_CUSTOM_FIXED` block: identifier then payload, with no
/// length header (the payload size is implied by the type).
fn Decoder::decode_custom_block_fixed(self : Self) -> MarshalValue raise {
  let identifier = self.read_custom_identifier()
  self.read_custom_payload(identifier)
}

///|
fn Decoder::read_null_terminated_string(self : Self) -> Bytes raise {
  let view = self.view()
  let mut len = 0
  while len < view.length() && view[len] != b'\x00' {
    len = len + 1
  }
  guard len < view.length() else {
    fail("No null terminator found in custom block identifier")
  }
  let str_bytes = view[:len].to_owned()
  self.update_view(view[len + 1:])
  str_bytes
}
