#####
##### Building blocks for ordering columns and tables.
#####

export TrustOrdering, TryOrdering, VerifyOrdering

####
#### ColumnOrder
####

"""
$(TYPEDEF)

Ordering specification for a column. `K::Symbol` is a key for ordering by `isless`,
`R::Bool == true` reverses that for this key. *Internal.*
"""
struct ColumnOrdering{K, R}
    function ColumnOrdering{K, R}() where {K, R}
        @argcheck K isa Symbol
        @argcheck R isa Bool
        new{K, R}()
    end
end

"""
$(SIGNATURES)

Accessor for key. *Internal.*
"""
orderkey(co::ColumnOrdering{K}) where {K} = K

orderrev(co::ColumnOrdering{K, R}) where {K, R} = R

"""
$(SIGNATURES)

Process a column ordering specification, called by [`table_ordering`](@ref).
"""
@inline ColumnOrdering(key::Symbol, rev::Bool = false) = ColumnOrdering{key, rev}()
@inline ColumnOrdering(keyrev::Pair{Symbol, typeof(reverse)}) = ColumnOrdering(first(keyrev), true)
@inline ColumnOrdering(cs::ColumnOrdering) = cs
ColumnOrdering(x) = throw(ArgumentError("Unrecognized ordering specification $(x)."))

"Types accepted as valid column ordering specifications in the user API."
const ColumnOrderingSpecification =
    Union{Symbol, Pair{Symbol, typeof(reverse)}, ColumnOrdering}

ordering_repr(cs::ColumnOrdering{K, R}) where {K, R} = (R ? "↓" : "↑") * string(K)

"""
Shorthand for table ordering. *Internal.*
"""
const TableOrdering = Tuple{Vararg{ColumnOrdering}}

"""
$(SIGNATURES)

A string representation of an ordering, eg for use in `show`.
"""
function ordering_repr(ordering::TableOrdering)
    isempty(ordering) ? "no ordering" : "ordering " * join(ordering_repr.(ordering), " ")
end

"""
$(SIGNATURES)

Process ordering specifications for columns (an iterable or possibly a TableOrdering),
return a `TableOrdering`. Check for uniqueness (but not validity) of keys.

Accepted syntax:

- `:key`, for ordering a column in ascending order,

- `:key => reverse`, for ordering a column in descending order.

All functions which accept ordering specifications should use this, but the function itself
is not part of the API.
"""
table_ordering(column_ordering_specifications) =
    map(ColumnOrdering, tuple(column_ordering_specifications...))

"""
$(SIGNATURES)

When `invert == false`, keep the initial part of ordering that has keys in `keys`. Not
having a key in `keys` invalidates the tail ordering from that point. This is useful for
selecting subsets of orderings.

When `invert == true`, *having a key* in `keys` invalidates the ordering. This is useful for
orderings of merged and dropped columns.
"""
Base.@pure function mask_ordering(ordering::TableOrdering, keys::Keys, invert::Bool = false)
    kept = ColumnOrdering[]
    for o in ordering
        if key_in(orderkey(o), keys) ⊻ invert
            push!(kept, o)
        else
            # skipping a ColumnOrdering invalidates the rest
            break
        end
    end
    (kept..., )
end

"""
$(SIGNATURES)

Extend `ordering` so that it can be used to split a table with `splitkeys`.
"""
function split_compatible_ordering(ordering::TableOrdering, splitkeys::Keys)
    @argcheck allunique(splitkeys)
    o_first, o_rest = first(ordering), Base.tail(ordering)
    s_first = first(splitkeys)
    if orderkey(o_first) ≡ s_first
        (o_first, split_compatible_ordering(o_rest, Base.tail(splitkeys))...)
    else
        o_matched = findfirst(o -> orderkey(o) ≡ s_first, o_rest)
        (o_matched ≡ nothing ? ColumnOrdering{s_first, false}() : o_rest[o_matched],
         split_compatible_ordering(ordering, Base.tail(splitkeys))...)
    end
