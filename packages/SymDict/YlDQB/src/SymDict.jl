#==============================================================================#
# SymDict.jl
#
# Convenience functions for dictionaries with `Symbol` keys.
#
# Copyright Sam O'Connor 2015 - All rights reserved
#==============================================================================#


__precompile__()


module SymDict


export SymbolDict, StringDict, @SymDict, symboldict, stringdict



const SymbolDict = Dict{Symbol,Any}
const StringDict = Dict{String,Any}


symboldict(x) = symboldict(SymbolDict(x))


function symboldict(kv::Dict)
    d = SymbolDict()
    for (k,v) in kv
        d[Symbol(k)] = v
    end
    return d
end


function symboldict(;args...)
    d = SymbolDict()
    for (k,v) in args
        d[k] = v
    end
    return d
end


function stringdict(kv)
    d = StringDict()
    for (k,v) in kv
        d[string(k)] = v
    end
    return d
end


# SymDict from local variables and keyword arguments.
#
#   a = 1
#   b = 2
#   @SymDict(a,b,c=3,d=4)
#   Dict(:a=>1,:b=>2,:c=>3,:d=>4)
#
#   function f(a; args...)
#       b = 2
#       @SymDict(a, b, c=3, d=0, args...)
#   end
#   f(1, d=4)
#   Dict(:a=>1,:b=>2,:c=>3,:d=>4)

macro SymDict(args...)

    @assert !isa(args[1], Expr) || args[1].head != :tuple

    # Check for "args..." at end...
    extra = nothing
    if isa(args[end], Expr) && args[end].head == Symbol("...")
        extra = :(symboldict($(esc(args[end].args[1]))))
        args = args[1:end-1]
    end

    # Ensure that all args are keyword arg Exprs...
    new_args = []
    for a in args

        # Create assignment statement for key with no value...
        if !isa(a, Expr)
            a = :($a=$a)
        end
        # Convert key from string to Symbol if needed...
        if !isa(a.args[1], Symbol)
            a.args[1] = Symbol(a.args[1])
        end
        a.head = :kw
        a.args[2] = esc(a.args[2])
        push!(new_args, a)
    end

    if extra != nothing
        :(merge!(symboldict($(new_args...)), $extra))
    else
        :(symboldict($(new_args...)))
    end
end


end # module SymDict

#==============================================================================#
# End of file.
#==============================================================================#
