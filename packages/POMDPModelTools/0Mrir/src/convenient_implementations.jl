# some implementations for convenience
# maintained by Zach Sunberg

rand(rng::AbstractRNG, t::Tuple{Bool, Bool}) = rand(rng, Bool)
rand(t::Tuple{Bool, Bool}) = rand(Bool)

support(s::AbstractVector) = s
support(s::Tuple) = s
support(r::AbstractRange) = r
support(g::Base.Generator) = g