// Tests for double array decoding in OCaml marshalling format
// Uses test data from marshal_data_test.mbt

///|
test "decode_empty_float_array" {
  let decoder = Decoder::new(float_array_empty_data)
  let (_, value) = decoder.decode()
  // Empty float array is encoded as an empty block with tag 0 in OCaml
  inspect(value, content="MBlock(tag=0, [])")
}

///|
test "decode_single_float_array" {
  let decoder = Decoder::new(float_array_single_data)
  let (_, value) = decoder.decode()
  // Let's see what we actually get
  inspect(value, content="MDoubleArray([3.14])")
}

///|
test "decode_small_float_array" {
  let decoder = Decoder::new(float_array_small_data)
  let (_, value) = decoder.decode()
  match value {
    MDoubleArray(arr) => {
      assert_eq(arr.length(), 5)
      // Check specific values: [| 1.0; 2.5; -3.7; 0.0; 42.42 |]
      assert_true(arr[0] > 0.99 && arr[0] < 1.01) // 1.0
      assert_true(arr[1] > 2.49 && arr[1] < 2.51) // 2.5
      assert_true(arr[2] > -3.71 && arr[2] < -3.69) // -3.7
      assert_true(arr[3] > -0.01 && arr[3] < 0.01) // 0.0
      assert_true(arr[4] > 42.41 && arr[4] < 42.43) // 42.42
    }
    _ => abort("Expected MDoubleArray")
  }
}

///|
test "decode_medium_float_array" {
  let decoder = Decoder::new(float_array_medium_data)
  let (_, value) = decoder.decode()
  match value {
    MDoubleArray(arr) => {
      assert_eq(arr.length(), 100)
      // Check first few values (0.0, 1.0, 2.0, ...)
      for i = 0; i < 10; i = i + 1 {
        let expected = i.to_double()
        assert_true(arr[i] > expected - 0.01 && arr[i] < expected + 0.01)
      }
    }
    _ => abort("Expected MDoubleArray")
  }
}

///|
test "decode_large_float_array" {
  let decoder = Decoder::new(float_array_large_data)
  let (_, value) = decoder.decode()
  match value {
    MDoubleArray(arr) => {
      assert_eq(arr.length(), 300)
      // Check pattern: 0, 2, 4, 6, ...
      for i = 0; i < 10; i = i + 1 {
        let expected = (i * 2).to_double()
        assert_true(arr[i] > expected - 0.01 && arr[i] < expected + 0.01)
      }
    }
    _ => abort("Expected MDoubleArray")
  }
}

///|
test "decode_float_array_types" {
  // This test checks that we can handle different encoding types
  // The actual encoding type (8-bit, 32-bit, 64-bit count) depends on array size

  // Empty array is encoded as an empty block with tag 0, not as MDoubleArray
  let decoder1 = Decoder::new(float_array_empty_data)
  let (_, value1) = decoder1.decode()
  match value1 {
    MBlock(tag~, fields) => {
      assert_eq(tag, 0)
      assert_eq(fields.length(), 0)
    }
    _ => abort("Expected MBlock for empty float array")
  }

  // Small array (< 256 elements) uses CODE_DOUBLE_ARRAY8
  let decoder2 = Decoder::new(float_array_small_data)
  let (_, value2) = decoder2.decode()
  match value2 {
    MDoubleArray(arr) => assert_eq(arr.length(), 5)
    _ => abort("Expected MDoubleArray for small array")
  }

  // Large array (>= 256 elements) uses CODE_DOUBLE_ARRAY32
  let decoder3 = Decoder::new(float_array_large_data)
  let (_, value3) = decoder3.decode()
  match value3 {
    MDoubleArray(arr) => assert_eq(arr.length(), 300)
    _ => abort("Expected MDoubleArray for large array")
  }
}

///|
test "decode_float_array_precision" {
  // Test that floating point values maintain reasonable precision
  let decoder = Decoder::new(float_array_small_data)
  let (_, value) = decoder.decode()
  match value {
    MDoubleArray(arr) => {
      // These are the exact values we marshalled: [| 1.0; 2.5; -3.7; 0.0; 42.42 |]
      let epsilon = 0.0000001

      // Test exact representation for simple values
      assert_true((arr[0] - 1.0).abs() < epsilon)
      assert_true((arr[1] - 2.5).abs() < epsilon)
      assert_true((arr[3] - 0.0).abs() < epsilon)

      // Test approximate values for non-exact representations
      assert_true((arr[2] - -3.7).abs() < 0.000001)
      assert_true((arr[4] - 42.42).abs() < 0.000001)
    }
    _ => abort("Expected MDoubleArray")
  }
}
