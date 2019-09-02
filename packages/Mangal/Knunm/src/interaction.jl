"""
    interactions(from::MangalNode, ::Colon, query::Pair...)

Returns interactions established *by* the species given as its first argument.
"""
function interactions(from::MangalNode, ::Colon, query::Pair...)
    return interactions(Pair("node_from", string(from.id)), query...)
end

"""
    interactions(::Colon, to::MangalNode, query::Pair...)

Returns interactions established *to* the species given as its second argument.
"""
function interactions(::Colon, to::MangalNode, query::Pair...)
    return interactions(Pair("node_to", string(to.id)), query...)
end

"""
    interactions(with::MangalNode, query::Pair...)

Returns interactions established *around* the species given as its first argument.
"""
function interactions(with::MangalNode, query::Pair...)
    to = interactions(with, :, query...)
    fr = interactions(:, with, query...)
    append!(to, fr)
    return unique(to)
end

"""
    interactions(from::MangalNode, to::MangalNode, query::Pair...)

Returns interactions between two nodes.
"""
function interactions(from::MangalNode, to::MangalNode, query::Pair...)
    return interactions(Pair("node_from", string(from.id)), Pair("node_to", string(to.id)), query...)
end

"""
    interactions(n::MangalNetwork, query::Pair...)

Returns interactions within a network.
"""
function interactions(n::MangalNetwork, query::Pair...)
    return interactions("network_id" => n.id, query...)
end
