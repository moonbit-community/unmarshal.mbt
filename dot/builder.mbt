///|
/// Simple DOT (Graphviz) builder for visualizing MarshalValue structures
/// 
/// Provides utilities to construct directed graphs in DOT format for
/// rendering with Graphviz tools.

///|
priv struct DotNode {
  id : String
  label : String
  shape : String
  color : String
}

///|
priv struct DotEdge {
  src : String
  dst : String
  label : String
  style : String
  color : String
  bidirectional : Bool
}

///|
priv struct DotSubgraph {
  name : String
  label : String
  nodes : Array[String]
}

///|
struct DotBuilder {
  nodes : Array[DotNode]
  edges : Array[DotEdge]
  subgraphs : Array[DotSubgraph]
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
  self.nodes.push({ id, label, shape: "", color: "" })
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
  self.nodes.push({ id, label, shape, color })
}

///|
/// Add a subgraph (cluster) to group nodes
pub fn DotBuilder::add_subgraph(
  self : DotBuilder,
  name~ : String,
  label~ : String,
  nodes~ : Array[String],
) -> Unit {
  self.subgraphs.push({ name, label, nodes })
}

///|
/// Add an edge from src to dst with optional label
pub fn DotBuilder::add_edge(
  self : DotBuilder,
  src~ : String,
  dst~ : String,
  label~ : String,
) -> Unit {
  self.edges.push({
    src,
    dst,
    label,
    style: "",
    color: "",
    bidirectional: false,
  })
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
  self.edges.push({ src, dst, label, style, color, bidirectional: false })
}

///|
/// Add a bidirectional edge (two arrows)
pub fn DotBuilder::add_bidirectional_edge(
  self : DotBuilder,
  node1~ : String,
  node2~ : String,
  label~ : String,
) -> Unit {
  self.edges.push({
    src: node1,
    dst: node2,
    label,
    style: "",
    color: "",
    bidirectional: true,
  })
}

///|
/// Generate the complete DOT graph string
pub fn DotBuilder::to_dot(self : DotBuilder) -> String {
  let mut result = "digraph \{self.graph_name} {\n"
  result += "  rankdir=\{self.rankdir};\n"
  result += "  node [shape=\{self.default_node_shape}, style=\{self.default_node_style}];\n\n"

  // Add all subgraphs
  for subgraph in self.subgraphs {
    result += render_dot_subgraph(subgraph) + "\n\n"
  }

  // Add all nodes
  for node in self.nodes {
    result += render_dot_node(node) + "\n"
  }
  result += "\n"

  // Add all edges
  for edge in self.edges {
    result += render_dot_edge(edge) + "\n"
  }
  result += "}\n"
  result
}

