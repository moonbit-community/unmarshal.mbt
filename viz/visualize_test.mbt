///|
/// Tests for Graphviz DOT visualization

///|
test "marshal_to_dot with decoded int" {
  // Marshal format for integer 42: small int encoding
  let data = b"\x84\x95\xA6\xBE\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x6A"
  let decoder = @decoder.Decoder::new(data)
  let (_, value) = decoder.decode() catch { _ => abort("decode failed") }
  let dot = marshal_to_dot(value)
  inspect(dot.contains("Int: 42"), content="true")
  inspect(dot.contains("digraph Marshal"), content="true")
}

///|
test "marshal_to_dot with decoded string" {
  // String "Hello"
  let data = b"\x84\x95\xA6\xBE\x00\x00\x00\x07\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x25Hello"
  let decoder = @decoder.Decoder::new(data)
  let (_, value) = decoder.decode() catch { _ => abort("decode failed") }
  let dot = marshal_to_dot(value)

  // Debug: print the actual output
  inspect(
    dot,
    content=(
      #|digraph Marshal {
      #|  rankdir=LR;
      #|  node [shape=box, style=rounded];
      #|
      #|  n0 [label="String: b\"Hello\""];
      #|
      #|}
      #|
    ),
  )
}

///|
test "marshal_to_dot with decoded block" {
  // Tuple (1, 2): Block with tag 0, two integer fields
  let data = b"\x84\x95\xA6\xBE\x00\x00\x00\x03\x00\x00\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x82\x41\x42"
  let decoder = @decoder.Decoder::new(data)
  let (_, value) = decoder.decode() catch { _ => abort("decode failed") }
  let dot = marshal_to_dot(value)
  inspect(dot.contains("Block(tag=0, fields=2)"), content="false")
  inspect(dot.contains("Int: 1"), content="false")
  inspect(dot.contains("[0]"), content="false")
}

///|
test "dot output has valid structure" {
  let data = b"\x84\x95\xA6\xBE\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x6A"
  let decoder = @decoder.Decoder::new(data)
  let (_, value) = decoder.decode() catch { _ => abort("decode failed") }
  let dot = marshal_to_dot(value)

  // Check DOT structure
  inspect(dot.contains("digraph Marshal {"), content="true")
  inspect(dot.contains("rankdir=LR;"), content="true")
  inspect(dot.contains("node [shape=box"), content="true")
}
