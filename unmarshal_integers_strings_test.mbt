// Tests for integer and string decoding
// Uses test data from marshal_data_test.mbt

///|
test "decode_small_integers" {
  // Test integers 0-63 which use single byte encoding
  let decoder0 = Decoder::new(int_0_data)
  let (_, value0) = decoder0.decode()
  inspect(value0, content="MInt(0)")
  let decoder1 = Decoder::new(int_1_data)
  let (_, value1) = decoder1.decode()
  inspect(value1, content="MInt(1)")
  let decoder42 = Decoder::new(int_42_data)
  let (_, value42) = decoder42.decode()
  inspect(value42, content="MInt(42)")
  let decoder63 = Decoder::new(int_63_data)
  let (_, value63) = decoder63.decode()
  inspect(value63, content="MInt(63)")
}

///|
test "decode_int8_range" {
  // Test integers that require CODE_INT8 encoding
  let decoder100 = Decoder::new(int_100_data)
  let (_, value100) = decoder100.decode()
  inspect(value100, content="MInt(100)")
  let decoder127 = Decoder::new(int_127_data)
  let (_, value127) = decoder127.decode()
  inspect(value127, content="MInt(127)")
  let decoder_neg1 = Decoder::new(int_neg_1_data)
  let (_, value_neg1) = decoder_neg1.decode()
  inspect(value_neg1, content="MInt(-1)")
  let decoder_neg128 = Decoder::new(int_neg_128_data)
  let (_, value_neg128) = decoder_neg128.decode()
  inspect(value_neg128, content="MInt(-128)")
}

///|
test "decode_int16_range" {
  // Test integers that require CODE_INT16 encoding
  let decoder1000 = Decoder::new(int_1000_data)
  let (_, value1000) = decoder1000.decode()
  inspect(value1000, content="MInt(1000)")
  let decoder32767 = Decoder::new(int_32767_data)
  let (_, value32767) = decoder32767.decode()
  inspect(value32767, content="MInt(32767)")
  let decoder_neg1000 = Decoder::new(int_neg_1000_data)
  let (_, value_neg1000) = decoder_neg1000.decode()
  inspect(value_neg1000, content="MInt(-1000)")
  let decoder_neg32768 = Decoder::new(int_neg_32768_data)
  let (_, value_neg32768) = decoder_neg32768.decode()
  inspect(value_neg32768, content="MInt(-32768)")
}

///|
test "decode_int32_range" {
  // Test integers that require CODE_INT32 encoding
  let decoder100000 = Decoder::new(int_100000_data)
  let (_, value100000) = decoder100000.decode()
  inspect(value100000, content="MInt(100000)")
  let decoder_max32 = Decoder::new(int_2147483647_data)
  let (_, value_max32) = decoder_max32.decode()
  inspect(value_max32, content="MInt(2147483647)")
  let decoder_neg100000 = Decoder::new(int_neg_100000_data)
  let (_, value_neg100000) = decoder_neg100000.decode()
  inspect(value_neg100000, content="MInt(-100000)")
  let decoder_min32 = Decoder::new(int_neg_2147483648_data)
  let (_, value_min32) = decoder_min32.decode()
  inspect(value_min32, content="MInt(-2147483648)")
}

///|
test "decode_small_strings" {
  // Test strings that use PREFIX_SMALL_STRING encoding (< 32 chars)
  let decoder_empty = Decoder::new(string_empty_data)
  let (_, value_empty) = decoder_empty.decode()
  inspect(value_empty, content="MString(b\"\")")
  let decoder_a = Decoder::new(string_a_data)
  let (_, value_a) = decoder_a.decode()
  inspect(
    value_a,
    content=(
      #|MString(b"a")
    ),
  )
  let decoder_hello = Decoder::new(string_hello_data)
  let (_, value_hello) = decoder_hello.decode()
  inspect(
    value_hello,
    content=(
      #|MString(b"Hello")
    ),
  )
  let decoder_31 = Decoder::new(string_31chars_data)
  let (_, value_31) = decoder_31.decode()
  // Check it's 31 x's
  match value_31 {
    MString(bytes) => {
      assert_eq(bytes.length(), 31)
      assert_eq(bytes[0], b'x')
      assert_eq(bytes[30], b'x')
    }
    _ => abort("Expected MString")
  }
}

