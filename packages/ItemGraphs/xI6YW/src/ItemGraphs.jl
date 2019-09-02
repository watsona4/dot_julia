module ItemGraphs

import LightGraphs:
    AbstractGraph,
    SimpleGraph,
    SimpleDiGraph,
    add_edge!,
    add_vertex!,
    nv,
    dijkstra_shortest_paths,
    enumerate_paths,
    has_vertex,
    has_path

export ItemGraph,
    SimpleGraph,
    SimpleDiGraph,
    add_edge!,
    add_vertex!,
    edgeitem,
    edgeitems,
    has_path,
    has_vertex,
    items

"""
    ItemGraph{T,S}([graph])

Create a new ItemGraph with items of type `T` based on a `graph` from `LightGraphs`.
Items of type `S` can be assigned to the edges of the graph, this type can be omitted
and will be `Float64` by default.
`graph` can be omitted as well and a `DiGraph` will be used by default.
Otherwise all paths are recomputed whenever a new edge is inserted.
"""
struct ItemGraph{T,S,G}
    graph::G
    ids::Dict{Int,T}
    items::Dict{T,Int}
    edges::Dict{T,Dict{T,S}}
    paths::Dict{T,Dict{T,Vector{T}}}
    ItemGraph{T,S}(graph::G) where {T, S, G <: AbstractGraph} = new{T,S,G}(graph,
        Dict{Int,T}(),
        Dict{T,Int}(),
        Dict{T,Dict{T,S}}(),
        Dict{T,Dict{T,Vector{T}}}(),
    )
end

ItemGraph{T}(graph=SimpleDiGraph()) where {T} = ItemGraph{T,Float64}(graph)
ItemGraph{T, S}(graph=SimpleDiGraph()) where {T, S} = ItemGraph{T,S}(graph)

getid(graph::ItemGraph{T}, item::T) where {T} = graph.items[item]
getitem(graph::ItemGraph, id) = graph.ids[id]
"""
    has_vertex(graph, item)

Return true if `item` is contained in `graph`.
"""
has_vertex(graph::ItemGraph, item) = haskey(graph.items, item)
"""
    has_path(graph, from, to)

Return true if there is a path between `from` and `to` in `graph`.
"""
has_path(graph::ItemGraph, from, to) = has_path(graph.graph, getid(graph, from), getid(graph, to))

"""
    add_vertex!(graph, item)

Add `item` to `graph`.
"""
function add_vertex!(graph::ItemGraph{T}, item::T) where T
    has_vertex(graph, item) && return

    add_vertex!(graph.graph)
    id = nv(graph.graph)
    push!(graph.ids, id => item)
    push!(graph.items, item => id)
    nothing
end

"""
    add_edge!(graph, from, to, [item])

Add an edge between `from` and `to` to `graph`. Optionally assign an item
to the edge.
"""
function add_edge!(graph::ItemGraph{T,S}, from::T, to::T,
        item::S=zero(S)) where {T, S}
    add_vertex!(graph, from)
    add_vertex!(graph, to)
    add_edge!(graph.graph, getid(graph, from), getid(graph, to))

    calculate_paths!(graph)

    edges = get!(graph.edges, from, Dict{Int,S}())
    push!(edges, to => item)
    nothing
end

"""
    edgeitem(graph, from, to)

Get the item assigned to the edge between `from` and `to`.
"""
function edgeitem(graph::ItemGraph{T}, from::T, to::T) where T
    graph.edges[from][to]
end

"""
    edgeitems(graph, from, to)

Get all items assigned to the edges between `from` and `to`.
Will return an empty array if either `from` or `to` are not a part of `graph` or if there
is no path between them.
"""
function edgeitems(graph::ItemGraph{T,S}, from::T, to::T) where {T, S}
    path = items(graph, from, to)
    isempty(path) && return S[]
    edges = Vector{S}(undef, length(path) - 1)
    for i in eachindex(edges)
        edges[i] = graph.edges[path[i]][path[i+1]]
    end
    edges
end

"""
    items(graph, from, to)

Get the items on the path between and including `from` and `to`.
Will return an empty array if either `from` or `to` are not a part of `graph` or if there
is no path between them.
"""
function items(graph::ItemGraph{T}, from, to) where T
    (has_vertex(graph, from) && has_vertex(graph, to)) || return T[]
    graph.paths[from][to]
end

function calculate_paths!(graph::ItemGraph{T}) where T
    for (origin, oid) in graph.items
        d = dijkstra_shortest_paths(graph.graph, oid)
        for (target, tid) in graph.items
            origin == target && continue
            path = getitem.(Ref(graph), enumerate_paths(d, tid))
            paths = get!(graph.paths, origin, Dict{T,Vector{T}}())
            push!(paths, target => path)
        end
    end
end

end # module
