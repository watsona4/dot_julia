"""
    count(::Type{MangalNetwork}, d::MangalDataset, query::Pair...)

Return the number of networks that belong to a dataset, according to an optional
series of queries.
"""
function count(::Type{MangalNetwork}, d::MangalDataset, query::Pair...)
    return count(MangalNetwork, "dataset_id" => d.id, query...)
end

"""
    count(::Type{MangalInteraction}, n::MangalNetwork, query::Pair...)

Return the number of interactions that belong to a network, according to an optional
series of queries.
"""
function count(::Type{MangalInteraction}, n::MangalNetwork, query::Pair...)
    return count(MangalInteraction, "network_id" => n.id, query...)
end

"""
    count(::Type{MangalNode}, n::MangalNetwork, query::Pair...)

Return the number of nodes that belong to a network, according to an optional
series of queries.
"""
function count(::Type{MangalNode}, n::MangalNetwork, query::Pair...)
    return count(MangalNode, "network_id" => n.id, query...)
end

"""
    count(::Type{MangalNode}, n::MangalReferenceTaxon, query::Pair...)

Return the number of nodes that are instances of a reference taxon, according to an optional
series of queries.
"""
function count(::Type{MangalNode}, r::MangalReferenceTaxon, query::Pair...)
    return count(MangalNode, "taxonomy_id" => r.id, query...)
end
