///|
/// Tests for DotBuilder - showcasing various graph patterns

///|
/// Test 1: Simple linear chain
test "linear chain graph" {
  let builder = DotBuilder::new()
  builder.add_node(id="a", label="Start")
  builder.add_node(id="b", label="Middle")
  builder.add_node(id="c", label="End")
  builder.add_edge(src="a", dst="b", label="→")
  builder.add_edge(src="b", dst="c", label="→")
  let dot = builder.to_dot()
  inspect(
    dot,
    content=(
      #|digraph Marshal {
      #|  rankdir=LR;
      #|  node [shape=box, style=rounded];
      #|
      #|  a [label="Start"];
      #|  b [label="Middle"];
      #|  c [label="End"];
      #|
      #|  a -> b [label="→"];
      #|  b -> c [label="→"];
      #|}
      #|
    ),
  )
}

///|
/// Test 2: Binary tree structure
test "binary tree graph" {
  let builder = DotBuilder::new()
  builder.add_node(id="root", label="Root")
  builder.add_node(id="left", label="Left Child")
  builder.add_node(id="right", label="Right Child")
  builder.add_node(id="ll", label="Left-Left")
  builder.add_node(id="lr", label="Left-Right")
  builder.add_edge(src="root", dst="left", label="L")
  builder.add_edge(src="root", dst="right", label="R")
  builder.add_edge(src="left", dst="ll", label="L")
  builder.add_edge(src="left", dst="lr", label="R")
  let dot = builder.to_dot()
  inspect(
    dot,
    content=(
      #|digraph Marshal {
      #|  rankdir=LR;
      #|  node [shape=box, style=rounded];
      #|
      #|  root [label="Root"];
      #|  left [label="Left Child"];
      #|  right [label="Right Child"];
      #|  ll [label="Left-Left"];
      #|  lr [label="Left-Right"];
      #|
      #|  root -> left [label="L"];
      #|  root -> right [label="R"];
      #|  left -> ll [label="L"];
      #|  left -> lr [label="R"];
      #|}
      #|
    ),
  )
}

///|
/// Test 3: Cyclic graph (circular reference)
test "cyclic graph with self-loop" {
  let builder = DotBuilder::new()
  builder.add_node(id="a", label="Node A")
  builder.add_node(id="b", label="Node B")
  builder.add_node(id="c", label="Node C")
  // Create a cycle
  builder.add_edge(src="a", dst="b", label="1")
  builder.add_edge(src="b", dst="c", label="2")
  builder.add_edge(src="c", dst="a", label="back to A")
  // Add a self-loop
  builder.add_edge(src="b", dst="b", label="self")
  let dot = builder.to_dot()
  inspect(
    dot,
    content=(
      #|digraph Marshal {
      #|  rankdir=LR;
      #|  node [shape=box, style=rounded];
      #|
      #|  a [label="Node A"];
      #|  b [label="Node B"];
      #|  c [label="Node C"];
      #|
      #|  a -> b [label="1"];
      #|  b -> c [label="2"];
      #|  c -> a [label="back to A"];
      #|  b -> b [label="self"];
      #|}
      #|
    ),
  )
}

///|
/// Test 4: Star pattern (hub and spoke)
test "star graph pattern" {
  let builder = DotBuilder::new()
  builder.add_node(id="hub", label="Central Hub")
  for i = 0; i < 5; i = i + 1 {
    let spoke_id = "spoke_\{i}"
    builder.add_node(id=spoke_id, label="Spoke \{i}")
    builder.add_edge(src="hub", dst=spoke_id, label="")
  }
  let dot = builder.to_dot()
  inspect(
    dot,
    content=(
      #|digraph Marshal {
      #|  rankdir=LR;
      #|  node [shape=box, style=rounded];
      #|
      #|  hub [label="Central Hub"];
      #|  spoke_0 [label="Spoke 0"];
      #|  spoke_1 [label="Spoke 1"];
      #|  spoke_2 [label="Spoke 2"];
      #|  spoke_3 [label="Spoke 3"];
      #|  spoke_4 [label="Spoke 4"];
      #|
      #|  hub -> spoke_0;
      #|  hub -> spoke_1;
      #|  hub -> spoke_2;
      #|  hub -> spoke_3;
      #|  hub -> spoke_4;
      #|}
      #|
    ),
  )
}

///|
/// Test 5: DAG (Directed Acyclic Graph) - dependency graph
test "dependency dag" {
  let builder = DotBuilder::new()
  builder.add_node(id="frontend", label="Frontend App")
  builder.add_node(id="api", label="API Server")
  builder.add_node(id="auth", label="Auth Service")
  builder.add_node(id="db", label="Database")
  builder.add_node(id="cache", label="Cache")
  builder.add_edge(src="frontend", dst="api", label="HTTP")
  builder.add_edge(src="api", dst="auth", label="verify")
  builder.add_edge(src="api", dst="db", label="query")
  builder.add_edge(src="api", dst="cache", label="get/set")
  builder.add_edge(src="auth", dst="db", label="user lookup")
  let dot = builder.to_dot()
  inspect(
    dot,
    content=(
      #|digraph Marshal {
      #|  rankdir=LR;
      #|  node [shape=box, style=rounded];
      #|
      #|  frontend [label="Frontend App"];
      #|  api [label="API Server"];
      #|  auth [label="Auth Service"];
      #|  db [label="Database"];
      #|  cache [label="Cache"];
      #|
      #|  frontend -> api [label="HTTP"];
      #|  api -> auth [label="verify"];
      #|  api -> db [label="query"];
      #|  api -> cache [label="get/set"];
      #|  auth -> db [label="user lookup"];
      #|}
      #|
    ),
  )
}

