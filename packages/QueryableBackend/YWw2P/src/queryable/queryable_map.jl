struct QueryableMap <: Queryable
    source
    f_func
    f_expr
    getiterator
end

function QueryOperators.map(source::Queryable, f::Function, f_expr::Expr)
    return QueryableMap(source, f, f_expr, source.getiterator)
end
