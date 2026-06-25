// Shared value model lives in the root `bobzhang/unmarshal` package.

///|
using @unmarshal {type MarshalValue}

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
      builder.add_node(id~, label="Int: \{n}")
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
      builder.add_node(id~, label~)
      id
    }
    MFloat(f) => {
      let id = builder.fresh_id()
      builder.add_node(id~, label="Float: \{f}")
      id
    }
    MDoubleArray(arr) => {
      let id = builder.fresh_id()
      builder.add_node(id~, label="DoubleArray[\{arr.length()}]")

      // Add edges to first few elements (to avoid cluttering)
      let max_show = if arr.length() > 10 { 10 } else { arr.length() }
      for i = 0; i < max_show; i = i + 1 {
        let elem_id = builder.fresh_id()
        builder.add_node(id=elem_id, label="Float: \{arr[i]}")
        builder.add_edge(src=id, dst=elem_id, label="[\{i}]")
      }
      if arr.length() > max_show {
        let ellipsis_id = builder.fresh_id()
        builder.add_node(
          id=ellipsis_id,
          label="... \{arr.length() - max_show} more",
        )
        builder.add_edge(src=id, dst=ellipsis_id, label="")
      }
      id
    }
    MBlock(tag~, fields) => {
      let id = builder.fresh_id()
      builder.add_node(
        id~,
        label="Block(tag=\{tag}, fields=\{fields.length()})",
      )

      // Add edges to all fields
      for i = 0; i < fields.length(); i = i + 1 {
        let field_id = add_value_to_dot(builder, fields[i])
        builder.add_edge(src=id, dst=field_id, label="[\{i}]")
      }
      id
    }
    MCustom(ident, data) => {
      let id = builder.fresh_id()
      builder.add_node(id~, label="Custom: \{ident} (\{data.length()} bytes)")
      id
    }
  }
}
