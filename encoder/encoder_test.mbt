// Encoder tests: byte-identity round-trips `marshal(decode(x)) == x` against
// fixtures that are genuine OCaml 4.14.1 `Marshal.to_string` output. A passing
// round-trip proves the encoder reproduces OCaml's exact bytes, including the
// header (data length, object count, heap-word sizes), smallest-fit encodings,
// and backward-distance shared references.
//
// Fixtures are stored as hex strings (long byte arrays are error-prone to hand
// transcribe). Decoding here uses the sibling `decoder` package.

// Shared value model lives in the root `bobzhang/unmarshal` package.

///|
using @unmarshal {type MarshalValue}

///|
fn enc_roundtrip(data : Bytes) -> Bytes raise {
  let (_, value) = @decoder.Decoder::new(data).decode()
  marshal(value)
}

///|
/// Parses a contiguous lowercase hex string into Bytes.
fn hex_to_bytes(s : String) -> Bytes {
  fn nib(u : Int) -> Int {
    if u >= 48 && u <= 57 {
      u - 48 // '0'..'9'
    } else if u >= 97 {
      u - 87 // 'a'..'f' -> 10..15
    } else {
      u - 55 // 'A'..'F'
    }
  }

  let arr : Array[Byte] = []
  let n = s.length()
  for i = 0; i + 1 < n; i = i + 2 {
    arr.push(((nib(s[i].to_int()) << 4) | nib(s[i + 1].to_int())).to_byte())
  }
  Bytes::from_array(arr)
}

///|
fn assert_roundtrip(hex : String) -> Unit raise {
  let data = hex_to_bytes(hex)
  assert_eq(enc_roundtrip(data), data)
}

// --- Shared / atom fixtures (genuine OCaml output) ---

///|
test "encode round-trips shared string tuple" {
  assert_roundtrip(
    "8495a6be0000000a000000020000000600000005a0267368617265640401",
  )
}

///|
test "encode round-trips shared list tuple" {
  assert_roundtrip(
    "8495a6be0000000a000000040000000c0000000ca0a041a042a043400403",
  )
}

///|
test "encode round-trips shared nested tuple" {
  assert_roundtrip(
    "8495a6be0000000a000000030000000900000008a0a024746573746a0402",
  )
}

///|
test "encode round-trips triple shared middle" {
  assert_roundtrip(
    "8495a6be00000010000000030000000a00000008b0256669727374266d6964646c650401",
  )
}

///|
test "encode round-trips list with shared elements" {
  assert_roundtrip(
    "8495a6be0000000d000000040000000c0000000ba024656c656da00402a0040340",
  )
}

///|
test "encode round-trips complex shared" {
  assert_roundtrip(
    "8495a6be0000000c000000050000000f0000000fa0a041a04aa05440a0420403",
  )
}

///|
test "encode round-trips rw shared string quad" {
  assert_roundtrip(
    "8495a6be0000000e000000040000000c0000000bc02161256f63616d6c2262620402",
  )
}

///|
test "encode round-trips rw shared tuple triple" {
  assert_roundtrip("8495a6be00000008000000020000000700000007b0a0474804010401")
}

///|
test "encode round-trips rw shared list after" {
  assert_roundtrip(
    "8495a6be0000000f000000070000001400000014b02178a041a042a04340a021790405",
  )
}

///|
test "encode round-trips atom between shared" {
  assert_roundtrip("8495a6be00000008000000020000000600000006b023616263800401")
}

// --- Scalar / double / boundary fixtures (genuine OCaml output) ---

///|
test "encode round-trips int16" {
  assert_roundtrip("8495a6be000000030000000000000000000000000103e8")
}

///|
test "encode round-trips int32" {
  assert_roundtrip("8495a6be0000000500000000000000000000000002000186a0")
}

///|
test "encode round-trips negative int16" {
  assert_roundtrip("8495a6be0000000300000000000000000000000001fc18")
}

///|
test "encode round-trips int64 (fits in 32-bit)" {
  // 1 lsl 30: magnitude >= 2^30 so OCaml uses CODE_INT64, but it fits in a
  // 32-bit Int so the decode is lossless and the re-encode is byte-identical.
  assert_roundtrip("8495a6be00000009000000000000000000000000030000000040000000")
}

///|
test "encode round-trips float" {
  assert_roundtrip("8495a6be000000090000000100000003000000020c1f85eb51b81e0940")
}

///|
test "encode round-trips float array" {
  assert_roundtrip(
    "8495a6be0000001a0000000100000007000000040e03000000000000f03f000000000000044000000000000008c0",
  )
}

///|
test "encode round-trips compound (block32, ints, double, array, string8)" {
  // (64, -1, 1000, -1000, 100000, 3.14, [|1.0;2.0|], "x"*40, ("a","b"))
  assert_roundtrip(
    "8495a6be0000005e00000007000000250000001d0800002400004000ff0103e801fc1802000186a00c1f85eb51b81e09400e02000000000000f03f0000000000000040092878787878787878787878787878787878787878787878787878787878787878787878787878787878a021612162",
  )
}

///|
test "encode round-trips big string (string32)" {
  // header (25 bytes) + 0x0a + u32 len 300 + 300 'q' payload
  let arr : Array[Byte] = [
    0x84, 0x95, 0xa6, 0xbe, 0x00, 0x00, 0x01, 0x31, 0x00, 0x00, 0x00, 0x01, 0x00,
    0x00, 0x00, 0x4d, 0x00, 0x00, 0x00, 0x27, 0x0a, 0x00, 0x00, 0x01, 0x2c,
  ]
  for _ in 0..<300 {
    arr.push(b'\x71')
  }
  let data = Bytes::from_array(arr)
  assert_eq(enc_roundtrip(data), data)
}

