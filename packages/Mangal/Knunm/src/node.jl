"""
    nodes(network::MangalNetwork, query::Pair...)

Returns the nodes that are part of a `MangalNetwork`, with an additional optional query.
"""
function nodes(network::MangalNetwork, query::Pair...)
    return nodes(Pair("network_id", network.id), query...)
end

"""
    nodes(taxon::MangalReferenceTaxon, query::Pair...)

Returns the nodes that are instance of a `MangalReferenceTaxon`, with an additional query.
"""
function nodes(taxon::MangalReferenceTaxon, query::Pair...)
    return nodes(Pair("taxonomy_id", taxon.id), query...)
end
