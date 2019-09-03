function QueryOperators.query(source_code::SourceCode)
    source_code
end

function numbered_argument(number)
    Symbol(string("argument", number))
end
function assert_type(argument, type)
    Expr(:(::), argument, type)
end
function maybe_splat(argument, a_type)
    if @capture a_type Vararg{AType_}
        Expr(:(...), argument)
    else
        argument
    end
end
function code_instead(location, a_function, types...)
    arguments = ntuple(numbered_argument, length(types))
    Expr(:function,
        Expr(:call, a_function, map_unrolled(assert_type, arguments, types)...),
        Expr(:block, location, Expr(:call,
            combine_sources,
            a_function,
            map_unrolled(maybe_splat, arguments, types)...
        ))
    )
end

macro code_instead(a_function, types...)
    code_instead(__source__, a_function, types...) |> esc
end

struct SQLExpression
    call::Symbol
    arguments::Tuple
    SQLExpression(call, arguments...) = new(call, arguments)
end

function split_node(node::Expr)
    if @capture node call_(arguments__)
        if call == ifelse
            if_else
        else
            call
        end, arguments...
    elseif @capture node left_ && right_
        &, left, right
    elseif @capture node left_ || right_
        |, left, right
    elseif @capture node if condition_ yes_ else no_ end
        if_else, condition, yes, no
    else
        error("Cannot split node $node")
    end
end

function model_row_dispatch(arbitrary_function, iterator, arguments...; options...)
    model_row(iterator; options...)
end
function model_row(node::Expr; options...)
    model_row_dispatch(split_node(node)...; options...)
end

function translate(something; options...)
    something
end
function translate(source_row::SourceRow; options...)
    source_row.table_name
end
function translate(source_row::SourceOtherRow; options...)
end
function translate(node::Expr; options...)
    translate_dispatch(split_node(node)...; options...)
end

function translate_default(location, function_type, SQL_call)
    result = :(
        function translate_dispatch($function_type, arguments...; options...)
            $SQLExpression($SQL_call, $map_unrolled(
                argument -> $translate(argument; options...),
                arguments
            )...)
        end
    )
    result.args[2].args[1] = location
    result
end

macro translate(a_function, SQL_call)
    translate_default(__source__, a_function, SQL_call) |> esc
end
