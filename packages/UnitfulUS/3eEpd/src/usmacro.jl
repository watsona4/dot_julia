"""
    macro us_str(unit)

String macro to easily recall U.S. customary units located in the `UnitfulUS`
package. Although all unit symbols in that package are suffixed with `_us`,
the suffix should not be used when using this macro.

Note that what goes inside must be parsable as a valid Julia expression.

Examples:

```jldoctest
julia> 1.0us"tbsp"
1.0 m s^-1

julia> 1.0us"syd" - 1.0u"yd"
1.0 m N
```
"""
macro us_str(unit)
    ex = Meta.parse(unit)
    esc(replace_value(ex))
end

const allowed_funcs = [:*, :/, :^, :sqrt, :√, :+, :-, ://]
function replace_value(ex::Expr)
    if ex.head == :call
        ex.args[1] in allowed_funcs ||
            error("""$(ex.args[1]) is not a valid function call when parsing a unit.
             Only the following functions are allowed: $allowed_funcs""")
        for i=2:length(ex.args)
            if typeof(ex.args[i])==Symbol || typeof(ex.args[i])==Expr
                ex.args[i]=replace_value(ex.args[i])
            end
        end
        return Core.eval(@__MODULE__, ex)
    elseif ex.head == :tuple
        for i=1:length(ex.args)
            if typeof(ex.args[i])==Symbol
                ex.args[i]=replace_value(ex.args[i])
            else
                error("only use symbols inside the tuple.")
            end
        end
        return Core.eval(@__MODULE__, ex)
    else
        error("Expr head $(ex.head) must equal :call or :tuple")
    end
end

dottify(s, t, u...) = dottify(Expr(:(.), s, QuoteNode(t)), u...)
dottify(s) = s

function replace_value(sym::Symbol)
    s = Symbol(sym, :_us)
    if !(isdefined(UnitfulUS, s) && ustrcheck_bool(getfield(UnitfulUS, s)))
        error("Symbol $s could not be found in UnitfulUS.")
    end

    return getfield(UnitfulUS, s)
end

replace_value(literal::Number) = literal

ustrcheck_bool(x::Unitful.Number) = true
ustrcheck_bool(x::Unitful.Unitlike) = true
ustrcheck_bool(x::Unitful.Quantity) = true
ustrcheck_bool(x::Unitful.MixedUnits) = true
ustrcheck_bool(x) = false
