// Test cases for unmarshaling OCaml custom blocks (Int32, Int64, Nativeint)

///|
test "unmarshal custom block Int32 zero" {
  // Int32 value 0
  let data = Bytes::from_array([
    0x84, 0x95, 0xa6, 0xbe, // Magic number
     0x00, 0x00, 0x00, 0x08, // Data length: 8 bytes
     0x00, 0x00, 0x00, 0x01, // Number of objects: 1
     0x00, 0x00, 0x00, 0x03, // Size on 32-bit: 3
     0x00, 0x00, 0x00, 0x03, // Size on 64-bit: 3
     0x19, // CODE_CUSTOM_FIXED
     0x5f, 0x69, 0x00, // "_i" (null-terminated)
     0x00, 0x00, 0x00, 0x00, // Int32 value: 0
  ])
  let decoder = Decoder::new(data)
  let (header, value) = decoder.decode()
  assert_eq(header.magic, 0x8495A6BE)
  assert_eq(header.data_len, 8)
  match value {
    MCustom(id, data) => {
      assert_eq(id, "_i")
      assert_eq(data, Bytes::from_array([0x00, 0x00, 0x00, 0x00]))
    }
    _ => fail("Expected MCustom for Int32")
  }
}

///|
test "unmarshal custom block Int32 value 42" {
  // Int32 value 42
  let data = Bytes::from_array([
    0x84, 0x95, 0xa6, 0xbe, // Magic number
     0x00, 0x00, 0x00, 0x08, // Data length: 8 bytes
     0x00, 0x00, 0x00, 0x01, // Number of objects: 1
     0x00, 0x00, 0x00, 0x03, // Size on 32-bit: 3
     0x00, 0x00, 0x00, 0x03, // Size on 64-bit: 3
     0x19, // CODE_CUSTOM_FIXED
     0x5f, 0x69, 0x00, // "_i" (null-terminated)
     0x00, 0x00, 0x00, 0x2a, // Int32 value: 42
  ])
  let decoder = Decoder::new(data)
  let (header, value) = decoder.decode()
  assert_eq(header.magic, 0x8495A6BE)
  assert_eq(header.data_len, 8)
  match value {
    MCustom(id, data) => {
      assert_eq(id, "_i")
      assert_eq(data, Bytes::from_array([0x00, 0x00, 0x00, 0x2a]))
      // Verify the value is 42 (big-endian)
      let val = (data[0].to_int() << 24) |
        (data[1].to_int() << 16) |
        (data[2].to_int() << 8) |
        data[3].to_int()
      assert_eq(val, 42)
    }
    _ => fail("Expected MCustom for Int32")
  }
}

///|
test "unmarshal custom block Int32 negative" {
  // Int32 value -42
  let data = Bytes::from_array([
    0x84, 0x95, 0xa6, 0xbe, // Magic number
     0x00, 0x00, 0x00, 0x08, // Data length: 8 bytes
     0x00, 0x00, 0x00, 0x01, // Number of objects: 1
     0x00, 0x00, 0x00, 0x03, // Size on 32-bit: 3
     0x00, 0x00, 0x00, 0x03, // Size on 64-bit: 3
     0x19, // CODE_CUSTOM_FIXED
     0x5f, 0x69, 0x00, // "_i" (null-terminated)
     0xff, 0xff, 0xff, 0xd6, // Int32 value: -42
  ])
  let decoder = Decoder::new(data)
  let (_header, value) = decoder.decode()
  match value {
    MCustom(id, data) => {
      assert_eq(id, "_i")
      assert_eq(data, Bytes::from_array([0xff, 0xff, 0xff, 0xd6]))
    }
    _ => fail("Expected MCustom for Int32")
  }
}

///|
test "unmarshal custom block Int64" {
  // Int64 value 1000000
  let data = Bytes::from_array([
    0x84, 0x95, 0xa6, 0xbe, // Magic number
     0x00, 0x00, 0x00, 0x0c, // Data length: 12 bytes
     0x00, 0x00, 0x00, 0x01, // Number of objects: 1
     0x00, 0x00, 0x00, 0x03, // Size on 32-bit: 3
     0x00, 0x00, 0x00, 0x02, // Size on 64-bit: 2
     0x19, // CODE_CUSTOM_FIXED
     0x5f, 0x6a, 0x00, // "_j" (null-terminated)
     0x00, 0x00, 0x00, 0x00, 0x00, 0x0f, 0x42, 0x40, // Int64 value: 1000000
  ])
  let decoder = Decoder::new(data)
  let (_header, value) = decoder.decode()
  match value {
    MCustom(id, data) => {
      assert_eq(id, "_j")
      assert_eq(data.length(), 8)
      // Verify the value is 1000000 (0xF4240)
      assert_eq(data[5], b'\x0f')
      assert_eq(data[6], b'\x42')
      assert_eq(data[7], b'\x40')
    }
    _ => fail("Expected MCustom for Int64")
  }
}

