####
#### Sort FunctionalTable by rows.
####

function sort_in_memory(ft::FunctionalTable, ordering::TableOrdering)
    FunctionalTable(sort!(collect(ft), lt = (a, b) -> isless_ordering(ordering, a, b)),
                    TrustOrdering(ordering))
end

function Base.sort(ft::FunctionalTable,
                   column_ordering_specifications::Tuple{Vararg{ColumnOrderingSpecification}})
    sort_ordering = table_ordering(column_ordering_specifications)
    # prefix of an existing order is costless
    is_prefix(sort_ordering, ordering(ft)) && return FunctionalTable(ft, TrustOrdering(sort_ordering))
    # TODO columns which are already sorted need not be resorted
    # TODO columns which do not need to be sorted can be skipped and a permutation applied
    # TODO select appropriate sorting method using heuristics for table size & sorting
    sort_in_memory(ft, sort_ordering)
end

# convenience wrapper
function Base.sort(ft::FunctionalTable,
          column_ordering_specifications::ColumnOrderingSpecification...)
    sort(ft, column_ordering_specifications)
end
