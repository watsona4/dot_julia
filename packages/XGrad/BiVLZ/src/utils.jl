
## utils.jl - utilities and helpers

# TODO: make recursive like calls_to_bcast
function bcast_to_call(pex::Expr)
    @assert pex.head == :(.)
    return Expr(:call, pex.args[1], pex.args[2].args...)
end

function calls_to_bcast(ex)
    return macroexpand(Main, :(@. $ex)) |> subs_bcast_with_dot
end

deriv_name(z::Symbol, x::Symbol) = Symbol("d$(z)!d$(x)")
split_deriv_name(vname) = Symbol.(split(String(vname), "!"))


function find_related(g::AbstractExGraph, dydx_v::Symbol)
    subderivs = Symbol[]
    i = 1
    name = Symbol("$(dydx_v)__$(i)")
    while haskey(g, name)
        push!(subderivs, name)
        i += 1
        name = Symbol("$(dydx_v)__$(i)")
    end
    return subderivs
end


# # (symbolic) derivative size propagation

const DERIV_NAME_PATTERN = r"(d.+)!(d.+)"

# function propagate_deriv_size!(g::AbstractExGraph, dd_name::Symbol)
#     sizes = @get_or_create(g.ctx, :sizes, Dict())
#     rg = match(DERIV_NAME_PATTERN, String(dd_name))
#     @assert length(rg.captures) == 2
#     str_dnames = rg.captures
#     zname = Symbol(str_dnames[1][2:end])
#     xname = Symbol(split(str_dnames[2][2:end], "__")[1]) # cut down `__$(i)` part if any
#     zsize, xsize = (sizes[zname], sizes[xname])
#     if zsize == :(())
#         # output var is constant
#         sizes[dd_name] = xsize
#     else
#         sizes[dd_name] = :(($zsize..., $xsize...)) |> simplify
#     end
# end


# function propagate_deriv_size!(g::AbstractExGraph)
#     for nd in g.tape
#         vname = varname(nd)
#         if match(DERIV_NAME_PATTERN, String(vname)) != nothing
#             propagate_deriv_size!(g, vname)
#         end
#     end
# end


# # (numeric) derivative size propagation

function infer_deriv_size!(g::AbstractExGraph, dd_name::Symbol)
    rg = match(DERIV_NAME_PATTERN, String(dd_name))
    @assert length(rg.captures) == 2
    str_dnames = rg.captures
    zname = Symbol(str_dnames[1][2:end])
    xname = Symbol(split(str_dnames[2][2:end], "__")[1]) # cut down `__$(i)` part if any
    # in case z or x haven't been evaluated and their size isn't known yet
    evaluate!(g, zname)
    evaluate!(g, xname)
    sizes = @get_or_create(g.ctx, :rsizes, Dict())
    if haskey(sizes, xname)
        # some nodes (e.g. structs) may not have a size
        zsize, xsize = (sizes[zname], sizes[xname])
        sizes[dd_name] = (zsize..., xsize...)
    end
end


function infer_deriv_size!(g::AbstractExGraph)
    for nd in g.tape
        vname = varname(nd)
        if match(DERIV_NAME_PATTERN, String(vname)) != nothing
            infer_deriv_size!(g, vname)
        end
    end
end


# top type

"The top type describing given data"
top_type(x::AbstractArray{T,N}) where {T,N} = AbstractArray{T,N}
top_type(x::Number) = Number
top_type(x::T) where T = T

top_type(::Type{AT}) where {AT <: AbstractArray{T,N}} where {T,N} = AbstractArray{T,N}
top_type(::Type{T}) where {T <: Number} = Number
top_type(::Type{T}) where T = T
