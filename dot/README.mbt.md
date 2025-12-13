# `bobzhang/unmarshal/dot`

Small graph builder that can render either:

- Graphviz DOT (`DotBuilder::to_dot`)
- Mermaid flowchart (`DotBuilder::to_mermaid`)

## Install

```bash
moon add bobzhang/unmarshal/dot
```

## Quickstart (DOT)

```mbt
///|
test "dot: quickstart" {
  let builder = @dot.DotBuilder::new()
  builder
  ..add_node(id="a", label="Start")
  ..add_node(id="b", label="End")
  ..add_edge(src="a", dst="b", label="→")
  let got = builder.to_dot()
  let expected = "digraph Marshal {\n" +
    "  rankdir=LR;\n" +
    "  node [shape=box, style=rounded];\n" +
    "\n" +
    "  a [label=\"Start\"];\n" +
    "  b [label=\"End\"];\n" +
    "\n" +
    "  a -> b [label=\"→\"];\n" +
    "}\n"
  assert_eq(got, expected)
}
```

## Quickstart (Mermaid)

```mbt
///|
test "dot: quickstart (mermaid)" {
  let builder = @dot.DotBuilder::new()
  builder
  ..add_node(id="a", label="Start")
  ..add_node(id="b", label="End")
  ..add_edge(src="a", dst="b", label="→")
  let got = builder.to_mermaid()
  let expected = "flowchart LR\n" +
    "%% graph: Marshal\n" +
    "\n" +
    "  a[\"Start\"]\n" +
    "  b[\"End\"]\n" +
    "\n" +
    "  a -->|→| b\n"
  assert_eq(got, expected)
}
```

## Direction and styling

```mbt
///|
test "dot: direction and styling (mermaid)" {
  let builder = @dot.DotBuilder::with_config(
    graph_name="Vertical",
    rankdir="TB",
  )
  builder
  ..add_styled_node(id="start", label="Start", shape="circle", color="green")
  ..add_styled_node(id="end", label="End", shape="doublecircle", color="red")
  ..add_styled_edge(
    src="start",
    dst="end",
    label="go",
    style="dashed",
    color="blue",
  )
  let got = builder.to_mermaid()
  let expected = "flowchart TB\n" +
    "%% graph: Vertical\n" +
    "\n" +
    "  start((Start))\n" +
    "  end(((End)))\n" +
    "\n" +
    "  start -->|go| end\n" +
    "\n" +
    "style start fill:green,stroke:#333,stroke-width:1px\n" +
    "style end fill:red,stroke:#333,stroke-width:1px\n" +
    "linkStyle 0 stroke-dasharray:5 5,stroke:blue\n"
  assert_eq(got, expected)
}
```

