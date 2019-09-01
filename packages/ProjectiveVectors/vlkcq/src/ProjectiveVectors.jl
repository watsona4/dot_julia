module ProjectiveVectors

using LinearAlgebra
using StaticArrays
import Base: ==

export PVector, data, dims, embed, dimension_indices, dimension_indices_homvars, homvars,
    affine_chart, affine_chart!, norm_affine_chart, fubini_study


"""
    AbstractProjectiveVector{T, N} <: AbstractVector{T}

An abstract type representing a vector in a product of `N` projective spaces ``P(T^{dᵢ})``.
"""
abstract type AbstractProjectiveVector{T, N} <: AbstractVector{T} end


"""
    PVector{T, N} <: AbstractProjectiveVector{T, N}

A `PVector` represents a projective vector `z` which lives in a product of `N`
projective spaces ``P(T)^{dᵢ}``. The underlying data structure is a `Vector{T}`.
"""
struct PVector{T, N} <: AbstractProjectiveVector{T, N}
    data::Vector{T}
    dims::NTuple{N, Int} # Projective dimensions

    function PVector{T, N}(data, dims) where {T, N}
        @assert length(data) == sum(dims) + N
        new(data, dims)
    end

    Base.copy(v::PVector{T, N}) where {T, N} = new{T, N}(copy(v.data), v.dims)
end

PVector(z::AbstractVector{T}, dims::NTuple{N, Int}) where {T, N} = PVector{T, N}(z, dims)
PVector(vectors::AbstractVector...) = PVector(promote(vectors...))
function PVector(vectors::NTuple{N, <:AbstractVector{T}}) where {T, N}
    data = reduce(vcat, vectors)
    dims = _dim.(vectors)
    PVector(data, dims)
end
_dim(x::AbstractVector) = length(x) - 1



"""
    data(z::AbstractProjectiveVector)

Access the underlying vector of `z`. This is useful to pass
the vector into some function which does not know the
projective structure.

    data(z::AbstractVector)

For general `AbstractVector`s this is just the identity.
"""
data(z::PVector) = z.data
data(z::AbstractVector) = z


"""
    dims(z::PVector)

Dimensions of the projective spaces in which `z` lives.
"""
dims(z::PVector) = z.dims

"""
    dimension_indices(z::PVector{T, N})
    dimension_indices(dims::NTuple{N, Int})

Return a tuple of `N` `UnitRange`s indexing the underlying data.

## Example
```julia-repl
julia> v = PVector([4, 5, 6], [2, 3], [1, 2])
PVector{Int64, 3}:
 [4, 5, 6] × [2, 3] × [1, 2]

julia> dimension_indices(v)
(1:3, 4:5, 6:7)
```
"""
dimension_indices(z::PVector) = dimension_indices(dims(z))
dimension_indices(dims::NTuple{1, Int}) = (1:(dims[1] + 1),)
function dimension_indices(dims::NTuple{N, Int}) where {N}
    k = Ref(1)
    @inbounds map(dims) do dᵢ
        curr_k = k[]
        r = (curr_k:(curr_k + dᵢ))
        k[] += dᵢ + 1
        r
    end
end

"""
    dimension_indices_homvars(z::PVector{T, N})
    dimension_indices_homvars(dims::NTuple{N, Int})

Return a tuple of `N` `(UnitRange, Int)` tuples indexing the underlying data per vector
where the last coordinate in each vector is treated separetely.

## Example
```julia-repl
julia> v = PVector([4, 5, 6], [2, 3], [1, 2])
PVector{Int64, 3}:
 [4, 5, 6] × [2, 3] × [1, 2]

 julia> dimension_indices_homvars(v)
 ((1:2, 3), (4:4, 5), (6:6, 7))
```
"""
dimension_indices_homvars(z::PVector) = dimension_indices_homvars(dims(z))
function dimension_indices_homvars(dims::NTuple{N, Int}) where {N}
    k = Ref(1) # we need the ref here to make the compiler happy
    @inbounds map(dims) do dᵢ
        curr_k = k[]
        upper = curr_k + dᵢ
        r = (curr_k:(upper - 1))
        k[] += dᵢ + 1
        (r, upper)
    end
end

"""
    homvars(z::PVector{T,N})

Return the indices of the homogenization variables.

## Example
```julia-repl
julia> v = PVector([4, 5, 6], [2, 3], [1, 2])
PVector{Int64, 3}:
 [4, 5, 6] × [2, 3] × [1, 2]

 julia> homvars(v)
 (3, 5, 7)
```
"""
function homvars(z::PVector{T, N}) where {T, N}
    k = Ref(1) # we need the ref here to make the compiler happy
    @inbounds map(z.dims) do dᵢ
        curr_k = k[]
        k[] += dᵢ + 1
        curr_k + dᵢ
    end
