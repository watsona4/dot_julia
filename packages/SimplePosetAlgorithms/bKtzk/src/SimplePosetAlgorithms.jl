module SimplePosetAlgorithms

using SimpleGraphs
using SimplePosets
using SimpleGraphAlgorithms

export max_chain, max_antichain, width

"""
`max_chain(P)` returns a largest set of pairwise *comparable* elements
in the `SimplePoset`.
"""
function max_chain(P::SimplePoset)
    return max_clique(ComparabilityGraph(P))
end

"""
`max_antichain(P)` returns a largest set of pairwise *incomparable*
elements in the `SimplePoset`.
"""
function max_antichain(P::SimplePoset)
    return max_indep_set(ComparabilityGraph(P))
end

"""
`width(P)` gives the size of a largest antichain in the poset `P`.
"""
width(P::SimplePoset) = length(max_antichain(P))

include("realizer.jl")

end # of module SimplePosetAlgorithms