///|
/// Test 6: Empty graph
test "empty graph" {
  let builder = DotBuilder::new()
  let dot = builder.to_dot()
  inspect(
    dot,
    content=(
      #|digraph Marshal {
      #|  rankdir=LR;
      #|  node [shape=box, style=rounded];
      #|
      #|
      #|}
      #|
    ),
  )
}

///|
/// Test 7: Graph with special characters in labels
test "special characters in labels" {
  let builder = DotBuilder::new()
  builder.add_node(id="n1", label="Label with \"quotes\"")
  builder.add_node(id="n2", label="Label with <brackets>")
  builder.add_node(id="n3", label="Label with \n newline")
  builder.add_edge(src="n1", dst="n2", label="edge → with → arrows")
  builder.add_edge(src="n2", dst="n3", label="label & symbols")
  let dot = builder.to_dot()
  inspect(
    dot,
    content=(
      #|digraph Marshal {
      #|  rankdir=LR;
      #|  node [shape=box, style=rounded];
      #|
      #|  n1 [label="Label with \"quotes\""];
      #|  n2 [label="Label with <brackets>"];
      #|  n3 [label="Label with \n newline"];
      #|
      #|  n1 -> n2 [label="edge → with → arrows"];
      #|  n2 -> n3 [label="label & symbols"];
      #|}
      #|
    ),
  )
}

///|
/// Test 8: Multi-edge graph (multiple edges between same nodes)
test "multi-edge graph" {
  let builder = DotBuilder::new()
  builder.add_node(id="alice", label="Alice")
  builder.add_node(id="bob", label="Bob")
  builder.add_edge(src="alice", dst="bob", label="email")
  builder.add_edge(src="alice", dst="bob", label="phone")
  builder.add_edge(src="alice", dst="bob", label="slack")
  builder.add_edge(src="bob", dst="alice", label="reply")
  let dot = builder.to_dot()
  inspect(
    dot,
    content=(
      #|digraph Marshal {
      #|  rankdir=LR;
      #|  node [shape=box, style=rounded];
      #|
      #|  alice [label="Alice"];
      #|  bob [label="Bob"];
      #|
      #|  alice -> bob [label="email"];
      #|  alice -> bob [label="phone"];
      #|  alice -> bob [label="slack"];
      #|  bob -> alice [label="reply"];
      #|}
      #|
    ),
  )
}

///|
/// Test 9: Fresh ID generation
test "fresh_id generates unique ids" {
  let builder = DotBuilder::new()
  let id1 = builder.fresh_id()
  let id2 = builder.fresh_id()
  let id3 = builder.fresh_id()
  // IDs should be in sequence
  inspect(id1, content="n0")
  inspect(id2, content="n1")
  inspect(id3, content="n2")
}

///|
/// Test 10: Large graph stress test (100 nodes)
test "large graph with 100 nodes" {
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
  // Verify it starts and ends correctly
  inspect(dot.contains("digraph G {"), content="false")
  inspect(dot.contains("\"n0\" [label=\"Node 0\"]"), content="false")
  inspect(dot.contains("\"n99\" [label=\"Node 99\"]"), content="false")
  inspect(dot.contains("\"n98\" -> \"n99\" [label=\"\"]"), content="false")
}

///|
/// Test 11: Complete graph K5 (all nodes connected to all others)
test "complete graph k5" {
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
  // K5 should have 5 nodes and 20 edges (5 * 4)
  // Verify a few edges exist
  inspect(dot.contains("\"a\" -> \"b\" [label=\"0→1\"]"), content="false")
  inspect(dot.contains("\"e\" -> \"d\" [label=\"4→3\"]"), content="false")
}

///|
/// Test 12: Unicode labels
test "unicode in labels" {
  let builder = DotBuilder::new()
  builder.add_node(id="emoji", label="😀 🎉 ✨")
  builder.add_node(id="chinese", label="中文测试")
  builder.add_node(id="arabic", label="مرحبا")
  builder.add_node(id="math", label="∑ ∫ ∂ √")
  builder.add_edge(src="emoji", dst="chinese", label="→")
  builder.add_edge(src="chinese", dst="arabic", label="→")
  builder.add_edge(src="arabic", dst="math", label="→")
  let dot = builder.to_dot()
  inspect(
    dot,
    content=(
      #|digraph Marshal {
      #|  rankdir=LR;
      #|  node [shape=box, style=rounded];
      #|
      #|  emoji [label="😀 🎉 ✨"];
      #|  chinese [label="中文测试"];
      #|  arabic [label="مرحبا"];
      #|  math [label="∑ ∫ ∂ √"];
      #|
      #|  emoji -> chinese [label="→"];
      #|  chinese -> arabic [label="→"];
      #|  arabic -> math [label="→"];
      #|}
      #|
    ),
  )
}
