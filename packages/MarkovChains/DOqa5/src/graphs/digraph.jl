
struct EdgeProp
    src::Int
    dst::Int
end

struct NodeProp
    out_edges::Vector{Int}
end

struct Digraph
    node_props::Vector{NodeProp}
    edge_props::Vector{EdgeProp}
    function Digraph()
        new(Vector{NodeProp}(), Vector{EdgeProp}())
    end
    function Digraph(num_nodes::Integer)
        new([NodeProp(Vector{Int}()) for _ in 1:num_nodes], Vector{EdgeProp}())
    end
end

export Digraph
export node_count, nodes, edge_count, edges, dst_node, src_node, get_data, out_edges, add_node!, add_edge!
node_count(dg::Digraph)::Int = convert(Int, length(dg.node_props))
nodes(dg::Digraph) = 1:node_count(dg)

edge_count(dg::Digraph)::Int = convert(Int, length(dg.edge_props))
edges(dg::Digraph) = 1:edge_count(dg)

dst_node(dg::Digraph, edge::Integer)::Int = dg.edge_props[edge].dst
src_node(dg::Digraph, edge::Integer)::Int = dg.edge_props[edge].src

out_edges(dg::Digraph, node::Integer) = dg.node_props[node].out_edges

function add_node!(dg::Digraph)
    prop = NodeProp(Vector{Int}())
    push!(dg.node_props, prop)
    return node_count(dg)
end

function add_edge!(dg::Digraph, src::Integer, dst::Integer)
    prop = EdgeProp(src, dst)
    push!(dg.edge_props, prop)
    eid = edge_count(dg)
    push!(out_edges(dg, src), eid)
    return eid
end
