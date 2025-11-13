# OCaml Marshal Decoder for MoonBit

A MoonBit implementation for decoding OCaml's Marshal binary format, enabling interoperability between OCaml and MoonBit programs.

## Overview

This library provides a decoder for OCaml's Marshal format, which is OCaml's native binary serialization format. It can decode most common OCaml data types including integers, strings, floats, arrays, tuples, records, and shared data references.

## Features

### ✅ Supported Data Types

- **Integers**: All ranges from small integers (0-63) to 64-bit integers
- **Strings**: All sizes from small strings (<32 chars) to large strings
- **Floats**: Single doubles and float arrays
- **Blocks**: Tuples, records, variants, lists (tag-based structures)
- **Float Arrays**: Native float arrays with proper endianness handling
- **Shared References**: Handles OCaml's object sharing mechanism
- **Custom Blocks**: Int32, Int64, Nativeint (with both fixed and length-prefixed formats)

### ⚠️ Not Yet Supported

- Custom blocks with custom serializers (e.g., Bigarray)
- Code pointers and closures
- Big header format (for objects >4GB)

## Installation

Add this package to your MoonBit project:

```bash
moon add bobzhang/unmarshal
```

## Usage

### Basic Example

```mbt
///|
test "basic_usage" {
  let data : Bytes = [
    b'\x84', b'\x95', b'\xa6', b'\xbe', // Magic number
     b'\x00', b'\x00', b'\x00', b'\x01', // Data length: 1
     b'\x00', b'\x00', b'\x00', b'\x00', // Num objects: 0
     b'\x00', b'\x00', b'\x00', b'\x00', // Size 32: 0
     b'\x00', b'\x00', b'\x00', b'\x00', // Size 64: 0
     b'\x41', // Data: small int 1
  ]
  let decoder = @unmarshal.Decoder::new(data)
  let (header, value) = decoder.decode()

  // Verify the result
  inspect(header.magic, content="2224400062")
  inspect(value, content="MInt(1)")
}
```

### Decoding Different Data Types

#### Integers

```mbt
///|
test "decode_integers" {
  // Small integer (0-63): single byte encoding
  let small_int_data : Bytes = [
    b'\x84', b'\x95', b'\xa6', b'\xbe', b'\x00', b'\x00', b'\x00', b'\x01', b'\x00',
    b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00',
    b'\x00', b'\x00', b'\x6a', // 0x40 + 42 = 0x6a
  ]
  let decoder = @unmarshal.Decoder::new(small_int_data)
  let (_, value) = decoder.decode()
  inspect(value, content="MInt(42)")
}
```

#### Strings

```mbt
///|
test "decode_strings" {
  // Small string "Hello" (< 32 chars)
  let string_data : Bytes = [
    b'\x84', b'\x95', b'\xa6', b'\xbe', b'\x00', b'\x00', b'\x00', b'\x06', b'\x00',
    b'\x00', b'\x00', b'\x01', b'\x00', b'\x00', b'\x00', b'\x03', b'\x00', b'\x00',
    b'\x00', b'\x02', b'\x25', // PREFIX_SMALL_STRING + 5
     b'\x48', b'\x65', b'\x6c', b'\x6c', b'\x6f', // "Hello"
  ]
  let decoder = @unmarshal.Decoder::new(string_data)
  let (_, value) = decoder.decode()
  inspect(
    value,
    content=(
      #|MString(b"Hello")
    ),
  )
}
```

#### Tuples and Blocks

```mbt
///|
test "decode_tuple" {
  // Tuple (1, 2)
  let tuple_data : Bytes = [
    b'\x84', b'\x95', b'\xa6', b'\xbe', b'\x00', b'\x00', b'\x00', b'\x03', b'\x00',
    b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00',
    b'\x00', b'\x00', b'\xa0', // PREFIX_SMALL_BLOCK: tag=0, size=2
     b'\x41', // Small int 1
     b'\x42', // Small int 2
  ]
  let decoder = @unmarshal.Decoder::new(tuple_data)
  let (_, value) = decoder.decode()
  match value {
    @unmarshal.MBlock(tag~, fields) => {
      inspect(tag, content="0")
      inspect(fields.length(), content="2")
      inspect(fields[0], content="MInt(1)")
      inspect(fields[1], content="MInt(2)")
    }
    _ => abort("Expected MBlock")
  }
}
```