// --- Custom block fixtures (genuine OCaml output: CODE_CUSTOM_FIXED) ---

///|
test "encode round-trips int32 custom" {
  assert_roundtrip("8495a6be00000008000000010000000300000003195f69000000002a")
}

///|
test "encode round-trips int64 custom" {
  assert_roundtrip(
    "8495a6be0000000c000000010000000400000003195f6a0000000000000f4240",
  )
}

///|
test "encode round-trips nativeint custom (small, tag 1)" {
  assert_roundtrip("8495a6be00000009000000010000000300000003195f6e00010000002a")
}

///|
test "encode round-trips nativeint custom (large, tag 2)" {
  assert_roundtrip(
    "8495a6be0000000d000000010000000300000003195f6e00020000010000000000",
  )
}

///|
test "encode round-trips tuple with customs" {
  // (Int32 7, "hi", Int64 -5)
  assert_roundtrip(
    "8495a6be00000018000000040000000d0000000cb0195f690000000007226869195f6a00fffffffffffffffb",
  )
}

// --- Cycles, atoms, empty values, integer boundaries (genuine OCaml) ---

///|
test "encode round-trips a cyclic list (self-reference)" {
  // let rec cyc = 0 :: cyc  ->  cons cell whose tail is a shared ref to itself
  assert_roundtrip("8495a6be00000004000000010000000300000003a0400401")
}

///|
test "encode round-trips empty string" {
  assert_roundtrip("8495a6be0000000100000001000000020000000220")
}

///|
test "encode round-trips empty array (atom)" {
  assert_roundtrip("8495a6be0000000100000000000000000000000080")
}

///|
test "encode round-trips shared one-char string" {
  // let s = "x" in (s, s)
  assert_roundtrip("8495a6be00000005000000020000000500000005a021780401")
}

///|
test "encode round-trips integer boundaries" {
  // 63, 64, 127, 128, -128, -129, 32767, 32768
  assert_roundtrip("8495a6be000000010000000000000000000000007f")
  assert_roundtrip("8495a6be000000020000000000000000000000000040")
  assert_roundtrip("8495a6be00000002000000000000000000000000007f")
  assert_roundtrip("8495a6be00000003000000000000000000000000010080")
  assert_roundtrip("8495a6be000000020000000000000000000000000080")
  assert_roundtrip("8495a6be0000000300000000000000000000000001ff7f")
  assert_roundtrip("8495a6be00000003000000000000000000000000017fff")
  assert_roundtrip("8495a6be000000050000000000000000000000000200008000")
}

// --- Reverse direction: decode(encode(v)) == v for constructed values ---

///|
test "decode(encode(v)) == v for constructed values" {
  let cases : Array[MarshalValue] = [
    MInt(0),
    MInt(63),
    MInt(64),
    MInt(-1),
    MInt(128),
    MInt(-129),
    MInt(32768),
    MInt(100000),
    MInt(-100000),
    MString(b""),
    MString(b"hello"),
    MFloat(3.14),
    MFloat(0.0),
    MDoubleArray([1.0, 2.0, 3.0]),
    MBlock(tag=0, [MInt(1), MString(b"a"), MFloat(2.5)]),
    MBlock(tag=3, [MInt(7), MBlock(tag=0, [MInt(8), MInt(9)])]),
  ]
  for v in cases {
    let (_, decoded) = @decoder.Decoder::new(marshal(v)).decode()
    assert_eq(decoded, v)
  }
}

///|
test "marshal empty MDoubleArray as the tag-0 atom" {
  // OCaml represents an empty float array as Atom(0) == 0x80.
  let bytes = marshal(MDoubleArray([]))
  assert_eq(bytes, hex_to_bytes("8495a6be0000000100000000000000000000000080"))
  let (_, v) = @decoder.Decoder::new(bytes).decode()
  assert_eq(v, MBlock(tag=0, []))
}

///|
test "marshal validates custom block payloads" {
  fn fails(v : MarshalValue) -> Bool {
    let _ = marshal(v) catch { _ => return true }
    false
  }

  // Malformed payloads must raise, not emit an unreadable stream.
  assert_true(fails(MCustom("_i", b""))) // _i needs 4 bytes
  assert_true(fails(MCustom("_i", b"\x00\x00\x00\x00\x00"))) // too long
  assert_true(fails(MCustom("_j", b"\x00"))) // _j needs 8 bytes
  assert_true(fails(MCustom("_n", b"\x01\x00\x00"))) // tag 1 needs 4 value bytes
  assert_true(fails(MCustom("_n", b"\x02\x00"))) // tag 2 needs 8 value bytes
  assert_true(fails(MCustom("_n", b"\x03\x00\x00\x00\x00"))) // invalid width tag
  assert_true(fails(MCustom("_z", b"\x00"))) // unsupported identifier
  // Well-formed payloads still succeed.
  assert_false(fails(MCustom("_i", b"\x00\x00\x00\x2a")))
  assert_false(fails(MCustom("_j", b"\x00\x00\x00\x00\x00\x00\x00\x2a")))
  assert_false(fails(MCustom("_n", b"\x01\x00\x00\x00\x2a")))
  assert_false(fails(MCustom("_n", b"\x02\x00\x00\x01\x00\x00\x00\x00\x00")))
}