end

##################
# Base overloads
#################

# AbstractArray interface

Base.@propagate_inbounds Base.getindex(z::PVector, k) = getindex(z.data, k)
Base.@propagate_inbounds Base.setindex!(z::PVector, v, i) = setindex!(z.data, v, i)
Base.firstindex(z::PVector) = 1
Base.lastindex(z::PVector) = length(z)

Base.length(z::PVector) = length(z.data)
Base.size(z::PVector) = (length(z),)

Base.@propagate_inbounds function Base.getindex(z::PVector, i::Integer, j::Integer)
    d = dims(z)
    @boundscheck checkbounds(z, i, j)
    k = 0
    for l = 1:i-1
        k += d[l] + 1
    end
    z[k + j]
end
function Base.checkbounds(z::PVector{T, N}, i, j) where {T, N}
    if i < 1 || i > N
        error("Attempt to access product of $N projective spaces at index $i")
    end
    dᵢ = dims(z)[i]
    if j < 1 || j > dᵢ + 1
        error("Attempt to access $(dᵢ)-dimensional projective space at index $i")
    end
    true
end

# conversion
Base.similar(v::PVector, ::Type{T}) where T = PVector(similar(v.data, T), v.dims)
function Base.convert(::Type{PVector{T, N}}, z::PVector{T1, N}) where {T, N, T1}
    PVector(convert(Vector{T}, z.data), z.dims)
end

# equality
(==)(v::PVector, w::PVector) = dims(v) == dims(w) && v.data == w.data


# show
Base.show(io::IO, ::MIME"text/plain", z::PVector) = show(io, z)
function Base.show(io::IO, z::PVector{T, N}) where {T, N}
    if !(get(io, :compact, false))
        print(io, "PVector{$T, $N}:\n ")
    end
    for (i, dᵢ) in enumerate(dims(z))
        if i > 1
            print(io, " × ")
        end
        print(io, "[")
        for j=1:(dᵢ + 1)
            print(io, z[i, j])
            if j ≤ dᵢ
                print(io, ", ")
            end
        end
        print(io, "]")
    end
end
Base.show(io::IO, ::MIME"application/juno+inline", z::PVector) = show(io, z)



"""
    embed(xs::AbstractVector...; normalize=false)
    embed(x::AbstractVector{T}, dims::NTuple{N, Int}; normalize=false)::PVector{T, N}

Embed an affine vector `x` in a product of affine spaces by the map πᵢ: xᵢ -> [xᵢ; 1]
for each subset `xᵢ` of `x` according to `dims`. If `normalize` is true the vector is
normalized.

## Examples
```julia-repl
julia> embed([2, 3])
PVector{Int64, 1}:
 [2, 3, 1]

julia> embed([2, 3], [4, 5, 6])
PVector{Int64, 2}:
 [2, 3, 1] × [4, 5, 6, 1]

julia> embed([2.0, 3, 4, 5, 6, 7], (2, 3, 1))
PVector{Float64, 3}:
 [2.0, 3.0, 1.0] × [4.0, 5.0, 6.0, 1.0] × [7.0, 1.0]

 julia> embed([2.0, 3, 4, 5, 6, 7], (2, 3, 1), normalize=true)
 PVector{Float64, 3}:
  [0.5345224838248488, 0.8017837257372732, 0.2672612419124244] × [0.45291081365783825, 0.5661385170722978, 0.6793662204867574, 0.11322770341445956] × [0.9899494936611666, 0.1414213562373095]
```
"""
function embed(z::AbstractVector{T}, dims::NTuple{N, Int}; normalize=false) where {T, N}
    n = sum(dims)
    data = Vector{T}(undef, n+N)
    v = PVector(data, dims)
    embed!(v, z; normalize=normalize)
end
function embed!(v::PVector, z::AbstractVector; normalize=false)
    dims = v.dims
    n = sum(dims)
    if length(z) == n + length(dims) # assume z has the same layout as v
        v.data .= z
        return v
    end
    if length(z) ≠ n
        error("Cannot embed `x` since passed dimensions `dims` are invalid for the given vector `x`.")
    end
    data = v.data
    k = 1
    j = 1
    for dᵢ in dims
        for _ = 1:dᵢ
            data[k] = z[j]
            k += 1
            j += 1
        end
        data[k] = one(eltype(data))
        k += 1
    end

    if normalize == true
        normalize!(v)
    end
    v
end

function embed!(v::PVector, z::PVector)
    v.dims == z.dims || error("Dimensions do not match.")
    copyto!(v.data, z.data)
    v
end

function embed(vectors::NTuple{N, <:AbstractVector{T}}; kwargs...) where {T, N}
    data = reduce(vcat, vectors)
    dims = length.(vectors)
    embed(data, dims; kwargs...)
