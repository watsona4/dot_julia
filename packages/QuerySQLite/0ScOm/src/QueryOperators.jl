function as(new_name_model_row::Pair{Symbol, <: SourceCode}; options...)
    SQLExpression(:AS,
        translate(new_name_model_row.second.code; options...),
        new_name_model_row.first
    )
end

@code_instead QueryOperators.drop SourceCode Integer
@translate ::typeof(QueryOperators.drop) :OFFSET

@code_instead QueryOperators.filter SourceCode Any Expr
function translate_dispatch(::typeof(QueryOperators.filter), iterator, call, call_expression; options...)
    SQLExpression(:WHERE,
        translate(iterator; options...),
        translate(call(model_row(iterator)).code; options...)
    )
end

@code_instead QueryOperators.join SourceCode SourceCode Any Expr Any Expr Any Expr
function translate_dispatch(::typeof(QueryOperators.join), source1, source2, key1, key1_expression, key2, key2_expression, combine, combine_expression; options...)
    model_row_1 = model_row(source1; other = true)
    model_row_2 = model_row(source2; other = true)
    SQLExpression(:ON,
        SQLExpression(Symbol("INNER JOIN"),
            SQLExpression(:SELECT,
                translate(source1; options...),
                Generator(
                    pair -> as(pair; options...),
                    pairs(combine(model_row_1, model_row_2))
                )...
            ),
            translate(source2; other = true, options...)
        ),
        SQLExpression(:(=),
            translate(key1(model_row_1).code; options...),
            translate(key2(model_row_2).code; other = true, options...)
        )
    )
end

@code_instead QueryOperators.orderby SourceCode Any Expr
function translate_dispatch(::typeof(QueryOperators.orderby), unordered, key_function, key_function_expression; options...)
    SQLExpression(Symbol("ORDER BY"),
        translate(unordered; options...),
        translate(key_function(model_row(unordered)).code; options...)
    )
end
@code_instead QueryOperators.thenby SourceCode Any Expr
function translate_dispatch(::typeof(QueryOperators.thenby), unordered, key_function, key_function_expression; options...)
    original = translate(unordered; options...)
    SQLExpression(original.call, original.arguments...,
        translate(key_function(model_row(unordered)).code; options...)
    )
end

@code_instead QueryOperators.orderby_descending SourceCode Any Expr
function translate_dispatch(::typeof(QueryOperators.orderby_descending), unordered, key_function, key_function_expression; options...)
    SQLExpression(Symbol("ORDER BY"),
        translate(unordered; options...),
        SQLExpression(:DESC,
            translate(key_function(model_row(unordered)).code; options...)
        )
    )
end
@code_instead QueryOperators.thenby_descending SourceCode Any Expr
function translate_dispatch(::typeof(QueryOperators.thenby_descending), unordered, key_function, key_function_expression; options...)
    original = translate(unordered; options...)
    SQLExpression(original.call, original.arguments...,
        SQLExpression(:DESC,
            translate(key_function(model_row(unordered)).code; options...)
        )
    )
end

@code_instead QueryOperators.map SourceCode Any Expr
function model_row_dispatch(::typeof(QueryOperators.map), iterator, call, call_expression; options...)
    call(model_row(iterator; options...))
end

function translate_dispatch(::typeof(QueryOperators.map), select_table, call, call_expression; options...)
    SQLExpression(
        Symbol("SELECT"), translate(select_table; options...),
        Generator(
            pair -> as(pair; options...),
            pairs(call(model_row(select_table; options...)))
        )...
    )
end

@code_instead QueryOperators.take SourceCode Any
@translate ::typeof(QueryOperators.take) :LIMIT

@code_instead QueryOperators.unique SourceCode Any Expr
function translate_dispatch(::typeof(QueryOperators.unique), repeated, key_function, key_function_expression; options...)
    result = translate(repeated; options...)
    SQLExpression(Symbol(string(result.call, " DISTINCT")), result.arguments...)
end
