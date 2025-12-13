///|
/// Simple DOT (Graphviz) builder for visualizing MarshalValue structures
/// 
/// Provides utilities to construct directed graphs in DOT format for
/// rendering with Graphviz tools.

///|
struct DotBuilder {
  nodes : Array[String]
  edges : Array[String]
  mut next_id : Int
}

///|
pub fn DotBuilder::new() -> DotBuilder {
  { nodes: [], edges: [], next_id: 0 }
}

///|
/// Generate a unique node ID
pub fn DotBuilder::fresh_id(self : DotBuilder) -> String {
  let id = "n\{self.next_id}"
  self.next_id += 1
  id
}

///|
/// Add a node with a label
/// Returns the node ID
pub fn DotBuilder::add_node(
  self : DotBuilder,
  id~ : String,
  label~ : String,
) -> Unit {
  let escaped = escape_dot_label(label)
  self.nodes.push("  \{id} [label=\"\{escaped}\"];")
}

///|
/// Add an edge from src to dst with optional label
pub fn DotBuilder::add_edge(
  self : DotBuilder,
  src~ : String,
  dst~ : String,
  label~ : String,
) -> Unit {
  if label == "" {
    self.edges.push("  \{src} -> \{dst};")
  } else {
    let escaped = escape_dot_label(label)
    self.edges.push("  \{src} -> \{dst} [label=\"\{escaped}\"];")
  }
}

///|
/// Generate the complete DOT graph string
pub fn DotBuilder::to_dot(self : DotBuilder) -> String {
  let mut result = "digraph Marshal {\n"
  result += "  rankdir=LR;\n"
  result += "  node [shape=box, style=rounded];\n\n"

  // Add all nodes
  for node in self.nodes {
    result += node + "\n"
  }
  result += "\n"

  // Add all edges
  for edge in self.edges {
    result += edge + "\n"
  }
  result += "}\n"
  result
}

///|
/// Escape special characters for DOT labels
fn escape_dot_label(s : String) -> String {
  let mut result = ""
  for i = 0; i < s.length(); i = i + 1 {
    let c = s.code_unit_at(i).to_int()
    match c {
      0x22 => result += "\\\"" // "
      0x5C => result += "\\\\" // \
      0x0A => result += "\\n" // \n
      0x0D => result += "\\r" // \r
      0x09 => result += "\\t" // \t
      _ => result += c.unsafe_to_char().to_string()
    }
  }
  result
}
