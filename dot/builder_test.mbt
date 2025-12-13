///|
/// Tests for DotBuilder - showcasing various graph patterns

///|
/// Test 1: Simple linear chain
test "linear chain graph" (it : @test.Test) {
  let builder = DotBuilder::new()
  builder
  ..add_node(id="a", label="Start")
  ..add_node(id="b", label="Middle")
  ..add_node(id="c", label="End")
  ..add_edge(src="a", dst="b", label="→")
  ..add_edge(src="b", dst="c", label="→")
  let dot = builder.to_dot()
  it.write(dot)
  it.snapshot(filename=it.name() + ".dot")
}

///|
/// Test 2: Binary tree structure
test "binary tree graph" (it : @test.Test) {
  let builder = DotBuilder::new()
  builder
  ..add_node(id="root", label="Root")
  ..add_node(id="left", label="Left Child")
  ..add_node(id="right", label="Right Child")
  ..add_node(id="ll", label="Left-Left")
  ..add_node(id="lr", label="Left-Right")
  ..add_edge(src="root", dst="left", label="L")
  ..add_edge(src="root", dst="right", label="R")
  ..add_edge(src="left", dst="ll", label="L")
  ..add_edge(src="left", dst="lr", label="R")
  let dot = builder.to_dot()
  it.write(dot)
  it.snapshot(filename=it.name() + ".dot")
}

///|
/// Test 3: Cyclic graph (circular reference)
test "cyclic graph with self-loop" (it : @test.Test) {
  let builder = DotBuilder::new()
  builder
  ..add_node(id="a", label="Node A")
  ..add_node(id="b", label="Node B")
  ..add_node(id="c", label="Node C")
  // Create a cycle
  ..add_edge(src="a", dst="b", label="1")
  ..add_edge(src="b", dst="c", label="2")
  ..add_edge(src="c", dst="a", label="back to A")
  // Add a self-loop
  ..add_edge(src="b", dst="b", label="self")
  let dot = builder.to_dot()
  it.write(dot)
  it.snapshot(filename=it.name() + ".dot")
}

///|
/// Test 4: Star pattern (hub and spoke)
test "star graph pattern" (it : @test.Test) {
  let builder = DotBuilder::new()
  builder.add_node(id="hub", label="Central Hub")
  for i = 0; i < 5; i = i + 1 {
    let spoke_id = "spoke_\{i}"
    builder.add_node(id=spoke_id, label="Spoke \{i}")
    builder.add_edge(src="hub", dst=spoke_id, label="")
  }
  let dot = builder.to_dot()
  it.write(dot)
  it.snapshot(filename=it.name() + ".dot")
}

///|
/// Test 5: DAG (Directed Acyclic Graph) - dependency graph
test "dependency dag" (it : @test.Test) {
  let builder = DotBuilder::new()
  builder
  ..add_node(id="frontend", label="Frontend App")
  ..add_node(id="api", label="API Server")
  ..add_node(id="auth", label="Auth Service")
  ..add_node(id="db", label="Database")
  ..add_node(id="cache", label="Cache")
  ..add_edge(src="frontend", dst="api", label="HTTP")
  ..add_edge(src="api", dst="auth", label="verify")
  ..add_edge(src="api", dst="db", label="query")
  ..add_edge(src="api", dst="cache", label="get/set")
  ..add_edge(src="auth", dst="db", label="user lookup")
  let dot = builder.to_dot()
  it.write(dot)
  it.snapshot(filename=it.name() + ".dot")
}

///|
/// Test 6: Empty graph
test "empty graph" (it : @test.Test) {
  let builder = DotBuilder::new()
  let dot = builder.to_dot()
  it.write(dot)
  it.snapshot(filename=it.name() + ".dot")
}

///|
/// Test 7: Graph with special characters in labels
test "special characters in labels" (it : @test.Test) {
  let builder = DotBuilder::new()
  builder
  ..add_node(id="n1", label="Label with \"quotes\"")
  ..add_node(id="n2", label="Label with <brackets>")
  ..add_node(id="n3", label="Label with \n newline")
  ..add_edge(src="n1", dst="n2", label="edge → with → arrows")
  ..add_edge(src="n2", dst="n3", label="label & symbols")
  let dot = builder.to_dot()
  it.write(dot)
  it.snapshot(filename=it.name() + ".dot")
}

///|
/// Test 8: Multi-edge graph (multiple edges between same nodes)
test "multi-edge graph" (it : @test.Test) {
  let builder = DotBuilder::new()
  builder
  ..add_node(id="alice", label="Alice")
  ..add_node(id="bob", label="Bob")
  ..add_edge(src="alice", dst="bob", label="email")
  ..add_edge(src="alice", dst="bob", label="phone")
  ..add_edge(src="alice", dst="bob", label="slack")
  ..add_edge(src="bob", dst="alice", label="reply")
  let dot = builder.to_dot()
  it.write(dot)
  it.snapshot(filename=it.name() + ".dot")
}

///|
/// Test 9: Fresh ID generation
test "fresh_id generates unique ids" (it : @test.Test) {
  let builder = DotBuilder::new()
  let id1 = builder.fresh_id()
  let id2 = builder.fresh_id()
  let id3 = builder.fresh_id()
  // IDs should be in sequence
  it.write("id1: \{id1}\n")
  it.write("id2: \{id2}\n")
  it.write("id3: \{id3}\n")
  it.snapshot(filename=it.name() + ".txt")
}

///|
/// Test 10: Large graph stress test (100 nodes)
test "large graph with 100 nodes" (it : @test.Test) {
  let builder = DotBuilder::new()
  // Create a chain of 100 nodes
  for i = 0; i < 100; i = i + 1 {
    let node_id = "n\{i}"
    builder.add_node(id=node_id, label="Node \{i}")
    if i > 0 {
      builder.add_edge(src="n\{i - 1}", dst=node_id, label="")
    }
  }
  let dot = builder.to_dot()
  it.write(dot)
  it.snapshot(filename=it.name() + ".dot")
}

///|
/// Test 11: Complete graph K5 (all nodes connected to all others)
test "complete graph k5" (it : @test.Test) {
  let builder = DotBuilder::new()
  let nodes = ["a", "b", "c", "d", "e"]
  // Add all nodes
  for i = 0; i < nodes.length(); i = i + 1 {
    builder.add_node(id=nodes[i], label="Node \{nodes[i].to_upper()}")
  }
  // Add all edges (complete graph)
  for i = 0; i < nodes.length(); i = i + 1 {
    for j = 0; j < nodes.length(); j = j + 1 {
      if i != j {
        builder.add_edge(src=nodes[i], dst=nodes[j], label="\{i}→\{j}")
      }
    }
  }
  let dot = builder.to_dot()
  it.write(dot)
  it.snapshot(filename=it.name() + ".dot")
}

///|
/// Test 12: Unicode labels
test "unicode in labels" (it : @test.Test) {
  let builder = DotBuilder::new()
  builder
  ..add_node(id="emoji", label="😀 🎉 ✨")
  ..add_node(id="chinese", label="中文测试")
  ..add_node(id="arabic", label="مرحبا")
  ..add_node(id="math", label="∑ ∫ ∂ √")
  ..add_edge(src="emoji", dst="chinese", label="→")
  ..add_edge(src="chinese", dst="arabic", label="→")
  ..add_edge(src="arabic", dst="math", label="→")
  let dot = builder.to_dot()
  it.write(dot)
  it.snapshot(filename=it.name() + ".dot")
}
