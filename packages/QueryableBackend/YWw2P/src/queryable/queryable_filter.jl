struct QueryableFilter <: Queryable
    source
    filter_func
    filter_expr
    getiterator
end

function QueryOperators.filter(source::Queryable, filter_func::Function, filter_expr::Expr)
    return QueryableFilter(source, filter_func, filter_expr, source.getiterator)
end
