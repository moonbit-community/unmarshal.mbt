// Encoder tests: byte-identity round-trips `marshal(decode(x)) == x` against
// fixtures that are genuine OCaml 4.14.1 `Marshal.to_string` output. A passing
// round-trip proves the encoder reproduces OCaml's exact bytes, including the
// header (data length, object count, heap-word sizes), smallest-fit encodings,
// and backward-distance shared references.

///|
fn enc_roundtrip(data : Bytes) -> Bytes raise {
  let (_, value) = Decoder::new(data).decode()
  marshal(value)
}

///|
/// Parses a contiguous lowercase hex string into Bytes (fixtures are stored as
/// hex to avoid transcription errors in long byte arrays).
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

// --- Shared / atom fixtures (from marshal_data_test.mbt and
// unmarshal_shared_realworld_test.mbt; all genuine OCaml output) ---

///|
test "encode round-trips shared string tuple" {
  assert_eq(enc_roundtrip(shared_string_tuple_data), shared_string_tuple_data)
}

///|
test "encode round-trips shared list tuple" {
  assert_eq(enc_roundtrip(shared_list_tuple_data), shared_list_tuple_data)
}

///|
test "encode round-trips shared nested tuple" {
  assert_eq(enc_roundtrip(shared_nested_tuple_data), shared_nested_tuple_data)
}

///|
test "encode round-trips triple shared middle" {
  assert_eq(enc_roundtrip(triple_shared_middle_data), triple_shared_middle_data)
}

///|
test "encode round-trips list with shared elements" {
  assert_eq(enc_roundtrip(list_with_shared_data), list_with_shared_data)
}

///|
test "encode round-trips complex shared" {
  assert_eq(enc_roundtrip(complex_shared_data), complex_shared_data)
}

///|
test "encode round-trips rw shared string quad" {
  assert_eq(
    enc_roundtrip(rw_shared_string_quad_data),
    rw_shared_string_quad_data,
  )
}

///|
test "encode round-trips rw shared tuple triple" {
  assert_eq(
    enc_roundtrip(rw_shared_tuple_triple_data),
    rw_shared_tuple_triple_data,
  )
}

///|
test "encode round-trips rw shared list after" {
  assert_eq(enc_roundtrip(rw_shared_list_after_data), rw_shared_list_after_data)
}

///|
test "encode round-trips atom between shared" {
  assert_eq(
    enc_roundtrip(rw_atom_between_shared_data),
    rw_atom_between_shared_data,
  )
}

// --- Scalar / double / boundary fixtures (genuine OCaml output, stored as
// hex). Each exercises a specific encode branch. ---

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
  assert_roundtrip(
    "8495a6be00000131000000010000004d000000270a0000012c717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171717171",
  )
}

// --- Custom block fixtures (genuine OCaml output: int32/int64/nativeint use
// CODE_CUSTOM_FIXED) ---

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
