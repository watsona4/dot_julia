#####
##### Utilities
#####

export wrapping, picking

####
#### Container element type management
####

"""
$(SIGNATURES)

Test if a collection of element type `T` can contain a new element `elt` without *any* loss
of precision.
"""
@inline cancontain(T, elt::S) where {S} = S <: T || T ≡ promote_type(S, T)

@inline cancontain(::Type{Union{}}, _) = false

@inline cancontain(::Type{Union{}}, ::Integer) = false

@inline cancontain(T::Type{<:Integer}, elt::Integer) where {S <: Integer} =
    typemin(T) ≤ elt ≤ typemax(T)

@inline cancontain(T::Type{<:AbstractFloat}, elt::Integer) =
    (m = Integer(maxintfloat(T)); -m ≤ elt ≤ m)

"""
$(SIGNATURES)

Convert the argument to a narrower type if possible without losing precision.

!!! NOTE
    This function is not type stable, use only when new container types are determined.
"""
@inline narrow(x) = x

@inline narrow(x::Bool) = x

@inline function narrow(x::Integer)
    intype(T) = typemin(T) ≤ x ≤ typemax(T)
    if intype(Int8)
        Int8(x)
    elseif intype(Int16)
        Int16(x)
    elseif intype(Int32)
        Int32(x)
    elseif intype(Int64)
        Int64(x)
    else
        x
    end
end

"""
$(SIGNATURES)

Append `elt` to `v`, allocating a new vector and copying the contents.

Type of new collection is calculated using `promote_type`.
"""
function append1(v::Vector{T}, elt::S) where {T,S}
    U = promote_type(T, S)
    w = Vector{U}(undef, length(v) + 1)
    copyto!(w, v)
    w[end] = elt
    w
end

####
#### Miscellaneous
####

"""
$(SIGNATURES)

Splits a named tuple in two, based on the names in `splitter`.

Returns two `NamedTuple`s; the first one is ordered as `splitter`, the second one with the
remaining values as in the original argument.

```jldoctest
julia> split_namedtuple(NamedTuple{(:a, :c)}, (c = 1, b = 2, a = 3, d = 4))
((a = 3, c = 1), (b = 2, d = 4))
```
"""
@inline function split_namedtuple(::Type{<:NamedTuple{N}}, nt::NamedTuple) where N
    S = NamedTuple{N}
    S(nt), Base.structdiff(nt, S)
end

"""
$(SIGNATURES)

Whenever `defaults` has a given key, use the corresponding type in `rowtype`, otherwise
`Union{}`.
"""
Base.@pure function merge_default_types(rowtype::Type{<: NamedTuple{A}},
                                        defaults::Type{<: NamedTuple{B}}) where {A, B}
    M = Any[]
    for a in A
        push!(M, key_in(a, B) ? fieldtype(defaults, a) : Union{})
    end
    NamedTuple{A, Tuple{M...}}
end

"""
$(SIGNATURES)

Test if `b` starts with `a`.
"""
is_prefix(a, b) = length(a) ≤ length(b) && all(a == b for (a,b) in zip(a, b))

####
#### wrapping and picking
####

struct Wrapping{K}
    function Wrapping{K}() where K
        @argcheck K isa Symbol
        new{K}()
    end
end

(::Wrapping{K})(x) where K = NamedTuple{(K, )}((x, ))

"""
$(SIGNATURES)

Return a callable that wraps its argument in a `NamedTuple` with a given `key`.
"""
wrapping(key::Symbol) = Wrapping{key}()

struct Picking{K}
    function Picking{K}() where K
        @argcheck K isa Symbol
        new{K}()
    end
end

(::Picking{K})(x) where K = getproperty(x, K)

"""
$(SIGNATURES)
"""
picking(key::Symbol) = Picking{key}()
