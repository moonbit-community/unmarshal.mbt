///|
/// Tests for DotBuilder Mermaid output

///|
test "linear chain graph (mermaid)" (it : @test.Test) {
  let builder = DotBuilder::new()
  builder
  ..add_node(id="a", label="Start")
  ..add_node(id="b", label="Middle")
  ..add_node(id="c", label="End")
  ..add_edge(src="a", dst="b", label="→")
  ..add_edge(src="b", dst="c", label="→")
  let mermaid = builder.to_mermaid()
  it.write(mermaid)
  it.snapshot(filename=it.name() + ".mmd")
}

///|
test "custom graph direction (mermaid)" (it : @test.Test) {
  let builder = DotBuilder::with_config(graph_name="Vertical", rankdir="TB")
  builder
  ..add_node(id="top", label="Top")
  ..add_node(id="middle", label="Middle")
  ..add_node(id="bottom", label="Bottom")
  ..add_edge(src="top", dst="middle", label="↓")
  ..add_edge(src="middle", dst="bottom", label="↓")
  let mermaid = builder.to_mermaid()
  it.write(mermaid)
  it.snapshot(filename=it.name() + ".mmd")
}

///|
test "styled nodes with shapes and colors (mermaid)" (it : @test.Test) {
  let builder = DotBuilder::new()
  builder
  ..add_styled_node(id="start", label="Start", shape="circle", color="green")
  ..add_styled_node(
    id="process",
    label="Process",
    shape="box",
    color="lightblue",
  )
  ..add_styled_node(
    id="decision",
    label="Decision?",
    shape="diamond",
    color="yellow",
  )
  ..add_styled_node(id="end", label="End", shape="doublecircle", color="red")
  ..add_edge(src="start", dst="process", label="")
  ..add_edge(src="process", dst="decision", label="")
  ..add_edge(src="decision", dst="end", label="yes")
  let mermaid = builder.to_mermaid()
  it.write(mermaid)
  it.snapshot(filename=it.name() + ".mmd")
}

///|
test "styled edges with different styles (mermaid)" (it : @test.Test) {
  let builder = DotBuilder::new()
  builder
  ..add_node(id="a", label="Node A")
  ..add_node(id="b", label="Node B")
  ..add_node(id="c", label="Node C")
  ..add_styled_edge(
    src="a",
    dst="b",
    label="solid",
    style="solid",
    color="black",
  )
  ..add_styled_edge(
    src="a",
    dst="c",
    label="dashed",
    style="dashed",
    color="blue",
  )
  ..add_styled_edge(
    src="b",
    dst="c",
    label="dotted",
    style="dotted",
    color="red",
  )
  let mermaid = builder.to_mermaid()
  it.write(mermaid)
  it.snapshot(filename=it.name() + ".mmd")
}

///|
test "bidirectional edges (mermaid)" (it : @test.Test) {
  let builder = DotBuilder::new()
  builder
  ..add_node(id="client", label="Client")
  ..add_node(id="server", label="Server")
  ..add_node(id="database", label="Database")
  ..add_bidirectional_edge(node1="client", node2="server", label="HTTP")
  ..add_edge(src="server", dst="database", label="query")
  ..add_bidirectional_edge(node1="server", node2="database", label="")
  let mermaid = builder.to_mermaid()
  it.write(mermaid)
  it.snapshot(filename=it.name() + ".mmd")
}

///|
test "subgraph clusters (mermaid)" (it : @test.Test) {
  let builder = DotBuilder::new()
  builder
  ..add_node(id="web1", label="Web1")
  ..add_node(id="web2", label="Web2")
  ..add_node(id="app1", label="App1")
  ..add_node(id="app2", label="App2")
  ..add_node(id="db", label="DB")
  ..add_subgraph(name="frontend", label="Frontend Tier", nodes=["web1", "web2"])
  ..add_subgraph(name="backend", label="Backend Tier", nodes=["app1", "app2"])
  ..add_edge(src="web1", dst="app1", label="")
  ..add_edge(src="web2", dst="app2", label="")
  ..add_edge(src="app1", dst="db", label="")
  ..add_edge(src="app2", dst="db", label="")
  let mermaid = builder.to_mermaid()
  it.write(mermaid)
  it.snapshot(filename=it.name() + ".mmd")
}

///|
test "special characters in labels (mermaid)" (it : @test.Test) {
  let builder = DotBuilder::new()
  builder
  ..add_node(id="n1", label="Label with \"quotes\"")
  ..add_node(id="n2", label="Label with <brackets>")
  ..add_node(id="n3", label="Label with \n newline")
  ..add_edge(src="n1", dst="n2", label="edge → with → arrows")
  ..add_edge(src="n2", dst="n3", label="label & symbols | pipes")
  let mermaid = builder.to_mermaid()
  it.write(mermaid)
  it.snapshot(filename=it.name() + ".mmd")
}