#### Float Arrays

```mbt
///|
test "decode_float_array" {
  // Simple float array [3.14, 2.71]
  let float_array_data : Bytes = [
    b'\x84', b'\x95', b'\xa6', b'\xbe', b'\x00', b'\x00', b'\x00', b'\x12', b'\x00',
    b'\x00', b'\x00', b'\x01', b'\x00', b'\x00', b'\x00', b'\x05', b'\x00', b'\x00',
    b'\x00', b'\x03', b'\x0e', b'\x02', // CODE_DOUBLE_ARRAY8_LITTLE, count=2
    // First double: 3.14 (little-endian)
     b'\x1f', b'\x85', b'\xeb', b'\x51', b'\xb8', b'\x1e', b'\x09', b'\x40',
    // Second double: 2.71 (little-endian)
     b'\x29', b'\x5c', b'\x8f', b'\xc2', b'\xf5', b'\xa8', b'\x05', b'\x40',
  ]
  let decoder = @unmarshal.Decoder::new(float_array_data)
  let (_, value) = decoder.decode()
  match value {
    @unmarshal.MDoubleArray(arr) => {
      inspect(arr.length(), content="2")
      // Values are approximately 3.14 and 2.71
      assert_true(arr[0] > 3.13 && arr[0] < 3.15)
      assert_true(arr[1] > 2.70 && arr[1] < 2.72)
    }
    _ => abort("Expected MDoubleArray")
  }
}
```

#### Custom Blocks (Int32, Int64, Nativeint)

OCaml's custom blocks allow specialized types like Int32, Int64, and Nativeint to be marshaled:

```mbt
///|
test "decode_int32" {
  // OCaml Int32.of_int 42
  let int32_data : Bytes = [
    b'\x84', b'\x95', b'\xa6', b'\xbe', b'\x00', b'\x00', b'\x00', b'\x08',
    b'\x00', b'\x00', b'\x00', b'\x01', b'\x00', b'\x00', b'\x00', b'\x03',
    b'\x00', b'\x00', b'\x00', b'\x03',
    b'\x19', // CODE_CUSTOM_FIXED
    b'\x5f', b'\x69', b'\x00', // "_i" identifier (null-terminated)
    b'\x00', b'\x00', b'\x00', b'\x2a', // 42 in big-endian
  ]
  let decoder = @unmarshal.Decoder::new(int32_data)
  let (_, value) = decoder.decode()
  match value {
    @unmarshal.MCustom(id, data) => {
      inspect(id, content="_i")
      // Extract the Int32 value (big-endian)
      let val = (data[0].to_int() << 24) | (data[1].to_int() << 16) |
                (data[2].to_int() << 8) | data[3].to_int()
      inspect(val, content="42")
    }
    _ => abort("Expected MCustom")
  }
}

///|
test "decode_int64" {
  // OCaml Int64.of_int 1000000
  let int64_data : Bytes = [
    b'\x84', b'\x95', b'\xa6', b'\xbe', b'\x00', b'\x00', b'\x00', b'\x0c',
    b'\x00', b'\x00', b'\x00', b'\x01', b'\x00', b'\x00', b'\x00', b'\x03',
    b'\x00', b'\x00', b'\x00', b'\x02',
    b'\x19', // CODE_CUSTOM_FIXED
    b'\x5f', b'\x6a', b'\x00', // "_j" identifier (null-terminated)
    b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x0f', b'\x42', b'\x40', // 1000000
  ]
  let decoder = @unmarshal.Decoder::new(int64_data)
  let (_, value) = decoder.decode()
  match value {
    @unmarshal.MCustom(id, _data) => {
      inspect(id, content="_j")
      // Custom blocks store the identifier and raw bytes
    }
    _ => abort("Expected MCustom")
  }
}
```

