export match_tuple
export @addField

"To match the tuple expression inside `begin` block and discard the rest."
match_tuple = @λ begin
    e::Expr -> e.head == :tuple ? e : nothing
    a -> nothing
end

"To call the tuple args by `f`."
macro fun_call_tuple(f, expr)
    args = filter(!isnothing, map(match_tuple, expr.args))
    exs = [:($(f)($(arg.args...))) for arg in args]
    Expr(:block, (esc(ex) for ex in exs)...)
end

@generated function parse_field_arg(tag::Integer, option::String, val::Number)
    :(gmsh.model.mesh.field.setNumber(tag, option, val))
end

@generated function parse_field_arg(tag::Integer, option::String, val::AbstractVector)
    :(gmsh.model.mesh.field.setNumbers(tag, option, val))
end

@generated function parse_field_arg(tag::Integer, option::String, val::AbstractString)
    :(gmsh.model.mesh.field.setString(tag, option, val))
end

@generated function parse_option_arg(name, val::AbstractString)
    :(gmsh.option.setString(name, val))
end

@generated function parse_option_arg(name, val::Number)
    :(gmsh.option.setNumber(name, val))
end

@generated function parse_option_arg(name, r::I, g::I, b::I, a::I=0) where I<:Integer
    gmsh.option.setColor(name, r, g, b, a)
end

const GmshModelGeoOps = Dict(
    :addPoint => :(gmsh.model.geo.addPoint),
    :addLine => :(gmsh.model.geo.addLine),
    :setTransfiniteCurve => :(gmsh.model.geo.mesh.setTransfiniteCurve),
    :addOption => :(GmshTools.parse_option_arg),
)

for (k, v) in GmshModelGeoOps
    @eval begin
        export $(Symbol("@" * String(k)))
        macro $(k)(expr)
            # nested escape, maybe related to: https://github.com/JuliaLang/julia/issues/23221
            esc(:(GmshTools.@fun_call_tuple($$(QuoteNode(v)), $(expr))))
        end
    end
end

"To add `gmsh.model.mesh.field`."
macro addField(tag, name, expr)
    args = filter(!isnothing, map(match_tuple, expr.args))
    # reason not calling `fun_call_tuple` is that it adds an additional argument `tag` at start
    exs = [:(parse_field_arg($(esc(tag)), $(map(esc, arg.args)...))) for arg in args]
    quote
        gmsh.model.mesh.field.add($(esc(name)), $(esc(tag)))
        $(Expr(:block, (ex for ex in exs)...))
    end
end