///|
test "unmarshal custom block with length prefix" {
  // Using CODE_CUSTOM_LEN instead of CODE_CUSTOM_FIXED
  let data = Bytes::from_array([
    0x84, 0x95, 0xa6, 0xbe, // Magic number
     0x00, 0x00, 0x00, 0x0c, // Data length: 12 bytes
     0x00, 0x00, 0x00, 0x01, // Number of objects: 1
     0x00, 0x00, 0x00, 0x03, // Size on 32-bit: 3
     0x00, 0x00, 0x00, 0x03, // Size on 64-bit: 3
     0x18, // CODE_CUSTOM_LEN
     0x00, 0x00, 0x00, 0x07, // Length: 7 bytes (identifier + null + data)
     0x5f, 0x69, 0x00, // "_i" (null-terminated)
     0x12, 0x34, 0x56, 0x78, // Int32 value: 0x12345678
  ])
  let decoder = Decoder::new(data)
  let (_header, value) = decoder.decode()
  match value {
    MCustom(id, data) => {
      assert_eq(id, "_i")
      assert_eq(data, Bytes::from_array([0x12, 0x34, 0x56, 0x78]))
      // Verify the value
      let val = (data[0].to_int() << 24) |
        (data[1].to_int() << 16) |
        (data[2].to_int() << 8) |
        data[3].to_int()
      assert_eq(val, 0x12345678)
    }
    _ => fail("Expected MCustom for Int32")
  }
}

///|
test "unmarshal tuple with custom blocks" {
  // Tuple containing (Int32(42), "Hello")
  let data = Bytes::from_array([
    0x84, 0x95, 0xa6, 0xbe, // Magic number
     0x00, 0x00, 0x00, 0x10, // Data length: 16 bytes
     0x00, 0x00, 0x00, 0x02, // Number of objects: 2
     0x00, 0x00, 0x00, 0x06, // Size on 32-bit
     0x00, 0x00, 0x00, 0x05, // Size on 64-bit
     0xa0, // Small block: tag 0, size 2
     0x19, // First element: CODE_CUSTOM_FIXED
     0x5f, 0x69, 0x00, // "_i"
     0x00, 0x00, 0x00, 0x2a, // Int32 value: 42
     0x25, // Second element: small string length 5
     0x48, 0x65, 0x6c, 0x6c, 0x6f, // "Hello"
  ])
  let decoder = Decoder::new(data)
  let (_header, value) = decoder.decode()
  match value {
    MBlock(tag~, fields) => {
      assert_eq(tag, 0)
      assert_eq(fields.length(), 2)

      // Check first field (Int32 custom block)
      match fields[0] {
        MCustom(id, data) => {
          assert_eq(id, "_i")
          assert_eq(data, Bytes::from_array([0x00, 0x00, 0x00, 0x2a]))
        }
        _ => fail("Expected MCustom for first tuple element")
      }

      // Check second field (string)
      match fields[1] {
        MString(s) => assert_eq(s, b"Hello")
        _ => fail("Expected MString for second tuple element")
      }
    }
    _ => fail("Expected MBlock for tuple")
  }
}

///|
test "unmarshal nativeint custom block" {
  // Nativeint value 42 (on 64-bit platform)
  let data = Bytes::from_array([
    0x84, 0x95, 0xa6, 0xbe, // Magic number
     0x00, 0x00, 0x00, 0x0c, // Data length: 12 bytes
     0x00, 0x00, 0x00, 0x01, // Number of objects: 1
     0x00, 0x00, 0x00, 0x03, // Size on 32-bit: 3
     0x00, 0x00, 0x00, 0x02, // Size on 64-bit: 2
     0x19, // CODE_CUSTOM_FIXED
     0x5f, 0x6e, 0x00, // "_n" (null-terminated)
     0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x2a, // Nativeint value: 42
  ])
  let decoder = Decoder::new(data)
  let (_header, value) = decoder.decode()
  match value {
    MCustom(id, data) => {
      assert_eq(id, "_n")
      assert_eq(data.length(), 8)
      // Verify the value is 42 (last byte)
      assert_eq(data[7], b'\x2a')
    }
    _ => fail("Expected MCustom for Nativeint")
  }
}

///|
test "unmarshal custom block Int32 max value" {
  // Int32.max_int = 2147483647 (0x7FFFFFFF)
  let data = Bytes::from_array([
    0x84, 0x95, 0xa6, 0xbe, // Magic number
     0x00, 0x00, 0x00, 0x08, // Data length: 8 bytes
     0x00, 0x00, 0x00, 0x01, // Number of objects: 1
     0x00, 0x00, 0x00, 0x03, // Size on 32-bit: 3
     0x00, 0x00, 0x00, 0x03, // Size on 64-bit: 3
     0x19, // CODE_CUSTOM_FIXED
     0x5f, 0x69, 0x00, // "_i" (null-terminated)
     0x7f, 0xff, 0xff, 0xff, // Int32 max value
  ])
  let decoder = Decoder::new(data)
  let (_header, value) = decoder.decode()
  match value {
    MCustom(id, data) => {
      assert_eq(id, "_i")
      assert_eq(data, Bytes::from_array([0x7f, 0xff, 0xff, 0xff]))
    }
    _ => fail("Expected MCustom for Int32")
  }
}

///|
test "unmarshal custom block Int32 min value" {
  // Int32.min_int = -2147483648 (0x80000000)
  let data = Bytes::from_array([
    0x84, 0x95, 0xa6, 0xbe, // Magic number
     0x00, 0x00, 0x00, 0x08, // Data length: 8 bytes
     0x00, 0x00, 0x00, 0x01, // Number of objects: 1
     0x00, 0x00, 0x00, 0x03, // Size on 32-bit: 3
     0x00, 0x00, 0x00, 0x03, // Size on 64-bit: 3
     0x19, // CODE_CUSTOM_FIXED
     0x5f, 0x69, 0x00, // "_i" (null-terminated)
     0x80, 0x00, 0x00, 0x00, // Int32 min value
  ])
  let decoder = Decoder::new(data)
  let (_header, value) = decoder.decode()
  match value {
    MCustom(id, data) => {
      assert_eq(id, "_i")
      assert_eq(data, Bytes::from_array([0x80, 0x00, 0x00, 0x00]))
    }
    _ => fail("Expected MCustom for Int32")
  }
}
