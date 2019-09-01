"""
    pca_reduction(wv::WordVectors, rdim=7, outdim=size(wv.vectors,1); [do_pca=true])

Post-processes word embeddings `wv` by removing the first `rdim` PCA components
from the word vectors and also reduces the dimensionality to `outdim` through
a subsequent PCA transform, if `do_pca=true`.

# Arguments
  * `wv::WordVectors` the word embeddings
  * `rdim::Int` the number of PCA components to remove from the data
     (default 7)
  * `outdim::Int` the output dimensionality of the data after the PCA
     dimensionality reduction; it is performed only if `do_pca=true`
     and the default value is the same as that of the input embeddings
     i.e. no reduction

# Keyword arguments
  * `do_pca::Bool` whether to perform a PCA transform of the
     post-processed data (default `true`)

# References:
  * [Vikas Raunak "Simple and effective dimensionality reduction for
     word embeddings", NIPS 2017 Workshop](https://arxiv.org/abs/1708.03629)
"""
function pca_reduction(wv::WordVectors{S,T,H},
                       rdim::Int=7,
                       outdim::Int=size(wv.vectors,1);
                       do_pca::Bool=true
                      ) where {S<:AbstractString, T<:Real, H<:Integer}

    # Perform first post-processing
    X = _pca_postprocessing(wv.vectors, rdim)

    # Do PCA and post-process again
    if do_pca
        outdim = clamp(outdim, 1, size(X,1))
        pratio = ifelse(size(wv.vectors,1)==outdim, 1.0, 0.99)
        M = fit(PCA, X, maxoutdim=outdim, pratio=pratio)
        X = transform(M, X)
        X = _pca_postprocessing(X, rdim)
    end

    return WordVectors{S,T,H}(wv.vocab, X, wv.vocab_hash)
end


function _pca_postprocessing(X::AbstractMatrix{T}, rdim::Int=7) where {T<:AbstractFloat}
    # Subtract the mean
    @debug "Subtracting the mean..."
    X .-= mean(X, dims=2)

    # Compute the first d PCA components
    @debug "Computing PCA components..."
    m, n = size(X)
    rdim = clamp(rdim, 1, m)
    M = fit(PCA, X, pratio=1.0, mean=0)
    M = __handle_pca_dimensions(M, m)
    Xd = transform(M, X)
    Xdv = [Xd[:,i]*Xd[:,i]' for i in 1:rdim]

    # Eliminate top d components
    @debug "Eliminating the top $rdim components..."
    Xout = similar(X)
    @inbounds @simd for i in 1:n
        Xout[:,i] = X[:,i] .- mapreduce(x->x*X[:,i], +, Xdv)
    end
    return Xout
end


# Introduces 0 components into PCA transform to force the number
# of components be equal to the number of dimensions explicitly
# specified
function __handle_pca_dimensions(M::PCA{T}, m) where {T}
    pcadim = length(M.prinvars)
    if pcadim < m
        proj = zeros(T, m, m)
        proj[:, 1:pcadim] .+= M.proj
        prinvars = zeros(T, m)
        prinvars[1:pcadim] .+= M.prinvars
        M = PCA(M.mean, proj, prinvars, M.tprinvar, M.tvar)
    end
    return M
end