Custom block identifiers:
- `"_i"` - Int32
- `"_j"` - Int64
- `"_n"` - Nativeint

### Working with Shared References

OCaml's Marshal format supports object sharing to avoid duplicating data and handle cyclic structures:

```mbt
///|
test "shared_references" {
  // Tuple with shared string: ("shared", "shared")
  // The second string is a reference to the first
  let shared_data : Bytes = [
    b'\x84', b'\x95', b'\xa6', b'\xbe', b'\x00', b'\x00', b'\x00', b'\x0a', b'\x00',
    b'\x00', b'\x00', b'\x02', b'\x00', b'\x00', b'\x00', b'\x06', b'\x00', b'\x00',
    b'\x00', b'\x05', b'\xa0', // Small block, tag=0, size=2
     b'\x26', b'\x73', b'\x68', b'\x61', // Small string "shar"
     b'\x72', b'\x65', b'\x64', // "ed"
     b'\x04', b'\x01', // SHARED8, index 1
  ]
  let decoder = @unmarshal.Decoder::new(shared_data)
  let (_, value) = decoder.decode()
  match value {
    @unmarshal.MBlock(tag~, fields) => {
      inspect(tag, content="0")
      inspect(
        fields[0],
        content=(
          #|MString(b"shared")
        ),
      )
      inspect(
        fields[1],
        content=(
          #|MString(b"shared")
        ),
      ) // Reference to first field
    }
    _ => abort("Expected MBlock")
  }
}
```

## API Reference

### Types

#### `MarshalHeader`
Contains metadata about the marshaled data:
- `magic : UInt` - Magic number (0x8495A6BE or 0x8495A6BF)
- `data_len : Int` - Length of data section
- `num_objects : Int` - Number of shared objects
- `size_32 : Int` - Size on 32-bit platforms
- `size_64 : Int` - Size on 64-bit platforms

#### `MarshalValue`
Represents decoded OCaml values:
- `MInt(Int)` - Integer values
- `MString(Bytes)` - String/bytes
- `MFloat(Double)` - Floating point
- `MDoubleArray(Array[Double])` - Float array
- `MBlock(tag~ : Int, Array[MarshalValue])` - Structured data (tuples, records, variants)
- `MCustom(String, Bytes)` - Custom blocks (Int32, Int64, Nativeint, etc.)

### Decoder Functions

#### `Decoder::new(data : Bytes) -> Decoder`
Creates a new decoder from marshal data.

#### `Decoder::decode(self : Decoder) -> (MarshalHeader, MarshalValue) raise`
Decodes the marshal data, returning the header and value. Raises an error if the data is malformed.

## Implementation Details

### Encoding Format

The OCaml Marshal format uses a tag-based encoding system:

- **Small integers (0-63)**: Single byte `0x40 + n`
- **Small strings (<32 chars)**: `0x20 + len` followed by data
- **Small blocks**: `0x80 + tag + (size << 4)` for tag < 16, size < 8
- **Larger values**: Use specific code tags (INT8, INT16, STRING8, etc.)

### Endianness

- Integers are stored in big-endian format
- Floats can be either big-endian or little-endian (indicated by different tags)
- The decoder handles both endianness variants automatically

### Shared Objects

Every decoded object (except shared references themselves) is registered in an internal object table. When a shared reference is encountered, it points to an index in this table, enabling:
- Memory-efficient representation of repeated values
- Support for cyclic data structures
- Preservation of object identity

## Testing

Run the test suite:

```bash
moon test
```

Generate test data from OCaml:

```bash
ocaml test_generator.ml > marshal_data_test.mbt
```

## Contributing

Contributions are welcome! Areas that need work:
- Custom blocks with custom serializers (Bigarray, etc.)
- Big header format for large objects
- Better error messages with position information
- More comprehensive test coverage
- Performance optimizations

## License

This project is licensed under the Apache-2.0 License - see the LICENSE file for details.

## Acknowledgments

This implementation is based on the OCaml Marshal format specification and the OCaml runtime's `extern.c` implementation.