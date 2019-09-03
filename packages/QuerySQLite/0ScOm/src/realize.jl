struct ArgumentsNumberException <: Exception
    call::Symbol
    expected_number_of_arguments::Int
end

function show_error(io::IO, exception::ArgumentsNumberException)
    print(io, "Expected $(exception.expected_number_of_arguments) arguments to $(exception.call)")
end

function unary(sql_expression)
    if length(sql_expression.arguments) != 1
        throw(ArgumentsNumberException(sql_expression.call, 1))
    else
        string(sql_expression.call, " ", realize(sql_expression.arguments[1]))
    end
end

function binary(sql_expression)
    if length(sql_expression.arguments) != 2
        throw(ArgumentsNumberException(sql_expression.call, 2))
    else
        string(
            realize(sql_expression.arguments[1]),
            " ", sql_expression.call, " ",
            realize(sql_expression.arguments[2]),
        )
    end
end

function tight_binary(sql_expression)
    if length(sql_expression.arguments) != 2
        throw(ArgumentsNumberException(sql_expression.call, 2))
    else
        string(
            realize(sql_expression.arguments[1]),
            sql_expression.call,
            realize(sql_expression.arguments[2]),
        )
    end
end

function function_call(sql_expression)
    string(
        sql_expression.call, "(",
        join(map_unrolled(realize, sql_expression.arguments), ", "), ")"
    )
end

function postfix(sql_expression)
    if length(sql_expression.arguments) != 1
        throw(ArgumentsNumberException(sql_expression.call, 1))
    else
        string(realize(sql_expression.arguments[1]), " ", sql_expression.call)
    end
end

function rest_first(sql_expression)
    realized_arguments = map_unrolled(realize, sql_expression.arguments)
    string(sql_expression.call, " ",
        join(realized_arguments[2:end], ", "),
        " ", realized_arguments[1]
    )
end

function first_result(sql_expression)
    realized_arguments = map_unrolled(realize, sql_expression.arguments)
    string(realized_arguments[1], " ",
        sql_expression.call, " ",
        join(realized_arguments[2:end], ", "),
    )
end

function realize(something)
    something
end

function realize(sql_expression::SQLExpression)
    if in(sql_expression.call, (:COALESCE,))
        function_call(sql_expression)
    elseif sql_expression.call == :IF && length(sql_expression.arguments) == 3
        string("CASE WHEN", realize(sql_expressions.arguments[1]),
            "THEN", realize(sql_expressions.arguments[2]),
            "ELSE", realize(sql_expressions.arguments[3])
        )
    elseif in(sql_expression.call, (:DESC, Symbol("IS NULL")))
        postfix(sql_expression)
    elseif in(sql_expression.call, (:SELECT, Symbol("SELECT DISTINCT")))
        rest_first(sql_expression)
    elseif in(sql_expression.call, (Symbol("ORDER BY"),))
        first_result(sql_expression)
    elseif in(sql_expression.call, (:.,))
        tight_binary(sql_expression)
    elseif length(sql_expression.arguments) == 1
        unary(sql_expression)
    elseif length(sql_expression.arguments) == 2
        binary(sql_expression)
    else
        error("Cannot realize $sql_expression")
    end
end

function realize_final(sql_expression::SQLExpression)
    if sql_expression.call == :FROM
        realize(SQLExpression(:SELECT, sql_expression, :*))
    else
        realize(sql_expression)
    end
end

text(source_code::SourceCode) =
    realize_final(translate(source_code.code))