end
embed(vectors::AbstractVector...; kwargs...) = embed(promote(vectors...); kwargs...)


"""
    norm(z::PVector{T,N}, p::Real=2)::NTuple{N, real(T)}

Compute the `p`-norm of `z` per vector space. This always returns a `Tuple`.

## Example
```julia-repl
julia> norm(embed([1, 2, 3, 4, 5], (2, 3)))
(2.449489742783178, 7.14142842854285)

julia> norm(embed([1, 2, 3, 4, 5]))
(7.483314773547883,)
```
"""
LinearAlgebra.norm(z::PVector{T, 1}, p::Real=2) where {T} = (LinearAlgebra.norm(z.data, p),)
@generated function LinearAlgebra.norm(z::PVector{T, N}, p::Real=2) where {T, N}
    quote
        r = dimension_indices(z)
        @inbounds $(Expr(:tuple, (:(_norm_range(z, r[$i], p)) for i=1:N)...))
    end
end


"""
    _norm_range(z::PVector{T, N}, rᵢ::UnitRange, p)

Compute the `p`-norm of `z` for the indices in `rᵢ`.
"""
@inline function _norm_range(z::PVector{T}, rᵢ::UnitRange{Int}, p::Real) where {T}
    normᵢ = zero(T)
    if p == 2
        @inbounds for k in rᵢ
            normᵢ += abs2(z[k])
        end
        normᵢ = sqrt(normᵢ)
    elseif p == Inf
        @inbounds for k in rᵢ
            normᵢ = @fastmath max(normᵢ, abs(z[k]))
        end
    else
        error("p=$p not supported.")
    end
    normᵢ
end
@inline function _norm_range(z::PVector{<:Complex}, rᵢ::UnitRange{Int}, p::Real) where {T}
    sqrt(_norm_range2(z, rᵢ, p))
end
@inline function _norm_range2(z::PVector{T}, rᵢ::UnitRange{Int}, p::Real) where T
    normᵢ = zero(real(T))
    if p == 2
        @inbounds for k in rᵢ
            normᵢ += abs2(z[k])
        end
    elseif p == Inf
        @inbounds for k in rᵢ
            normᵢ = @fastmath max(normᵢ, abs2(z[k])) # We do not care about NAN propagation
        end
    else
        error("p=$p not supported.")
    end
    normᵢ
end


"""
    LinearAlgebra.rmul!(z::PVector{T, N}, λ::NTuple{N, <:Number}) where {T, N}
    LinearAlgebra.rmul!(z::PVector{T, 1}, λ::Number) where {T}

Multiply each component of `zᵢ` of `z` by `λ[i]`.
"""
function LinearAlgebra.rmul!(z::PVector{T, 1}, λ::Number) where {T}
    rmul!(z.data, λ)
    z
end
function LinearAlgebra.rmul!(z::PVector{T, N}, λ::NTuple{N, <:Number}) where {T, N}
    r = dimension_indices(z)
    @inbounds for i = 1:N
        rᵢ, λᵢ = r[i], λ[i]
        for k in rᵢ
            z[k] *= λᵢ
        end
    end
    z
end

"""
    LinearAlgebra.normalize!(z::PVector, p::Real=2)

Normalize each component of `z` separetly.
"""
function LinearAlgebra.normalize!(z::PVector{T, 1}, p::Real=2) where {T}
    normalize!(z.data, p)
    z
end
LinearAlgebra.normalize!(z::PVector, p::Real=2) = rmul!(z, inv.(LinearAlgebra.norm(z, p)))

"""
    LinearAlgebra.normalize(z::PVector{T, N}, p::Real=2)::PVector{T,N}

Normalize each component of `z` separetly.
"""
LinearAlgebra.normalize(z::PVector, p::Real=2) = normalize!(copy(z), p)

"""
    affine_chart(z::PVector)

Return the affine chart corresponding to the projective vector. This can be seen as the
inverse of [`embed`](@ref).

## Example
```julia-repl
julia> v = embed([2.0, 3, 4, 5, 6, 7], (2, 3, 1))
PVector{Float64, 3}:
 [2.0, 3.0, 1.0] × [4.0, 5.0, 6.0, 1.0] × [7.0, 1.0]

julia> affine_chart(v)
6-element Array{Float64,1}:
 2.0
 3.0
 4.0
 5.0
 6.0
 7.0
```
"""
function affine_chart(z::PVector{T}) where {T}
    @inbounds affine_chart!(Vector{T}(undef, sum(dims(z))), z)
end


