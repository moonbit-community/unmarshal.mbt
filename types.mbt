///|
/// OCaml Marshal header structure (20 bytes total)
/// 
/// Contains metadata about the marshaled data including magic number for
/// format validation, data length, and platform-specific size information.
/// 
pub(all) struct MarshalHeader {
  /// Format identifier (0x8495A6BE or 0x8495A6BF)  
  magic : UInt
  /// Length of data section (excluding 20-byte header)
  data_len : Int
  /// Number of objects that can be shared/referenced
  num_objects : Int
  /// Size of integers/pointers on 32-bit platforms
  size_32 : Int
  /// Size of integers/pointers on 64-bit platforms
  size_64 : Int
} derive(Debug, Eq, ToJson)

///|
/// Represents all possible OCaml values that can be unmarshaled
/// 
/// This enum covers the complete range of OCaml data types that can be
/// serialized with the Marshal module. Each variant corresponds to specific
/// OCaml runtime representations.
/// 
/// ## Variants
/// 
pub(all) enum MarshalValue {
  /// OCaml integers (31-bit on 32-bit, 63-bit on 64-bit platforms)  
  MInt(Int)
  /// OCaml strings with UTF-8 encoding
  MString(Bytes) // OCaml string is Bytes
  /// OCaml floats (IEEE 754 double precision)  
  MFloat(Double)
  /// OCaml float arrays
  MDoubleArray(Array[Double])
  /// - `MBlock(Int, Array[MarshalValue])`: Structured data with tag and fields
  /// - Used for tuples, records, variants, lists, arrays
  /// - Tag indicates the specific OCaml constructor or structure type
  MBlock(tag~ : Int, Array[MarshalValue]) // tag, fields
  /// User-defined serializable objects (PLANNED)
  MCustom(String, Bytes) // Custom blocks (not yet implemented)
  /// Reference to shared object by index (PLANNED)
  /// ## Sharing System
  /// Objects are automatically registered in a shared object table during parsing
  /// to handle OCaml's object sharing and cyclic reference support.
  // MShared(Int) // Shared reference (currently resolved immediately during decoding)
} derive(Debug, Eq, ToJson, Hash)

///|
pub impl Show for MarshalHeader with fn output(self, logger) {
  logger.write_string(@debug.render(self.to_repr(), max_depth=2147483647))
}

///|
pub impl Show for MarshalValue with fn output(self, logger) {
  logger.write_string(@debug.render(self.to_repr(), max_depth=2147483647))
}
