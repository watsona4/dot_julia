"""
	similarity_order(wv::WordVectors, alpha=-0.65)

Post-processes the word embeddings `wv` so that the embeddings capture more
information than directly apparent through a linear transformation that
adjusts the similarity order of the model. The function returns a new
`WordVectors` object containing the processed embeddings.

# Arguments
  * `wv::WordVectors` the word embeddings
  # `alpha::AbstractFloat` the `α` parameter of the algorithm (default -0.65)

# References:
  * [Artetxe et al. \"Uncovering divergent linguistic information in
     word embeddings with lessons for intrinsic and extrinsic evaluation\",
     2018](https://arxiv.org/pdf/1809.02094.pdf)
"""
function similarity_order(wv::WordVectors{S,T,H},
                          alpha::T=T(-0.65)
                         ) where {S<:AbstractString, T<:Real, H<:Integer}
    n = length(wv.vocab)
    X = wv.vectors
    M = X*X'
    L, Q = eigen(M)
    Wₐ= Q .* (L.^alpha)
    return WordVectors{S,T,H}(wv.vocab, Wₐ*X, wv.vocab_hash)
end