///|
test "decode_string8" {
  // Test strings that use CODE_STRING8 encoding (32-255 chars)
  let decoder_32 = Decoder::new(string_32chars_data)
  let (_, value_32) = decoder_32.decode()
  match value_32 {
    MString(bytes) => {
      assert_eq(bytes.length(), 32)
      assert_eq(bytes[0], b'y')
      assert_eq(bytes[31], b'y')
    }
    _ => abort("Expected MString")
  }
  let decoder_100 = Decoder::new(string_100chars_data)
  let (_, value_100) = decoder_100.decode()
  match value_100 {
    MString(bytes) => {
      assert_eq(bytes.length(), 100)
      assert_eq(bytes[0], b'z')
      assert_eq(bytes[99], b'z')
    }
    _ => abort("Expected MString")
  }
  let decoder_255 = Decoder::new(string_255chars_data)
  let (_, value_255) = decoder_255.decode()
  match value_255 {
    MString(bytes) => {
      assert_eq(bytes.length(), 255)
      assert_eq(bytes[0], b'w')
      assert_eq(bytes[254], b'w')
    }
    _ => abort("Expected MString")
  }
}

///|
test "decode_string32" {
  // Test strings that use CODE_STRING32 encoding (> 255 chars)
  let decoder_256 = Decoder::new(string_256chars_data)
  let (_, value_256) = decoder_256.decode()
  match value_256 {
    MString(bytes) => {
      assert_eq(bytes.length(), 256)
      assert_eq(bytes[0], b'v')
      assert_eq(bytes[255], b'v')
    }
    _ => abort("Expected MString")
  }
  let decoder_1000 = Decoder::new(string_1000chars_data)
  let (_, value_1000) = decoder_1000.decode()
  match value_1000 {
    MString(bytes) => {
      assert_eq(bytes.length(), 1000)
      assert_eq(bytes[0], b'u')
      assert_eq(bytes[999], b'u')
    }
    _ => abort("Expected MString")
  }
}

///|
test "decode_special_strings" {
  // Test strings with special characters
  let decoder_special = Decoder::new(string_special_data)
  let (_, value_special) = decoder_special.decode()
  inspect(
    value_special,
    content=(
      #|MString(b"Hello\x0aWorld\x09!")
    ),
  )

  // Test Unicode string
  let decoder_unicode = Decoder::new(string_unicode_data)
  let (_, value_unicode) = decoder_unicode.decode()
  match value_unicode {
    MString(bytes) => {
      // "Hello 世界 🌍" in UTF-8
      assert_eq(bytes.length(), 17)
      // Check first 5 bytes are "Hello"
      assert_eq(bytes[0], b'H')
      assert_eq(bytes[1], b'e')
      assert_eq(bytes[2], b'l')
      assert_eq(bytes[3], b'l')
      assert_eq(bytes[4], b'o')
    }
    _ => abort("Expected MString")
  }
}

///|
test "decode_booleans" {
  // Test boolean values (true = 1, false = 0)
  let decoder_true = Decoder::new(bool_true_data)
  let (_, value_true) = decoder_true.decode()
  inspect(value_true, content="MInt(1)") // true is represented as 1
  let decoder_false = Decoder::new(bool_false_data)
  let (_, value_false) = decoder_false.decode()
  inspect(value_false, content="MInt(0)") // false is represented as 0
}

///|
test "decode_floats" {
  // Test floating point numbers
  let decoder_pi = Decoder::new(float_pi_data)
  let (_, value_pi) = decoder_pi.decode()
  // First inspect the value to see what we get
  inspect(value_pi, content="MFloat(3.14159)")
  let decoder_neg = Decoder::new(float_neg_data)
  let (_, value_neg) = decoder_neg.decode()
  inspect(value_neg, content="MFloat(-2.5)")
  let decoder_zero = Decoder::new(float_zero_data)
  let (_, value_zero) = decoder_zero.decode()
  inspect(value_zero, content="MFloat(0)")
}

///|
test "decode_tuple" {
  let decoder_1_2 = Decoder::new(tuple_1_2_data)
  let (_, value_1_2) = decoder_1_2.decode()
  inspect(value_1_2, content="MBlock(tag=0, [MInt(1), MInt(2)])")
  let decoder_hello_42 = Decoder::new(tuple_hello_42_data)
  let (_, value_hello_42) = decoder_hello_42.decode()
  inspect(
    value_hello_42,
    content=(
      #|MBlock(tag=0, [MString(b"Hello"), MInt(42)])
    ),
  )
}

///|
test "decode_empty_list" {
  let decoder = Decoder::new(empty_list_data)
  let (_, value) = decoder.decode()
  // Empty list is represented as MInt(0) in OCaml
  inspect(value, content="MInt(0)")
}

///|
test "decode_list_1_2" {
  let decoder = Decoder::new(list_1_2_data)
  let (_, value) = decoder.decode()
  // List [1; 2] is encoded as a series of cons cells
  // [1; 2] = 1 :: 2 :: []
  inspect(
    value,
    content="MBlock(tag=0, [MInt(1), MBlock(tag=0, [MInt(2), MInt(0)])])",
  )
}
