module KeyedFrames

using DataFrames

import DataFrames: deletecols!, deleterows!, first, index, last, ncol, nonunique, nrow,
    permutecols!, rename, rename!, SubDataFrame, unique!

struct KeyedFrame <: AbstractDataFrame
    frame::DataFrame
    key::Vector{Symbol}

    function KeyedFrame(df::DataFrame, key::Vector{<:Symbol})
        key = unique(key)
        df_names = names(df)

        if !issubset(key, df_names)
            throw(
                ArgumentError(
                    string(
                        "The columns provided for the key ($key) must all be",
                        "present in the DataFrame ($df_names)."
                    )
                )
            )
        end

        return new(df, key)
    end
end

function KeyedFrame(df::DataFrame, key::Vector{<:AbstractString})
    return KeyedFrame(df, map(Symbol, key))
end

KeyedFrame(df::DataFrame, key::Symbol) = KeyedFrame(df, [key])

"""
    KeyedFrame(df::DataFrame, key::Vector{Symbol})

Create an `KeyedFrame` using the provided `DataFrame`; `key` specifies the columns
to use by default when performing a `join` on `KeyedFrame`s when `on` is not provided.

When performing a `join`, if only one of the arguments is an `KeyedFrame` and `on` is not
specified, the frames will be joined on the `key` of the `KeyedFrame`. If both
arguments are `KeyedFrame`s, `on` will default to the intersection of their respective
indices. In all cases, the result of the `join` will share a type with the first argument.

When calling `unique` (or `unique!`) on a KeyedFrame without providing a `cols` argument,
`cols` will default to the `key` of the `KeyedFrame` instead of all columns. If you wish to
remove only rows that are duplicates across all columns (rather than just across the key),
you can call `unique!(kf, names(kf))`.

When `sort`ing, if no `cols` keyword is supplied, the `key` is used to determine precedence.

When testing for equality, `key` ordering is ignored, which means that it's possible to have
two `KeyedFrame`s that are considered equal but whose default sort order will be different
by virtue of having the columns listed in a different order in their `key`s.
"""
KeyedFrame

DataFrame(kf::KeyedFrame) = frame(kf)
Base.copy(kf::KeyedFrame) = KeyedFrame(copy(DataFrame(kf)), copy(keys(kf)))
Base.deepcopy(kf::KeyedFrame) = KeyedFrame(deepcopy(DataFrame(kf)), deepcopy(keys(kf)))

Base.convert(::Type{DataFrame}, kf::KeyedFrame) = frame(kf)

SubDataFrame(kf::KeyedFrame, args...) = SubDataFrame(frame(kf), args...)

##### EQUALITY #####

Base.:(==)(a::KeyedFrame, b::KeyedFrame) = frame(a) == frame(b) && sort(keys(a)) == sort(keys(b))

Base.isequal(a::KeyedFrame, b::KeyedFrame) = isequal(frame(a), frame(b))&&isequal(keys(a), keys(b))
Base.isequal(a::KeyedFrame, b::AbstractDataFrame) = false
Base.isequal(a::AbstractDataFrame, b::KeyedFrame) = false

Base.hash(kf::KeyedFrame, h::UInt) = hash(keys(kf), hash(frame(kf), h))

##### SIZE #####

nrow(kf::KeyedFrame) = nrow(frame(kf))
ncol(kf::KeyedFrame) = ncol(frame(kf))

##### ACCESSORS #####

index(kf::KeyedFrame) = index(frame(kf))
Base.names(kf::KeyedFrame) = names(frame(kf))

##### INDEXING #####

const ColumnIndex = Union{Real, Symbol}

frame(kf::KeyedFrame) = getfield(kf, :frame)
Base.keys(kf::KeyedFrame) = getfield(kf, :key)
Base.setindex!(kf::KeyedFrame, value, ind...) = setindex!(frame(kf), value, ind...)

# I don't want to have to write the same function body several times, so...
function _kf_getindex(kf::KeyedFrame, index...)
    # If indexing by column, some keys might be removed.
    df = getindex(frame(kf), index...)
    return KeyedFrame(DataFrame(df), intersect(names(df), keys(kf)))
end

# Returns a KeyedFrame
Base.getindex(kf::KeyedFrame, ::Colon) = copy(kf)
Base.getindex(kf::KeyedFrame, ::Colon, ::Colon) = copy(kf)

# Returns a KeyedFrame
Base.getindex(kf::KeyedFrame, col::AbstractVector) = _kf_getindex(kf, col)

# Returns a column
Base.getindex(kf::KeyedFrame, col::ColumnIndex) = frame(kf)[col]

# Returns a KeyedFrame or a column (depending on the type of col)
Base.getindex(kf::KeyedFrame, ::Colon, col) = kf[col]

# Returns a scalar
Base.getindex(kf::KeyedFrame, row::Integer, col::ColumnIndex) = frame(kf)[row, col]

# Returns a KeyedFrame
Base.getindex(kf::KeyedFrame, row::Integer, col::AbstractVector) = _kf_getindex(kf, row, col)

# Returns a column
Base.getindex(kf::KeyedFrame, row::AbstractVector, col::ColumnIndex) = frame(kf)[row, col]

