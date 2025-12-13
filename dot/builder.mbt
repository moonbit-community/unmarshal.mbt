///|
/// Simple DOT (Graphviz) builder for visualizing MarshalValue structures
/// 
/// Provides utilities to construct directed graphs in DOT format for
/// rendering with Graphviz tools.

///|
struct DotBuilder {
  nodes : Array[String]
  edges : Array[String]
  subgraphs : Array[String]
  mut next_id : Int
  graph_name : String
  rankdir : String // "TB", "LR", "BT", "RL"
  mut default_node_shape : String // "box", "circle", "ellipse", "diamond", etc.
  mut default_node_style : String // "rounded", "filled", etc.
}

///|
pub fn DotBuilder::new() -> DotBuilder {
  {
    nodes: [],
    edges: [],
    subgraphs: [],
    next_id: 0,
    graph_name: "Marshal",
    rankdir: "LR",
    default_node_shape: "box",
    default_node_style: "rounded",
  }
}

///|
/// Create a new DotBuilder with custom graph name and direction
/// rankdir can be: "TB" (top-bottom), "LR" (left-right), "BT" (bottom-top), "RL" (right-left)
pub fn DotBuilder::with_config(
  graph_name~ : String,
  rankdir~ : String,
) -> DotBuilder {
  {
    nodes: [],
    edges: [],
    subgraphs: [],
    next_id: 0,
    graph_name,
    rankdir,
    default_node_shape: "box",
    default_node_style: "rounded",
  }
}

///|
/// Set the default node shape
/// Common shapes: "box", "circle", "ellipse", "diamond", "rectangle", "square",
/// "triangle", "pentagon", "hexagon", "octagon", "doublecircle", "plaintext"
pub fn DotBuilder::set_node_shape(self : DotBuilder, shape : String) -> Unit {
  self.default_node_shape = shape
}

///|
/// Set the default node style
pub fn DotBuilder::set_node_style(self : DotBuilder, style : String) -> Unit {
  self.default_node_style = style
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
pub fn DotBuilder::add_node(
  self : DotBuilder,
  id~ : String,
  label~ : String,
) -> Unit {
  let escaped = escape_dot_label(label)
  self.nodes.push("  \{id} [label=\"\{escaped}\"];")
}

///|
/// Add a node with custom shape and optional color
/// shape: "box", "circle", "ellipse", "diamond", etc.
/// color: any HTML color name or hex code (empty string for no color)
pub fn DotBuilder::add_styled_node(
  self : DotBuilder,
  id~ : String,
  label~ : String,
  shape~ : String,
  color~ : String,
) -> Unit {
  let escaped = escape_dot_label(label)
  let attrs = if color == "" {
    "label=\"\{escaped}\", shape=\{shape}"
  } else {
    "label=\"\{escaped}\", shape=\{shape}, color=\"\{color}\", style=filled"
  }
  self.nodes.push("  \{id} [\{attrs}];")
}

///|
/// Add a subgraph (cluster) to group nodes
pub fn DotBuilder::add_subgraph(
  self : DotBuilder,
  name~ : String,
  label~ : String,
  nodes~ : Array[String],
) -> Unit {
  let escaped = escape_dot_label(label)
  let mut subgraph = "  subgraph cluster_\{name} {\n"
  subgraph += "    label=\"\{escaped}\";\n"
  subgraph += "    style=filled;\n"
  subgraph += "    color=lightgrey;\n"
  for node in nodes {
    subgraph += "    \{node};\n"
  }
  subgraph += "  }"
  self.subgraphs.push(subgraph)
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
/// Add a styled edge with custom style and color
/// style: "solid", "dashed", "dotted", "bold"
/// color: any HTML color name or hex code
pub fn DotBuilder::add_styled_edge(
  self : DotBuilder,
  src~ : String,
  dst~ : String,
  label~ : String,
  style~ : String,
  color~ : String,
) -> Unit {
  let mut attrs = "style=\{style}"
  if color != "" {
    attrs += ", color=\"\{color}\""
  }
  if label != "" {
    let escaped = escape_dot_label(label)
    attrs += ", label=\"\{escaped}\""
  }
  self.edges.push("  \{src} -> \{dst} [\{attrs}];")
}

///|
/// Add a bidirectional edge (two arrows)
pub fn DotBuilder::add_bidirectional_edge(
  self : DotBuilder,
  node1~ : String,
  node2~ : String,
  label~ : String,
) -> Unit {
  if label == "" {
    self.edges.push("  \{node1} -> \{node2} [dir=both];")
  } else {
    let escaped = escape_dot_label(label)
    self.edges.push("  \{node1} -> \{node2} [label=\"\{escaped}\", dir=both];")
  }
}

///|
/// Generate the complete DOT graph string
pub fn DotBuilder::to_dot(self : DotBuilder) -> String {
  let mut result = "digraph \{self.graph_name} {\n"
  result += "  rankdir=\{self.rankdir};\n"
  result += "  node [shape=\{self.default_node_shape}, style=\{self.default_node_style}];\n\n"

  // Add all subgraphs
  for subgraph in self.subgraphs {
    result += subgraph + "\n\n"
  }

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
