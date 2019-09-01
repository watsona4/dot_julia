__precompile__()

module DevIL

import Libdl

const libIL = Libdl.find_library(["libIL", "DevIL"],
                                 ["/usr/lib/x86_64-linux-gnu", joinpath(dirname(pathof(DevIL)), "..", "deps", string(Sys.ARCH))])

# Stolen from getCFun macro
macro ilFunc(cFun)
    arguments = map(function (arg)
                        if isa(arg, Symbol)
                            arg = Expr(:(::), arg)
                        end
                        return arg
                    end, cFun.args[1].args[2:end])

    # Get info out of arguments of `cFun`
    argumentNames = map(arg->arg.args[1], arguments)
    returnType    = cFun.args[2]
    inputTypes    = map(arg->arg.args[2], arguments)

    # Construct the result.
	cName     = cFun.args[1].args[1]
	cSym      = Expr(:quote, cName)
	symAndLib = :($cSym, $libIL)
#=
    body       = Expr(:ccall, symAndLib, returnType, Expr(:tuple, inputTypes...), argumentNames...)
    func       = Expr(:function, Expr(:call, cName, argumentNames...), body)
	exportExpr = Expr(:export, cName)
	ret        = Expr(:block, func, exportExpr)
=#
    ret = quote
        $cName($(argumentNames...)) = ccall($symAndLib, $returnType, ($(inputTypes...),), $(argumentNames...))
        export $cName
    end

    return esc(ret)
end

macro ilConst(assignment)
	constExpr  = Expr(:const, assignment)
	exportExpr = Expr(:export, assignment.args[1])
	ret        = Expr(:block, constExpr, exportExpr)

	return esc(ret)
end

include("IL.jl")

end # module