# Returns a KeyedFrame
function Base.getindex(kf::KeyedFrame, row::AbstractVector, col::AbstractVector)
    return _kf_getindex(kf, row, col)
end

# Returns a KeyedFrame
function Base.getindex(kf::KeyedFrame, row::AbstractVector, col::Colon)
    return _kf_getindex(kf, row, col)
end

# Returns a KeyedFrame
Base.getindex(kf::KeyedFrame, row::Integer, col::Colon) = kf[[row], col]

##### SORTING #####

function Base.sort(kf::KeyedFrame, cols=nothing; kwargs...)
    return KeyedFrame(sort(frame(kf), cols === nothing ? keys(kf) : cols; kwargs...), keys(kf))
end

function Base.sort!(kf::KeyedFrame, cols=nothing; kwargs...)
    sort!(frame(kf), cols === nothing ? keys(kf) : cols; kwargs...)
    return kf
end

function Base.issorted(kf::KeyedFrame, cols=nothing; kwargs...)
    return issorted(frame(kf), cols === nothing ? keys(kf) : cols; kwargs...)
end

##### PUSH/APPEND/DELETE #####

function Base.push!(kf::KeyedFrame, data)
    push!(frame(kf), data)
    return kf
end

function Base.append!(kf::KeyedFrame, data)
    append!(frame(kf), data)
    return kf
end

function deleterows!(kf::KeyedFrame, ind)
    deleterows!(frame(kf), ind)
    return kf
end

deletecols!(kf::KeyedFrame, ind::Union{Integer, Symbol}) = deletecols!(kf, [ind])
deletecols!(kf::KeyedFrame, ind::Vector{<:Integer}) = deletecols!(kf, names(kf)[ind])

function deletecols!(kf::KeyedFrame, ind::Vector{<:Symbol})
    deletecols!(frame(kf), ind)
    filter!(x -> !in(x, ind), keys(kf))
    return kf
end

##### RENAME #####

function rename!(kf::KeyedFrame, nms)
    rename!(frame(kf), nms)

    for (from, to) in nms
        i = findfirst(isequal(from), keys(kf))
        if i !== nothing
            keys(kf)[i] = to
        end
    end

    return kf
end

rename!(kf::KeyedFrame, nms::Pair{Symbol, Symbol}...) = rename!(kf, collect(nms))
rename!(f::Function, kf::KeyedFrame) = rename!(kf, [(nm => f(nm)) for nm in names(kf)])

rename(kf::KeyedFrame, args...) = rename!(copy(kf), args...)
rename(f::Function, kf::KeyedFrame) = rename!(f, copy(kf))

##### UNIQUE #####

_unique(kf::KeyedFrame, cols) = KeyedFrame(unique(frame(kf), cols), keys(kf))
function _unique!(kf::KeyedFrame, cols)
    unique!(frame(kf), cols)
    return kf
end

Base.unique(kf::KeyedFrame, cols::AbstractVector) = _unique(kf, cols)
Base.unique(kf::KeyedFrame, cols::Union{Integer, Symbol, Colon}) = _unique(kf, cols)
Base.unique(kf::KeyedFrame) = _unique(kf, keys(kf))
unique!(kf::KeyedFrame, cols::Union{Integer, Symbol, Colon}) = _unique!(kf, cols)
unique!(kf::KeyedFrame, cols::AbstractVector) = _unique!(kf, cols)
unique!(kf::KeyedFrame) = _unique!(kf, keys(kf))

nonunique(kf::KeyedFrame) = nonunique(frame(kf), keys(kf))

##### JOIN #####

# Returns a KeyedFrame
function Base.join(a::KeyedFrame, b::KeyedFrame; on=nothing, kind=:inner, kwargs...)
    df = join(
        frame(a),
        frame(b);
        on=on === nothing ? intersect(keys(a), keys(b)) : on,
        kind=kind,
        kwargs...,
    )

    if kind in (:semi, :anti)
        key = intersect(keys(a), names(df))
    else
        # A join can sometimes rename columns, meaning some of the key columns "disappear"
        key = intersect(union(keys(a), keys(b)), names(df))
    end

    return KeyedFrame(df, key)
end

# Returns a KeyedFrame
function Base.join(a::KeyedFrame, b::AbstractDataFrame; on=nothing, kwargs...)
    df = join(frame(a), b; on=on === nothing ? intersect(keys(a), names(b)) : on, kwargs...)

    # A join can sometimes rename columns, meaning some of the key columns "disappear"
    return KeyedFrame(df, intersect(keys(a), names(df)))
end

# Does NOT return a KeyedFrame
function Base.join(a::AbstractDataFrame, b::KeyedFrame; on=nothing, kwargs...)
    return join(a, frame(b); on=on === nothing ? intersect(keys(b), names(a)) : on, kwargs...)
end

##### FIRST/LAST #####

first(kf::KeyedFrame, r::Int) = KeyedFrame(first(frame(kf), r), keys(kf))
last(kf::KeyedFrame, r::Int) = KeyedFrame(last(frame(kf), r), keys(kf))

##### PERMUTE #####

function permutecols!(kf::KeyedFrame, index::AbstractVector)
    permutecols!(frame(kf), index)
    return kf
end

export KeyedFrame

end
