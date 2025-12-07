///|
/// Command-line tool to decode and visualize OCaml Marshal data
/// 
/// Usage:
///   moon run cmd/main -- <input-file> [--dot <output.dot>]
/// 
/// Examples:
///   moon run cmd/main -- data.bin --dot graph.dot
///   dot -Tsvg graph.dot -o graph.svg

///|
fn main {
  // For now, just demonstrate the API usage
  // Full CLI with file I/O requires moonbitlang/x or moonbitlang/core filesystem support

  println("OCaml Marshal Decoder & Visualizer")
  println("===================================")
  println("")
  println(
    "This tool decodes OCaml Marshal format and can generate Graphviz DOT output.",
  )
  println("")
  println("To use this tool programmatically:")
  println("  1. Load your marshal data as Bytes")
  println("  2. Call Decoder::new(data) and decoder.decode()")
  println("  3. Call marshal_to_dot(value) to generate DOT format")
  println("  4. Write the DOT string to a file")
  println("  5. Render with: dot -Tsvg output.dot -o output.svg")
  println("")
  println("Example code:")
  println("  let decoder = Decoder::new(your_bytes)")
  println("  let (header, value) = decoder.decode()!")
  println("  let dot = marshal_to_dot(value)")
  println("  // Write dot string to file and render")
}
