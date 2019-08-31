__precompile__()

"""
MADS: Model Analysis & Decision Support in Julia (Mads.jl v1.0) 2016

http://mads.lanl.gov
http://madsjulia.lanl.gov
http://gitlab.com/mads/Mads.jl

Licensing: GPLv3: http://www.gnu.org/licenses/gpl-3.0.html

Copyright 2016.  Los Alamos National Security, LLC.  All rights reserved.

This material was produced under U.S. Government contract DE-AC52-06NA25396 for
Los Alamos National Laboratory, which is operated by Los Alamos National Security, LLC for
the U.S. Department of Energy. The Government is granted for itself and others acting on its
behalf a paid-up, nonexclusive, irrevocable worldwide license in this material to reproduce,
prepare derivative works, and perform publicly and display publicly. Beginning five (5) years after
--------------- November 17, 2015, ----------------------------------------------------------------
subject to additional five-year worldwide renewals, the Government is granted for itself and
others acting on its behalf a paid-up, nonexclusive, irrevocable worldwide license in this
material to reproduce, prepare derivative works, distribute copies to the public, perform
publicly and display publicly, and to permit others to do so.

NEITHER THE UNITED STATES NOR THE UNITED STATES DEPARTMENT OF ENERGY, NOR LOS ALAMOS NATIONAL SECURITY, LLC,
NOR ANY OF THEIR EMPLOYEES, MAKES ANY WARRANTY, EXPRESS OR IMPLIED, OR ASSUMES ANY LEGAL LIABILITY OR
RESPONSIBILITY FOR THE ACCURACY, COMPLETENESS, OR USEFULNESS OF ANY INFORMATION, APPARATUS, PRODUCT, OR
PROCESS DISCLOSED, OR REPRESENTS THAT ITS USE WOULD NOT INFRINGE PRIVATELY OWNED RIGHTS.

LA-CC-15-080; Copyright Number Assigned: C16008
"""
module MetaProgTools

function getargumentsymbols(funcdef)
	return map(x->isa(x, Symbol) ? x : x.args[1], funcdef.args[1].args[2:end])
end

function getfunctionsymbol(funcdef)
	return funcdef.args[1].args[1]
end

"Get symbols"
function getsymbols(needle::Number)
	return Set{Symbol}()
end

function getsymbols(needle::Symbol)
	return Set{Symbol}([needle])
end

function getsymbols(haystack::Expr)
	symbols = Set{Symbol}()
	if typeof(haystack.head) == Expr
		union!(symbols, getsymbols(haystack.head))
	elseif typeof(haystack.head) == Symbol
		union!(symbols, [haystack.head])
	end
	for i = 1:length(haystack.args)
		if typeof(haystack.args[i]) == Expr
			union!(symbols, getsymbols(haystack.args[i]))
		elseif typeof(haystack.args[i]) == Symbol
			union!(symbols, [haystack.args[i]])
		end
	end
	return symbols
end

"Populate Expression"
function populateexpression(haystack::Symbol, vals::AbstractDict)
	if haskey(vals, string(haystack))
		return :($(vals[string(haystack)]))
	end
end

function populateexpression(haystack::Expr, vals::AbstractDict)
	newhaystack = deepcopy(haystack)
	populateexpression!(newhaystack, vals)
	return newhaystack
end

function populateexpression!(haystack::Expr, vals::AbstractDict)
	if typeof(haystack.head) == Expr
		populateexpression!(haystack.head, vals)
	elseif typeof(haystack.head) == Symbol
		if haskey(vals, string(haystack.head))
			haystack.head = vals[string(haystack.head)]
		end
	end
	for i = 1:length(haystack.args)
		if typeof(haystack.args[i]) == Expr
			populateexpression!(haystack.args[i], vals)
		elseif typeof(haystack.args[i]) == Symbol
			if haskey(vals, string(haystack.args[i]))
				haystack.args[i] = vals[string(haystack.args[i])]
			end
		end
	end
end

"Replace Symbol"
function replacesymbol(haystack::Symbol, needle::Symbol, replacement::Any)
	if haystack == needle
		return replacement
	else
		return haystack
	end
end

function replacesymbol(haystack::Expr, needle::Symbol, replacement::Any)
	newhaystack = deepcopy(haystack)
	replacesymbol!(newhaystack, needle, replacement)
	return newhaystack
end

function replacesymbol(haystack::Number, needle::Symbol, replacement::Any)
	return haystack
end

function replacesymbol!(haystack::Expr, needle::Symbol, replacement::Any)
	if typeof(haystack.head) == Expr
		replacesymbol!(haystack.head, needle, replacement)
	elseif haystack.head == needle
		haystack.head = replacement
	end
	for i = 1:length(haystack.args)
		if typeof(haystack.args[i]) == Expr
			replacesymbol!(haystack.args[i], needle, replacement)
		elseif haystack.args[i] == needle
			haystack.args[i] = replacement
		end
	end
	return haystack
end

"Find a needle in a haystack"
function in(needle::Any, haystack::Expr)
	if needle == haystack.head
		return true
	elseif typeof(haystack.head) == Expr
		if in(needle, haystack.head)
			return true
		end
	end
	for i = 1:length(haystack.args)
		if needle == haystack.args[i]
			return true
		elseif typeof(haystack.args[i]) == Expr
			if in(needle, haystack.args[i])
				return true
			end
		end
	end
	return false
end

end