end

split_compatible_ordering(ordering::TableOrdering, splitkeys::Tuple{}) = ()

split_compatible_ordering(ordering::Tuple{}, splitkeys::Tuple{}) = ()

split_compatible_ordering(ordering::Tuple{}, splitkeys::Keys) = table_ordering(splitkeys)


####
#### Comparisons
####

cmp_ordering(::ColumnOrdering{K, R}, a, b) where {K, R} =
    cmp(getproperty(a, K), getproperty(b, K)) * (R ? -1 : 1)

"""
$(SIGNATURES)

Compare `a` and `b` given the `ordering`.

*Internal*.
"""
@inline cmp_ordering(ordering::TableOrdering, a, b) = _cmp_table_ordering(a, b, ordering...)

_cmp_table_ordering(a, b) = 0

function _cmp_table_ordering(a, b, column_ordering::ColumnOrdering, rest...)
    r = cmp_ordering(column_ordering, a, b)
    r ≠ 0 && return r
    _cmp_table_ordering(a, b, rest...)
end

@inline isless_ordering(ordering, a, b) = cmp_ordering(ordering, a, b) == -1

"""
$(SIGNATURES)

Return the (initial) part of `ordering` under which `a ≤ b`.
"""
retained_ordering(ordering::TableOrdering, a, b) = _retained_table_ordering(a, b, ordering...)

_retained_table_ordering(a, b) = ()

function _retained_table_ordering(a, b, column_ordering::ColumnOrdering, rest...)
    if cmp_ordering(column_ordering, a, b) ≤ 0
        (column_ordering, _retained_table_ordering(a, b, rest...)...)
    else
        ()
    end
end

####
#### Ordering rules
####

"""
$(TYPEDEF)

Rule for dealing with specified orderings. Verifies key uniqueness.

See [`VerifyOrdering`](@ref), [`TrustOrdering`](@ref), and [`TryOrdering`](@ref).

This type and its methods are *internal*.
"""
struct OrderingRule{R, O <: TableOrdering}
    ordering::O
    function OrderingRule{R}(ordering::O) where {R, O <: TableOrdering}
        @argcheck R ∈ (:trust, :verify, :try)
        @argcheck allunique(orderkey.(ordering)) "Duplicate order keys."
        new{R, O}(ordering)
    end
end

OrderingRule{R}(column_ordering_specifications::Tuple{Vararg{ColumnOrderingSpecification}}
                ) where {R} = OrderingRule{R}(table_ordering(column_ordering_specifications))

OrderingRule{R}(column_ordering_specifications::ColumnOrderingSpecification...) where {R} =
    OrderingRule{R}(column_ordering_specifications)

"Verify that the specified ordering holds. This is the default ordering rule."
const VerifyOrdering = OrderingRule{:verify}

"""
Accept the specified ordering to hold without any checks (except for verifying that column
names are valid).

!!! note
    This can lead to incorrect results, use cautiously. [`VerifyOrdering`](@ref) is
    recommended instead as it has little overhead.
"""
const TrustOrdering = OrderingRule{:trust}

"Try the specified ordering, when necesary degrade to a subset of it that holds."
const TryOrdering = OrderingRule{:try}

# forced conversion
OrderingRule{R}(ordering_rule::OrderingRule) where {R} =
    OrderingRule{R}(ordering_rule.ordering)

"""
$(SIGNATURES)

For `TryOrdering`, return a masked ordering rule that is is defined on `keys` so that
comparisons make sense, otherwise return the original `ordering_rule` (that will just error
for undefined keys).
"""
Base.@pure function mask_try_ordering(ordering_rule::OrderingRule{R}, keys::Keys) where {R}
    R ≡ :try ? OrderingRule{R}(mask_ordering(ordering_rule.ordering, keys)) : ordering_rule
end
