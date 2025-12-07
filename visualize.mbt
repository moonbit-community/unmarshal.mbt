///|
/// Convert MarshalValue to Graphviz DOT format for visualization

///|
/// Convert a MarshalValue to DOT format
/// Returns a DOT string that can be rendered with Graphviz
pub fn marshal_to_dot(value : MarshalValue) -> String {
  let builder = @dot.DotBuilder::new()
  let _ = add_value_to_dot(builder, value)
  builder.to_dot()
}

///|
/// Recursively add a MarshalValue and its children to the DOT builder
/// Returns the node ID for this value
fn add_value_to_dot(builder : @dot.DotBuilder, value : MarshalValue) -> String {
  match value {
    MInt(n) => {
      let id = builder.fresh_id()
      builder.add_node(id, "Int: \{n}")
      id
    }
    MString(bytes) => {
      let id = builder.fresh_id()
      // Try to show as string, truncate if too long
      let s = bytes.to_string()
      let label = if s.length() > 50 {
        // Manual truncation to avoid slice error handling
        let mut prefix = ""
        for i = 0; i < 50; i = i + 1 {
          prefix += s.code_unit_at(i).to_int().unsafe_to_char().to_string()
        }
        "String: \{prefix}..."
      } else {
        "String: \{s}"
      }
      builder.add_node(id, label)
      id
    }
    MFloat(f) => {
      let id = builder.fresh_id()
      builder.add_node(id, "Float: \{f}")
      id
    }
    MDoubleArray(arr) => {
      let id = builder.fresh_id()
      builder.add_node(id, "DoubleArray[\{arr.length()}]")

      // Add edges to first few elements (to avoid cluttering)
      let max_show = if arr.length() > 10 { 10 } else { arr.length() }
      for i = 0; i < max_show; i = i + 1 {
        let elem_id = builder.fresh_id()
        builder.add_node(elem_id, "Float: \{arr[i]}")
        builder.add_edge(id, elem_id, "[\{i}]")
      }
      if arr.length() > max_show {
        let ellipsis_id = builder.fresh_id()
        builder.add_node(ellipsis_id, "... \{arr.length() - max_show} more")
        builder.add_edge(id, ellipsis_id, "")
      }
      id
    }
    MBlock(tag~, fields) => {
      let id = builder.fresh_id()
      builder.add_node(id, "Block(tag=\{tag}, fields=\{fields.length()})")

      // Add edges to all fields
      for i = 0; i < fields.length(); i = i + 1 {
        let field_id = add_value_to_dot(builder, fields[i])
        builder.add_edge(id, field_id, "[\{i}]")
      }
      id
    }
    MCustom(ident, data) => {
      let id = builder.fresh_id()
      builder.add_node(id, "Custom: \{ident} (\{data.length()} bytes)")
      id
    }
  }
}
