#####
##### Interface and implementation for split-apply-combine.
#####

export by, RepeatRow, ignoreindex, aggregator

"""
RepeatRow(row)

A row repeated as many times as needed. Can be `merge`d to a `FunctionalTable`, or
instantiated with `FunctionalTable(len, repeat_row)`.
"""
struct RepeatRow{T <: NamedTuple}
    row::T
end

function FunctionalTable(len::Int, repeat_row::RepeatRow,
                         ordering::OrderingRule = TrustOrdering())
    FunctionalTable(TrustLength(len), map(v -> RepeatValue(v, len), repeat_row.row),
                    ordering)
end

Base.merge(row::RepeatRow, ft::FunctionalTable; kwargs...) =
    merge(FunctionalTable(length(ft), row), ft; kwargs...)

Base.merge(ft::FunctionalTable, row::RepeatRow; kwargs...) =
    merge(ft, FunctionalTable(length(ft), row); kwargs...)

"""
$(SIGNATURES)

Prepend the `index` as repeated columns to `f(index, tables...)`.
"""
fuse(f, index::NamedTuple, tables...) =
    merge(RepeatRow(index), FunctionalTable(f(index, tables...)))

"""
$(TYPEDEF)

Implements [`by`](@ref) using an iterator.

# Internals

Each rows from the underlying `FunctionalTable` is split into `index` and `rest`.

Iterator state is

1. `nothing` when the rows of the underlying FunctionalTable have been exhausted,

2. `index`, `rest`, `itrstate` for the next block, where `index` and `rest` are the first
(mismatching) row that has *not* been pushed to the buffers.
"""
struct SplitTable{K <: NamedTuple, B <: NamedTuple, O <: TableOrdering, T <: FunctionalTable}
    block_buffers::B
    block_ordering::O
    ft::T
    function SplitTable{K}(block_buffers::B, block_ordering::O, ft::T) where {K, B, O, T}
        new{K, B, O, T}(block_buffers, block_ordering, ft)
    end
end

"""
$(SIGNATURES)

Helper function to set up a `SplitTable`. *Internal*.
"""
function split_table(ft::FunctionalTable{C}, splitkeys::Keys) where {C}
    @argcheck is_prefix(splitkeys, orderkey.(ordering(ft)))
    block_ordering = ()     # FIXME calculate this
    T = NamedTuple{fieldnames(C)}(map(eltype, fieldtypes(C)))
    index, rest = split_namedtuple(NamedTuple{splitkeys}, T)
    block_buffers = map(V -> Vector{V}(), rest)
    K = NamedTuple{keys(index), Tuple{values(index)...}}
    SplitTable{K}(block_buffers, block_ordering, ft)
end

Base.IteratorSize(::Type{<:SplitTable}) = Base.SizeUnknown()

Base.IteratorEltype(::Type{<:SplitTable}) = Base.HasEltype()

Base.eltype(::Type{<: SplitTable{K,B,O}}) where {K,B,O} = Tuple{K, FunctionalTable{B,O}}

ordering(st::SplitTable{K}) where K = mask_ordering(ordering(st.ft), fieldnames(K))

function Base.iterate(g::SplitTable{K}) where K
    row, itrstate = @ifsomething iterate(g.ft)
    index, rest = split_namedtuple(K, row)
    iterate(g, (index, rest, itrstate))
end

function Base.iterate(g::SplitTable{K}, state) where K
    @unpack ft, block_buffers, block_ordering = g
    map(b -> resize!(b, 0), block_buffers) # FIXME use foreach?
    index, rest, itrstate = @ifsomething state
    len = 0
    _block() = (index, FunctionalTable(TrustLength(len),
                                       # FIXME not entirely sure we need to copy
                                       # if that is emphasized in the semantics
                                       map(copy, block_buffers),
                                       TrustOrdering(block_ordering)))
    while true
        map(push!, block_buffers, rest) # FIXME use foreach?
        len += 1
        y = iterate(ft, itrstate)
        y ≡ nothing && return _block(), nothing # done
        row, itrstate = y
        row_index, row_rest = split_namedtuple(K, row)
        if index == row_index
             rest = row_rest
        else
           return _block(), (row_index, row_rest, itrstate)
        end
    end
end

####
#### by and its implementation
####

"""
$(SIGNATURES)

An iterator that groups rows of tables by the columns `splitkeys`, returning
`(index::NamedTupe, table::FunctionalTable)` for each contiguous block of the index keys.

The function has a convenience form `by(ft, splitkeys...; ...)`.
"""
function by(ft::FunctionalTable, splitkeys::Keys)
    # TODO by could be very clever here by only sorting the subgroup which is unsorted,
    # and giving views of the underlying vectors instead of creating new tables
    sorted_ft = is_prefix(splitkeys, orderkey.(ordering(ft))) ? ft :
        sort(ft, split_compatible_ordering(ordering(ft), splitkeys))
    split_table(sorted_ft, splitkeys)
end

by(ft::FunctionalTable, splitkeys::Symbol...; kwargs...) = by(ft, splitkeys; kwargs...)

"""
$(SIGNATURES)

Map a table split with [`by`](@ref) using `f`.

Specifically, `f(index, table)` receives the split index (a `NamedTuple`) and a
`FunctionalTable`.

It is supposed to return an *iterable* that returns rows (can be a `FunctionalTable`). These
will be prepended with the corresponding index, and collected into a `FunctionalTable` with
`cfg`.

When `f` returns just a single row (eg aggregation), wrap by `Ref` to create a
single-element iterable.
"""
function Base.map(f, st::SplitTable; cfg = SINKCONFIG)
    # FIXME: idea: custom ordering override? would that make sense?
    FunctionalTable(Iterators.flatten(imap(args -> fuse(f, args...), st)),
                    TrustOrdering(ordering(st)); cfg = cfg)
end

"""
$(SIGNATURES)

Wrap a function returning a closure that ignores the first argument (the index in
[`by`](@ref) mappings).
"""
@inline ignoreindex(f) = (_, args...) -> f(args...)

"""
$(SIGNATURES)

Wrap a function so that it maps columns of a `FunctionalTable` to a table with a single row,
columwise, ignoring the index. Returns a closure.

# Example

```julia
map(aggregator(mean), by(ft, :col))
```

will calculate means after grouping by `:col`.
"""
@inline aggregator(f) = ignoreindex(ft -> Ref(map(f, columns(ft))))
