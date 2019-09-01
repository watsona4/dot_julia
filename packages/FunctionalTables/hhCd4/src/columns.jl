export SinkConfig, SINKVECTORS


# sinks — general interface

# A *sink* is a container that collects elements, expanding as necessary. When the
# collection is finished, sinks are *finalized* into *columns*. Details are governed by sink
# configuration objects (see [`SinkConfig`](@ref).
#
# Interface for sinks
#
# 1. [`make_sink`](@ref) for creating a sink for a single element.
#
# 2. [`store_or_reallocate!`](@ref) for saving another element. Either the result is `≡` to
# the sink in the argument, or a new sink was reallocated (potentially changing type).
#
# 3. [`finalize_sink`](@ref) turns the sink into a *column*, which is an iterable with a
# length and element type, supports `iterate,` but is not necessarily optimized for random
# access.

"""
$(TYPEDEF)
"""
struct SinkConfig{useRLE, M}
    missingvalue::M
    function SinkConfig{useRLE}(missingvalue::M) where {useRLE, M}
        @argcheck useRLE isa Bool
        @argcheck issingletontype(M)
        new{useRLE, M}(missingvalue)
    end
end

use_rle(cfg::SinkConfig{useRLE}) where useRLE = useRLE

"""
$(SIGNATURES)

Make a sink configuration, using defaults.
"""
SinkConfig(; useRLE = true, missingvalue = missing) = SinkConfig{useRLE}(missingvalue)

"Default sink configuration."
const SINKCONFIG = SinkConfig{true}(missing)

"Sink configuration that collects to vectors."
const SINKVECTORS = SinkConfig{false}(missing)

####
#### Reference implementation for sinks: `Vector`
####

"""
$(SIGNATURES)

Create and return a sink using configuration `cfg` that stores elements of type `T`. When
`T` is unkown, use `Base.Bottom`.
"""
make_sink(cfg::SinkConfig{true,M}, ::Type{T}) where {M, T} = RLEVector{M}(Int8, T)

make_sink(cfg::SinkConfig{false,M}, ::Type{T}) where {M, T} = Vector{T}()

"""
$(SIGNATURES)

Either store `elt` in `sink` (in which case the returned value is `≡ sink`), or
allocate a new sink that can do this, copy the contents, save `elt` and return that (then
the returned value is `≢ sink`).
"""
function store!_or_reallocate(::SinkConfig, sink::Vector{T}, elt) where T
    if cancontain(T, elt)
        (push!(sink, elt); sink)
    else
        append1(sink, narrow(elt))
    end
end

"""
$(SIGNATURES)

Convert `sink` to a *column*.

`sink` may share structure with the result and is not supposed to be used for saving any
more elements.
"""
finalize_sink(::SinkConfig, sink::Vector) = sink

####
#### RepeatValue type
####

"""
RepeatValue(value, len)

Equivalent to a vector containing `len` instances of `value`. Used *internally*.
"""
struct RepeatValue{T} <: AbstractVector{T}
    value::T
    len::Int
end

Base.size(s::RepeatValue) = (s.len, )

Base.IndexStyle(::Type{<:RepeatValue}) = Base.IndexLinear()

function Base.getindex(s::RepeatValue, i::Integer)
    @boundscheck checkbounds(s, i)
    s.value
end

####
#### RLE compressed vector
####

"""
$(TYPEDEF)

An RLE encoded vector, using negative lengths for missing values. Use the
`RLEVector{S}(C, T)` constructor for creating an empty one.

When an elemenet in `counts` is positive, it encodes that many of the corresponding element
in `data`.

Negative `counts` encode values of type `S` (has to be a concrete singleton). In this case
there is no corresponding value in `data`, ie `data` may have *fewer elements* than
`counts`. Note that `0` values in count are reserved, and currently should not happen.

The flag `anyS::Bool` is `true` iff there are *any* values of type `S` in object.

An RLEVector is iterable.
"""
struct RLEVector{C,T,S,anyS}
    counts::Vector{C}
    data::Vector{T}
    function RLEVector{S,anyS}(counts::Vector{C}, data::Vector{T}
                               ) where {C <: Signed, T, S, anyS}
        @argcheck issingletontype(S) "$(S) is not a concrete singleton type."
        @argcheck anyS isa Bool
        @argcheck length(counts) ≥ length(data)
        new{eltype(counts), eltype(data), S, anyS}(counts, data)
    end
