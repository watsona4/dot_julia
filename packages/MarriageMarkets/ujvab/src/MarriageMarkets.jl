"""
A package for solving various marriage market matching models.

Two models are supported:

- `StaticMatch`: the static frictionless matching model of Choo & Siow (2006)
- `SearchMatch`: the search and matching model of Shimer & Smith (2000)

`SearchMatch` is generalized in a few ways beyond the model presented in the paper.
This includes a match-specific "love" shock to make the matching probabilistic.
"""
module MarriageMarkets

export StaticMatch, estimate_static_surplus, SearchMatch, SearchClosed, SearchInflow

include("static-match.jl")
include("search-match.jl")

end # module
