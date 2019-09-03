module RestrictProlong

using Base: tail

export restrict, restrict!, prolong

const DimsLike = Union{Dims,AbstractVector{Int}}

### restrict, for reducing the image size by 2-fold

"""
    Ar = restrict(A[, dims])

Perform two-fold reduction in size along the dimensions listed in
`dims`, or all coordinates if `dims` is omitted.  It anti-aliases A,
so is more accurate than a naive summation over
2×2×... blocks. `restrict` is normalized so as to approximately
preserve the mean value of `A`.

Thought of as an operator, `restrict` is equal to the transpose of `prolong`.
"""
restrict(A::AbstractArray, dims::DimsLike=1:ndims(A)) =  _restrict(A, dims...)

restrict(A::AbstractArray, dim::Integer) = _restrict(A, dim)

@inline _restrict(A, d1, d2, d...) = _restrict(_restrict(A, d1), d2, d...)
_restrict(A) = A

"""
    Ap = prolong(A, [sz::Tuple])

Perform two-fold expansion in size. If `sz` is omitted, all
dimensions are expanded. If `sz` is specified, it can be one of the
following:

- `sz[d] = size(A, d)`: no expansion is performed
- `sz[d] = 2*size(A, d) - 1`: expansion to an odd-size, adding (by interpolation) points on the half-grid between all points along dimension `d`
- `sz[d] = 2*size(A, d)`: expansion to an even-size, estimating the points on the 1/4 and 3/4 grid (including one point beyond either edge of the current span)

Any other choice results in an error. The default choice is to perform
odd-expansion. `prolong` is normalized so as to approximately preserve
the sum of `A`.

Thought of as an operator, `prolong` is equal to the transpose of `restrict`.
"""
prolong(A::AbstractArray) = prolong(A, map(n->2*n-1, _size(A)))

prolong(A::AbstractVector, sz::Integer) = prolong(A, sz, 1)

prolong(A::AbstractArray{T, N}, sz::Dims{N}) where {T, N} = _prolong(A, sz, ntuple(identity, Val(N)))

@inline _prolong(A, sz, dims) = _prolong(prolong(A, sz[1], dims[1]), tail(sz), tail(dims))
_prolong(A, ::Tuple{}, ::Tuple{}) = A

### Inner routines

function _restrict(A::AbstractArray{T, N}, dim::Integer) where {T, N}
    indsA = axes(A)
    sz = dim <= N ? length(indsA[dim]) : 1
    if sz <= 2
        return copy(A)
    end
    newinds = ntuple(i -> i==dim ? oftype(indsA[i], Base.OneTo(restrict_size(sz))) : indsA[i], Val(N))
    A1 = first(A)
    out = similar(A, typeof(A1/4+A1/2), newinds)
    restrict!(out, A, dim)
    out
end

# This properly anti-aliases. The only "oddity" is that edges tend
# towards zero under repeated restriction.

function restrict!(out, A, dim)
    checkdims(out, A, dim)
    indsA = axes(A)
    Rpre = CartesianIndices(indsA[1:dim-1])
    Rpost = CartesianIndices(indsA[dim+1:end])
    _restrict!(out, axes(out, dim), A, Rpre, indsA[dim], Rpost)
end

# Normalized so that out has roughly the same mean as A
@noinline function _restrict!(out::AbstractArray{T}, indout, A, Rpre::CartesianIndices, indA, Rpost::CartesianIndices) where T
    l = length(indA)
    fill!(out, zero(T))
    if isodd(l)
        half = convert(eltype(T), 0.5)
        quarter = convert(eltype(T), 0.25)
        rngA = first(indA):2:last(indA)-1
        rngout = first(indout):last(indout)-1
        for Ipost in Rpost
            for (i,j) in zip(rngA, rngout)
                @inbounds for Ipre in Rpre
                    tmp = quarter*A[Ipre, i+1, Ipost]
                    out[Ipre, j, Ipost]   += half*A[Ipre, i, Ipost] + tmp
                    out[Ipre, j+1, Ipost] += tmp
                end
            end
            @inbounds for Ipre in Rpre
                out[Ipre, last(indout), Ipost] += half*A[Ipre, last(indA), Ipost]
            end
        end
    else
        threeeighths = convert(eltype(T), 0.375)
        oneeighth = convert(eltype(T), 0.125)
        half = convert(eltype(T), 0.5)
        rngA = first(indA)+1:2:last(indA)-1
        rngout = first(indout):last(indout)-1
        for Ipost in Rpost
            @inbounds for Ipre in Rpre
                out[Ipre, first(indout), Ipost] = half*A[Ipre, first(indA), Ipost]
            end
            @inbounds for (i,j) in zip(rngA, rngout)
                for Ipre in Rpre
                    tmpA1, tmpA2 = A[Ipre, i, Ipost], A[Ipre, i+1, Ipost]
                    out[Ipre, j, Ipost]   += threeeighths*tmpA1 + oneeighth*tmpA2
                    out[Ipre, j+1, Ipost] += oneeighth*tmpA1 + threeeighths*tmpA2
                end
            end
            @inbounds for Ipre in Rpre
                out[Ipre, last(indout), Ipost] += half*A[Ipre, last(indA), Ipost]
            end
        end
    end
    out
