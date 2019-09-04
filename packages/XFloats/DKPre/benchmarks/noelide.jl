using MacroTools

walk(x, inner, outer) = outer(x)
walk(x::Expr, inner, outer) = outer(Expr(x.head, map(inner, x.args)...))
postwalk(f, x) = walk(x, x -> postwalk(f, x), f)

function referred(expr::Expr)
    if expr.head == :$
        :($(Expr(:$, :(Ref($(expr.args...)))))[])
    else
        expr
    end
end
referred(x)  = x

"""
    @noelide _bmacro_ expression
where _bmacro_ is one of @btime, @belapsed, @benchmark
Wraps all interpolated code in _expression_ in a __Ref()__ to
stop the compiler from cheating at simple benchmarks. Works
with any macro that accepts interpolation
#Example
    julia> @btime \$a + \$b
      0.024 ns (0 allocations: 0 bytes)
    3
    julia> @noelide @btime \$a + \$b
      1.277 ns (0 allocations: 0 bytes)
    3
"""
macro noelide(expr)
    out = postwalk(referred, expr) |> esc
end