end

"""
$(SIGNATURES)

Create an empty RLEVector for `Union{T,S}`, with special-casing the singleton type `S`. RLE
counts are stored in type `C`.
"""
RLEVector{S}(C::Type{<:Signed}, ::Type{S}) where {S} =
    RLEVector{S, true}(Vector{C}(), Vector{Union{}}())

RLEVector{S}(C::Type{<:Signed}, ::Type{T}) where {S, T} =
    RLEVector{S, false}(Vector{C}(), Vector{T}())

RLEVector{S}(C::Type{<:Signed}, ::Type{Union{S,T}}) where {S, T} =
    RLEVector{S, true}(Vector{C}(), Vector{T}())

function store!_or_reallocate(::SinkConfig, sink::RLEVector{C,T,S,anyS}, elt) where {C,T,S,anyS}
    @unpack counts, data = sink
    if cancontain(T, elt)       # can accommodate elt, same sink
        if isempty(data)
            push!(data, elt)
            push!(counts, one(C))
        elseif data[end] == elt && 0 < counts[end] < typemax(C)
            counts[end] += one(C) # increment existing count
        else
            push!(counts, one(C)) # start new RLE run
            push!(data, elt)
        end
        sink
    else                        # can't accommodate elt, allocate new sink
        RLEVector{S,anyS}(append1(counts, one(C)), append1(data, narrow(elt)))
    end
end

function store!_or_reallocate(cfg::SinkConfig, sink::RLEVector{C, T, S, false}, elt::S
                              ) where {C, T, S}
    @unpack counts, data = sink
    # simply flip the flag anyS
    store!_or_reallocate(cfg, RLEVector{S, true}(counts, data), elt)
end

function store!_or_reallocate(::SinkConfig, sink::RLEVector{C,T,S,true}, elt::S) where {C,T,S}
    @unpack counts = sink
    if isempty(counts)                  # no elements yet
        push!(counts, -one(C))
    elseif 0 > counts[end] > typemin(C) # ongoing RLE run with S
        counts[end] -= one(C)
    else
        push!(counts, -one(C))  # start new RLE runx
    end
    sink
end

finalize_sink(::SinkConfig, rle::RLEVector) = rle

function Base.eltype(::Type{RLEVector{C,T,S,anyS}}) where {C,T,S,anyS}
    anyS ? Base.promote_typejoin(T,S) : T
end

Base.length(rle::RLEVector) = isempty(rle.counts) ? 0 : sum(abs ∘ Int, rle.counts)

function Base.iterate(rle::RLEVector{C,T,S},
                 (countsindex, dataindex, remaining) = (0, 0, zero(C))) where {C,T,S}
    @unpack counts, data = rle
    if remaining < 0
        (S(), (countsindex, dataindex, remaining + one(C)))
    elseif remaining > 0
        (data[dataindex], (countsindex, dataindex, remaining - one(C)))
    else
        countsindex += 1
        countsindex > length(counts) && return nothing
        remaining = counts[countsindex]
        if remaining > 0
            dataindex += 1
        end
        iterate(rle, (countsindex, dataindex, remaining))
    end
end

####
#### Collecting named tuples
####

"""
$(TYPEDEF)

Wrapper type to indicate that the length should not be checked.

!!! note
    The perfect footgun. Only use when the lengths are known and verified by construction.
"""
struct TrustLength
    len::Int
end

"""
$(SIGNATURES)

Collect results from `itr` into a sink (using config `cfg`), then finalize and return the
column.
"""
function collect_column(cfg::SinkConfig, itr)
    y = iterate(itr)
    y ≡ nothing && return nothing
    elt, state = y
    narrow_elt = narrow(elt)
    sink = make_sink(cfg, typeof(narrow_elt))
    collect_column!(store!_or_reallocate(cfg, sink, narrow_elt), cfg, itr, state)
