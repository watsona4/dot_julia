"""
  rep(ind::Tuple)

axiliary for cnorm count how many times a block should be counted
```jldoctest
julia> rep((1,2,3))
6

julia> rep((1,2,2))
3

julia> rep((1,1,1))
1
```
"""
function rep(ind::Tuple)
  @inbounds c = counts([ind...])
  div(factorial(length(ind)), mapreduce(factorial, * , c))
end

"""
norm(bt::SymmetricTensor{T, m}, p::Union{Float64, Int}=2) where {T<:AbstractFloat, m}

Returns Float, a p-norm of bt, supported for p ≠ 0

```jldoctest

julia> te = [-0.112639 0.124715 0.124715 0.268717 0.124715 0.268717 0.268717 0.046154];

julia> st = convert(SymmetricTensor, (reshape(te, (2,2,2))));

julia> norm(st)
0.5273572868359742

julia> norm(st, 2.5)
0.4468668679541424

julia> norm(st, 1)
1.339089
```
"""
function norm(bt::SymmetricTensor{T, m}, p::Union{Float64, Int}=2) where {T<:AbstractFloat, m}
  p != 0 || throw(AssertionError("0-norm not supported"))
  ret = 0.
  for i in pyramidindices(m, bt.bln)
    @inbounds ret += rep(i) * norm(getblockunsafe(bt, i), p)^p
  end
  ret^(1/p)
end

"""
  cnorms(c::Vector{SymmetricTensor{T}})

Returns vector of Floats of norms of cumulants of order 3, ..., k , ..., m, normalsed
by √||C₂||ᵏ
.....

"""
function cnorms(c::Vector{SymmetricTensor{T}}) where T <: AbstractFloat
  n = norm(c[2])
  [norm(c[k])/(n)^(k/2) for k in 3:length(c)]
end
