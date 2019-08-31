module CacheVariables

using BSON
import Logging: @info

export @cache

function _cachevars(ex::Expr)
    (ex.head === :(=))   && return Symbol[ex.args[1]]
    (ex.head === :block) && return collect(
        Iterators.flatten([_cachevars(exi) for exi in ex.args if isa(exi,Expr)])
    )
    return Vector{Symbol}(undef,0)
end

macro cache(path, ex::Expr, overwrite=false)
    vars = _cachevars(ex)
    vardesc = join(string.(vars), "\n")
    varkws  = [:($(var) = $(var)) for var in vars]
    varlist = :($(varkws...),)
    vartuple = :($(vars...),)

    return quote
        if !isfile($(esc(path))) || $(esc(overwrite))
            _ans = $(esc(ex))
            _msg = isfile($(esc(path))) ? "Overwriting " : "Saving to "
            @info(string(_msg, $(esc(path)), "\n", $(vardesc)))
            bson($(esc(path)); $(esc(varlist))...,ans=_ans)
            _ans
        else
            @info(string("Loading from ", $(esc(path)), "\n", $(vardesc)))
            data = BSON.load($(esc(path)))
            $(esc(vartuple)) = getindex.(Ref(data), $vars)
            data[:ans]
        end
    end
end

end # module
