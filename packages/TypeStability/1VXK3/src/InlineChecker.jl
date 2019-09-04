
export enable_inline_stability_checks, inline_stability_checks_enabled
export @stable_function, stability_warn


run_inline_stability_checks = false

"""
    enable_inline_stability_checks(::Bool)

Sets whether to run inline stability checks from [`@stable_function`](@ref).

If it is set to `false` (the default value), @stable_function does not perform
any type stability checks.

The value is checked when @stable_function is evaluated, so this should useually
be set at the begining of a package definition.

See [`inline_stability_checks_enabled`](@ref).
"""
function enable_inline_stability_checks(enabled::Bool)
    global run_inline_stability_checks
    run_inline_stability_checks = enabled
end

"""
    inline_stability_checks_enabled()::Bool

Returns whether inline stability checks are enabled.

See [`enable_inline_stability_checks`](@ref).
"""
function inline_stability_checks_enabled()::Bool
    run_inline_stability_checks
end


"""
    @stable_function arg_lists function_name
    @stable_function arg_lists function_definition(s)
    @stable_function arg_lists acceptable_instability function_name
    @stable_function arg_lists acceptable_instability function_definitions(s)

Checks the type stability of the function under the given argument lists.

If the second value is a function definition, the function is defined before
checking type stability.
"""
macro stable_function(arg_lists, unstable, func)
    if run_inline_stability_checks
        if unstable == nothing || unstable == :nothing
            unstable = Dict{Symbol, Type}()
        end
        if VERSION < v"0.7.0-"
            (func_names, body) = parsebody(func, @__MODULE__)
        else
            (func_names, body) = parsebody(func, __module__)
        end
        esc(quote
            $body
            $((:(TypeStability.stability_warn($name, TypeStability.check_function($name, $arg_lists, $unstable)))
               for name in func_names)...)
        end)
    else
        esc(func)
    end
end

macro stable_function(arg_lists, func)
    esc(:(TypeStability.@stable_function $arg_lists nothing $func))
end

"""
    parsebody(body, mod::Any)

Internal method to parse the last argument of @stable_function
`mod` should be a Module in Julia 0.7+, but don't matter on Julia 0.6 due to changes in `macroexpand`
"""
function parsebody(body::Expr, mod; require_function=true)
    if body.head == :function || (body.head == :(=) && isa(body.args[1], Expr))
        if body.args[1] isa Symbol
            func_names = [body.args[1]]
        else
            subExpr = body.args[1]
            if subExpr.head == :where
                subExpr = subExpr.args[1]
            end
            if subExpr.head == :(::)
                subExpr = subExpr.args[1]
            end
            if subExpr.head == :call
                func_names = [subExpr.args[1]]
            else
                error("Cannot find function name in $(dump(body))")
            end
        end
    elseif body.head == :macrocall
        if VERSION < v"0.7.0-"
            expanded_body = macroexpand(body)
        else
            expanded_body = macroexpand(mod, body)
        end
        if isa(expanded_body, Expr)
            (func_names, _) = parsebody(expanded_body, mod; require_function=false)
        elseif isa(expanded_body, Symbol)
            func_names = [expanded_body]
        elseif require_function
            error("Cannot find a function name in macro expansion of $body")
        else
            func_names = Symbol[]
        end
    elseif body.head == :block
        func_names = Symbol[]
        for expr in body.args
            if isa(expr, Expr)
                (expr_func_names, _) = parsebody(expr, mod; require_function=false)
                append!(func_names, expr_func_names)
            end
        end
        func_names = unique(func_names)
        if require_function && length(func_names) == 0
            error("Cannot find any function names in $body")
        end
    elseif require_function
        error("Don't know how to find function names in $body")
    else
        func_names = Symbol[]
    end
    (func_names, body)
end

function parsebody(func::Symbol, mod)
    ([func], quote end)
end
