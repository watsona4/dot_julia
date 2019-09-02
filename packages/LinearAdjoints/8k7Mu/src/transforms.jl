const specialrefstring = "___laref___"

function transformrefs(ex::Expr, vars::Array{Symbol, 1})
	if ex.head == :ref
		if ex.args[1] in vars
			s = Symbol(string(ex.args[1], map(x->string(specialrefstring, x), ex.args[2:end])...))
			return s, Symbol[s]
		else
			return ex, Symbol[]
		end
	else
		x = map(arg->transformrefs(arg, vars), ex.args)
		transformedargs = map(x->x[1], x)
		syms = reduce((x, y)->unique([x; y]), map(x->x[2], x); init=Symbol[])
		return Expr(ex.head, transformedargs...), syms
	end
end

function transformrefs(x, vars::Array{Symbol, 1})
	return x, Symbol[]
end

function untransformrefs(x)
	return x
end

function untransformrefs(x::Expr)
	return Expr(x.head, map(untransformrefs, x.args)...)
end

function untransformrefs(x::Symbol)
	sx = string(x)
	if occursin(specialrefstring, sx)
		splitsx = split(sx, specialrefstring)
		return Meta.parse(string(splitsx[1], "[", join(splitsx[2:end], ", ")..., "]"))
	else
		return x
	end
end
