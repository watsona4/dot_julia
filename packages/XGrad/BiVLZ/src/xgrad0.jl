
## xgrad0.jl - dynamic cache for xdiff

DERIV_CACHE = Dict{Any,Any}()


getsize(x::AbstractArray) = size(x)
getsize(x::Number) = ()

function getsize(x)
    if isstruct(x)
        sz_arr = []
        for fld in fieldnames(typeof(x))
            val = getfield(x, fld)
            push!(sz_arr, getsize(val))
        end
        return (sz_arr...,)
    else
        return size(x)
    end
end


"""
Calculate gradient of a function at specified inputs, cache the derivative.

    loss(w, x, y) = sum(w * x .- y)
    val, dw, dx, dy = xgrad(loss; w=rand(2,3), x=rand(3,4), y=rand(2))

`xgrad` also accepts context `ctx::Dict{}` and cache `mem::Dict{Any,Any}`.

See also: `xdiff`.
"""
function xgrad(f::Function; ctx=Dict(), mem=Dict(), inputs...)
    vals = [v for (k, v) in inputs]
    types = [typeof(v) for v in vals]
    sizes = [getsize(v) for v in vals]
    key = (f, types)
    if haskey(DERIV_CACHE, key)
        df, old_sizes = DERIV_CACHE[key]
        if sizes != old_sizes
            # new input sizes - recompile and clean up buffers
            # println("recompiling for new sizes and cleaning up memory")
            df = xdiff(f; ctx=copy(ctx), inputs...)
            DERIV_CACHE[key] = (df, sizes)
            for k in keys(mem)
                delete!(mem, k)
            end
        end
    else
        # println("compiling derivative")
        # if derivative function isn't compiled yet, do it
        # use copy of context in order not to pollute the passed one
        df = xdiff(f; ctx=copy(ctx), inputs...)
        DERIV_CACHE[key] = (df, sizes)
    end
    dvals = Base.invokelatest(df, vals..., mem)
    return dvals
end



function _kgrad(f::Function, args...; kwargs...)
    vnames, _ = funexpr(f, map(typeof, args))
    inputs = [n => v for (n, v) in zip(vnames, args)]
    res = xgrad(f; inputs...)
    return res[2]  # derivative of the first argument
end

"""
    kgrad(f::Function)

Experimental: derivatives in the same form as used in AutoGrad/Knet.

"""
function kgrad(f::Function)
    # TODO: add kwargs & integrate mem
    (args...) -> _kgrad(f, args...)
end