///|
/// Generate Mermaid flowchart graph string (useful for Markdown rendering)
pub fn DotBuilder::to_mermaid(self : DotBuilder) -> String {
  let direction = rankdir_to_mermaid_direction(self.rankdir)
  let mut result = "flowchart \{direction}\n"
  if self.graph_name != "" {
    result += "%% graph: \{escape_mermaid_text(self.graph_name)}\n"
  }
  result += "\n"
  for subgraph in self.subgraphs {
    result += render_mermaid_subgraph(subgraph) + "\n\n"
  }
  for node in self.nodes {
    result += render_mermaid_node(node, self.default_node_shape) + "\n"
  }
  result += "\n"
  let link_styles : Array[String] = []
  let mut link_index = 0
  for edge in self.edges {
    let line = render_mermaid_edge(edge)
    result += line + "\n"
    let style = render_mermaid_link_style(edge)
    if style != "" {
      link_styles.push("linkStyle \{link_index} \{style}")
    }
    link_index += 1
  }
  let node_styles : Array[String] = []
  for node in self.nodes {
    if node.color != "" {
      node_styles.push(
        "style \{node.id} fill:\{node.color},stroke:#333,stroke-width:1px",
      )
    }
  }
  if node_styles.length() > 0 || link_styles.length() > 0 {
    result += "\n"
  }
  for line in node_styles {
    result += line + "\n"
  }
  for line in link_styles {
    result += line + "\n"
  }
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

///|
fn render_dot_subgraph(sg : DotSubgraph) -> String {
  let escaped = escape_dot_label(sg.label)
  let mut subgraph = "  subgraph cluster_\{sg.name} {\n"
  subgraph += "    label=\"\{escaped}\";\n"
  subgraph += "    style=filled;\n"
  subgraph += "    color=lightgrey;\n"
  for node in sg.nodes {
    subgraph += "    \{node};\n"
  }
  subgraph += "  }"
  subgraph
}

///|
fn render_dot_node(node : DotNode) -> String {
  let escaped = escape_dot_label(node.label)
  if node.shape == "" && node.color == "" {
    "  \{node.id} [label=\"\{escaped}\"];"
  } else {
    let attrs = if node.color == "" {
      "label=\"\{escaped}\", shape=\{node.shape}"
    } else {
      "label=\"\{escaped}\", shape=\{node.shape}, color=\"\{node.color}\", style=filled"
    }
    "  \{node.id} [\{attrs}];"
  }
}

///|
fn render_dot_edge(edge : DotEdge) -> String {
  if edge.bidirectional {
    if edge.label == "" {
      "  \{edge.src} -> \{edge.dst} [dir=both];"
    } else {
      let escaped = escape_dot_label(edge.label)
      "  \{edge.src} -> \{edge.dst} [label=\"\{escaped}\", dir=both];"
    }
  } else if edge.style != "" || edge.color != "" {
    let mut attrs = "style=\{edge.style}"
    if edge.color != "" {
      attrs += ", color=\"\{edge.color}\""
    }
    if edge.label != "" {
      let escaped = escape_dot_label(edge.label)
      attrs += ", label=\"\{escaped}\""
    }
    "  \{edge.src} -> \{edge.dst} [\{attrs}];"
  } else if edge.label == "" {
    "  \{edge.src} -> \{edge.dst};"
  } else {
    let escaped = escape_dot_label(edge.label)
    "  \{edge.src} -> \{edge.dst} [label=\"\{escaped}\"];"
  }
}

///|
fn rankdir_to_mermaid_direction(rankdir : String) -> String {
  match rankdir {
    "TB" => "TB"
    "BT" => "BT"
    "RL" => "RL"
    _ => "LR"
  }
}

///|
fn escape_mermaid_text(s : String) -> String {
  let mut result = ""
  for i = 0; i < s.length(); i = i + 1 {
    let c = s.code_unit_at(i).to_int()
    match c {
      0x26 => result += "&amp;" // &
      0x3C => result += "&lt;" // <
      0x3E => result += "&gt;" // >
      0x22 => result += "&quot;" // "
      0x7C => result += "&#124;" // |
      0x5B => result += "&#91;" // [
      0x5D => result += "&#93;" // ]
      0x28 => result += "&#40;" // (
      0x29 => result += "&#41;" // )
      0x7B => result += "&#123;" // {
      0x7D => result += "&#125;" // }
      0x0A => result += "<br/>" // \n
      0x0D => result += "<br/>" // \r
      0x09 => result += "  " // \t
      _ => result += c.unsafe_to_char().to_string()
    }
  }
  result
}

///|
fn render_mermaid_subgraph(sg : DotSubgraph) -> String {
  let escaped = escape_mermaid_text(sg.label)
  let mut result = "subgraph cluster_\{sg.name}[\"\{escaped}\"]\n"
  for node in sg.nodes {
    result += "  \{node}\n"
  }
  result += "end"
  result
}

///|
fn render_mermaid_node(node : DotNode, default_shape : String) -> String {
  let shape = if node.shape == "" { default_shape } else { node.shape }
  let label = escape_mermaid_text(node.label)
  match shape {
    "circle" => "  \{node.id}((\{label}))"
    "doublecircle" => "  \{node.id}(((\{label})))"
    "diamond" => "  \{node.id}{\{label}}"
    "ellipse" => "  \{node.id}([\{label}])"
    _ => "  \{node.id}[\"\{label}\"]"
  }
}

///|
fn render_mermaid_edge(edge : DotEdge) -> String {
  let arrow = if edge.bidirectional { "<-->" } else { "-->" }
  if edge.label == "" {
    "  \{edge.src} \{arrow} \{edge.dst}"
  } else {
    let label = escape_mermaid_text(edge.label)
    "  \{edge.src} \{arrow}|\{label}| \{edge.dst}"
  }
}

///|
fn render_mermaid_link_style(edge : DotEdge) -> String {
  let mut styles = ""
  if edge.style != "" {
    match edge.style {
      "bold" => styles += "stroke-width:3px"
      "dashed" => styles += "stroke-dasharray:5 5"
      "dotted" => styles += "stroke-dasharray:2 2"
      _ => ()
    }
  }
  if edge.color != "" {
    if styles != "" {
      styles += ","
    }
    styles += "stroke:\{edge.color}"
  }
  styles
}