end

function collect_column!(sink, cfg::SinkConfig, itr, state)
    while true
        y = iterate(itr, state)
        y ≡ nothing && return finalize_sink(cfg, sink)
        elt, state = y
        newsink = store!_or_reallocate(cfg, sink, elt)
        sink ≡ newsink || return collect_column!(newsink, cfg, itr, state)
    end
end

"""
$(SIGNATURES)

Empty sinks for a named tuple of elements, using a type.
"""
function empty_sinks(cfg, ::Type{NamedTuple{N,T}}) where {N,T}
    NamedTuple{N}(map(S -> make_sink(cfg, S), fieldtypes(T)))
end

"""
$(SIGNATURES)

Start sinks using row, using the default `known_types` when available.
"""
function start_sinks(cfg, row::T, known_types) where {T}
    rowtypes = merge_default_types(T, known_types)
    sinks = empty_sinks(cfg, rowtypes)
    store!_or_reallocate_row(cfg, sinks, row)
end

"""
$(SIGNATURES)

Finalize a (named) tuple of sinks.
"""
finalize_sinks(cfg, sinks::NamedTuple) = map(sink -> finalize_sink(cfg, sink), sinks)

"""
$(SIGNATURES)

Broadcast `store!_or_rellocate` for a compatible (named) tuple of `sinks` and `elts`. Return
the (potentially) new sinks.
"""
@inline store!_or_reallocate_row(cfg, sinks, elts) =
    map((sink, elt) -> store!_or_reallocate(cfg, sink, elt), sinks, elts)

"""
len, columns, ordering_rule = $(SIGNATURES)

Collect results from `itr`, which are supposed to be `NamedTuple`s with the same names, into
sinks (using config `cfg`), then finalize and return

1. the length,

2. the `NamedTuple` of the columns, and

3. the ordering rule (which is always `::TrustOrdering`, by construction).

Determine the names and types from the first named tuple, using `known_types` as the
narrowest types for the given columns.

# Special rules for empty iterators

When `itr` is empty, use a `known_types` will be used to create empty columns, and only the
`TryOrdering` rule will be narrowed to these. Other rule with more column names may cause an
error in the callee, which is intentional.
"""
function collect_columns(cfg::SinkConfig, itr, ordering_rule::OrderingRule{R},
                         known_types::Type{<:NamedTuple{N}} = NamedTuple{(), Tuple{}}
                         ) where {R,N}
    y = iterate(itr)
    if y ≡ nothing
        columns = finalize_sinks(cfg, empty_sinks(cfg, known_types))
        return 0, columns, mask_try_ordering(ordering_rule, N)
    end
    elts, state = y
    sinks = start_sinks(cfg, elts, known_types)
    collect_columns!(sinks, 1, cfg, itr, mask_try_ordering(ordering_rule, keys(elts)),
                     # :trust, we don't need the last element for comparison, hence the ()
                     R ≡ :trust ? () : elts, state)
end

function collect_columns!(sinks::NamedTuple, len::Int, cfg::SinkConfig, itr,
                          ordering_rule::OrderingRule{R}, lastelts, state) where R
    @unpack ordering = ordering_rule
    while true
        y = iterate(itr, state)
        if y ≡ nothing
            return TrustLength(len), finalize_sinks(cfg, sinks), TrustOrdering(ordering_rule)
        end
        elts, state = y
        newsinks = store!_or_reallocate_row(cfg, sinks, elts)
        len += 1
        if R ≢ :trust
            if cmp_ordering(ordering, lastelts, elts) > 0
                if R ≡ :verify
                    error("Sorting $(sorting) violated: $(lastelts) ≰ $(elts).")
                else # R ≡ :try
                    new_ordering = retained_ordering(ordering, lastelts, elts)
                    return collect_columns!(newsinks, len, cfg, itr,
                                            OrderingRule{R}(new_ordering), elts, state)
                end
            end
            lastelts = elts
        end
        sinks ≡ newsinks || return collect_columns!(newsinks, len, cfg, itr, ordering_rule,
                                                    lastelts, state)
    end
end
