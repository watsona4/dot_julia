import Calculus
import Calculus.differentiate

function differentiate(x::Symbol, syms::Array{Symbol, 1})
	return map(sym->differentiate(x, sym), syms)
end

function differentiate(x::Number, syms::Array{Symbol, 1})
	return map(sym->0., syms)
end

function differentiate(ex::Expr,wrt)
	if ex.head == :ref
		return 0
	elseif ex.head != :call
		error("Unrecognized expression $ex")
	end
	Calculus.simplify(differentiate(Calculus.SymbolParameter(ex.args[1]), ex.args[2:end], wrt))
end