"""
    affine_chart!(x, z::PVector)

Inplace variant of [`affine_chart`](@ref).
"""
function affine_chart!(x::AbstractVector, z::PVector{T,N}) where {T,N}
    if N == 1 # don't split into sepearat method to avoid method ambiguity with SVector below
        @boundscheck length(x) >= length(z) - 1
        n = length(z)
        v = inv(z[n])
        for i=1:n-1
            x[i] = z[i] * v
        end
    else
        k = 1
        for (rᵢ, hᵢ) in dimension_indices_homvars(z)
            @inbounds normalizer = inv(z[hᵢ])
            for i in rᵢ
                x[k] = z[i] * normalizer
                k += 1
            end
        end
    end
    x
end

function affine_chart!(::SVector{M, S}, z::PVector{T, N}) where {M,S,T,N}
    x = @MVector zeros(S, M)
    k = 1
    for (rᵢ, hᵢ) in dimension_indices_homvars(z)
        @inbounds normalizer = inv(z[hᵢ])
        for i in rᵢ
            x[k] = z[i] * normalizer
            k += 1
        end
    end
    SVector{M}(x)
end


function affine_chart!(z::PVector{T}) where T
    k = 1
    for (rᵢ, hᵢ) in dimension_indices_homvars(z)
        normalizer = @fastmath inv(z[hᵢ])
        for i in rᵢ
            z[k] = z[i] * normalizer
            k += 1
        end
        z[hᵢ] = one(T)
        k += 1
    end
    z
end





"""
     norm_affine_chart(z::PVector, p::Real=2) where {T, N}

Compute the `p`-norm of `z` on it's affine_chart.
"""
function norm_affine_chart(z::PVector{T, N}, p::Real=2) where {T, N}
    # We need to compute for each subrange
    #     ||z[hᵢ]⁻¹z[rᵢ]|| = |z[hᵢ]⁻¹|||z[rᵢ]|| = |z[hᵢ]|⁻¹||z[rᵢ]||
    r = dimension_indices_homvars(z)
    norm = zero(real(T))
    if p == 2
        @inbounds for (rᵢ, hᵢ) in r
            norm += _norm_range2(z, rᵢ, p) / abs2(z[hᵢ])
        end
        return sqrt(norm)
    elseif p == Inf
        if T <: Complex
            @inbounds for (rᵢ, hᵢ) in r
                norm = @fastmath max(norm, _norm_range2(z, rᵢ, p) / abs2(z[hᵢ]))
            end
            return sqrt(norm)
        else
            @inbounds for (rᵢ, hᵢ) in r
                norm = @fastmath max(norm, _norm_range(z, rᵢ, p) / abs(z[hᵢ]))
            end
            return norm
        end
    else
        error("$p-norm not supported")
    end
    norm
end


"""
    LinearAlgebra.dot(v::PVector{T, N}, w::PVector{T2, N}) where {T, T2, N}

Compute the component wise dot product. If decorated with `@inbounds` the check of the
[`dims`](@ref) of `v` and `w` is skipped.
"""
@generated function LinearAlgebra.dot(v::PVector{T, N}, w::PVector{T2, N}) where {T, T2, N}
    quote
        @boundscheck checkbounds(v, w)
        r = dimension_indices(v)
        @inbounds $(Expr(:tuple, (:(_dot_range(v, w, r[$i])) for i=1:N)...))
    end
end
@inline function Base.checkbounds(v::PVector{T, N}, w::PVector{T2, N}) where {T, T2, N}
    if dims(v) ≠ dims(w)
        error("Dimensions of the vector spaces of the `PVector`s don't agree.")
    end
    true
end

function LinearAlgebra.dot(v::PVector{<:Number, 1}, w::PVector{<:Number, 1})
    (dot(v.data, w.data),)
end

"""
    _dot_range(v::PVector{T1, N}, w::PVector{T2, N}, rᵢ::UnitRange)

Compute the dot product of v and w for the indices in rᵢ.
"""
@inline function _dot_range(v::PVector{T1, N}, w::PVector{T2, N}, rᵢ) where {T1, T2, N}
    dotᵢ = zero(promote_type(T1, T2))
    @inbounds for k in rᵢ
        dotᵢ += conj(v[k]) * w[k]
    end
    dotᵢ
end

"""
    fubini_study(v::PVector{<:Number,N}, w::PVector{<:Number, N})

Compute the Fubini-Study distance between `v` and `w` for each component `vᵢ` and `wᵢ`.
This is defined as ``\\arccos|⟨vᵢ,wᵢ⟩|``.
"""
@generated function fubini_study(v::PVector{<:Number,N}, w::PVector{<:Number, N}) where N
    quote
        Base.@_propagate_inbounds_meta
        r = dimension_indices(v)
        $(Expr(:tuple, (quote
            @inbounds rᵢ = r[$i]
            acos(abs2(_dot_range(v, w, rᵢ)) / (_norm_range2(v, rᵢ, 2) * _norm_range2(w, rᵢ, 2)))
        end for i=1:N)...))
    end
end

end