end

"""
    prolong(A, sz::Integer, dim::Integer)

Perform expansion to size `sz` along dimension `dim`. `sz` must be one
of the valid choices for prolongation size.
"""
function prolong(A::AbstractArray{T, N}, sz::Integer, dim::Integer) where {T, N}
    if dim > N
        sz == 1 || throw(DimensionMismatch("cannot prolong $N-dimensional array to size $sz along dimension $dim (size must be 1)"))
        return copy(A)
    end
    indsA = axes(A)
    l = dim <= ndims(A) ? length(indsA[dim]) : 1
    (sz == l) | (sz == 2*l-1) | (sz == 2*l) || throw(DimensionMismatch("along dimension $dim, sz must be one of $l, $(2*l-1), or $(2*l), got $sz"))
    newinds = ntuple(i -> i==dim ? oftype(indsA[i], Base.OneTo(sz)) : indsA[i], Val(N))
    A1 = first(A)
    out = similar(A, typeof(A1/2+A1/2), newinds)
    Rpre = CartesianIndices(indsA[1:dim-1])
    Rpost = CartesianIndices(indsA[dim+1:end])
    _prolong!(out, newinds[dim], A, Rpre, indsA[dim], Rpost)
end

@noinline function _prolong!(out::AbstractArray{T}, indout, A, Rpre::CartesianIndices, indA, Rpost::CartesianIndices) where T
    l = length(indout)
    fill!(out, zero(T))
    if isodd(l)
        half = convert(eltype(T), 0.5)
        quarter = convert(eltype(T), 0.25)
        rngout = first(indout):2:last(indout)-1
        for Ipost in Rpost
            i = first(indA)
            for j in rngout
                @inbounds for Ipre in Rpre
                    tmpA1, tmpA2 = A[Ipre, i, Ipost], A[Ipre, i+1, Ipost]
                    out[Ipre, j, Ipost]   = half*tmpA1
                    out[Ipre, j+1, Ipost] = quarter*tmpA1+quarter*tmpA2
                end
                i += 1
            end
            @inbounds for Ipre in Rpre
                out[Ipre, last(indout), Ipost] = half*A[Ipre, last(indA), Ipost]
            end
        end
    else
        threeeighths = convert(eltype(T), 0.375)
        oneeighth = convert(eltype(T), 0.125)
        half = convert(eltype(T), 0.5)
        rngout = first(indout)+1:2:last(indout)-1
        rngA = first(indA):last(indA)-1
        for Ipost in Rpost
            @inbounds for Ipre in Rpre
                out[Ipre, first(indout), Ipost] = half*A[Ipre, first(indA), Ipost]
            end
            @inbounds for (i,j) in zip(rngA, rngout)
                for Ipre in Rpre
                    tmpA1, tmpA2 = A[Ipre, i, Ipost], A[Ipre, i+1, Ipost]
                    out[Ipre, j, Ipost]   = threeeighths*tmpA1 + oneeighth*tmpA2
                    out[Ipre, j+1, Ipost] = oneeighth*tmpA1 + threeeighths*tmpA2
                end
            end
            @inbounds for Ipre in Rpre
                out[Ipre, last(indout), Ipost] = half*A[Ipre, last(indA), Ipost]
            end
        end
    end
    out
end

restrict_size(len::Integer) = (len+1)>>1

function checkdims(out, A, dim)
    1 <= dim <= ndims(A) || throw(DimensionMismatch("dim must be between 1 and $(ndims(A)), got $dim"))
    ndims(out) == ndims(A) || throw(DimensionMismatch("A and out must have the same dimensions, got $(ndims(A)) and $(ndims(out))"))
    indsA = axes(A)
    indsout = axes(out)
    for i = 1:ndims(A)
        if i != dim
            indsout[i] == indsA[i] || throw(DimensionMismatch("A and out must have the same axces for all non-reduced dimensions, got $(indsA[i]) and $(indsout[i]) for dimension $i"))
        end
    end
    indAr = indsA[dim]
    indout = indsout[dim]
    length(indout) == restrict_size(length(indAr)) || throw(DimensionMismatch("A and out disagree along the restricted dimension, have axes $indAr and $indout but latter must be of length $(length(indout))"))
    nothing
end

_size(A::AbstractArray) = map(length, axes(A))

end # module
