function addentry(I, J, V, i, j, v)
	push!(I, i)
	push!(J, j)
	push!(V, v)
end

function adjointsparsematrix(ex::Expr, vars, solutionsymbol)
	if ex.head == :call && (string(ex.args[1]) == "LinearAdjoints.addentry" || string(ex.args[1]) == "addentry")
		tv, tvars = transformrefs(ex.args[end], vars)
		tvars = unique([tvars; vars])
		dtv_dvars = Calculus.differentiate(tv, tvars)
		code = quote end
		for i = 1:length(tvars)
			thisex = deepcopy(ex)
			thisex.args[end] = untransformrefs(dtv_dvars[i])
			if thisex.args[end] != :(0)#don't add unnecessary zeros
				thisex.args[2] = specialsymbolI
				thisex.args[3] = specialsymbolJ
				thisex.args[4] = specialsymbolV
				thisex.args[end] = :(($(thisex.args[end])) * $solutionsymbol[$(thisex.args[6])])
				thisex.args[6] = thisex.args[5]#the row gives the equation in the A matrix, but the column gives the equation in A_px
				splitstring = split(string(tvars[i]), specialrefstring)
				thisvarname = splitstring[1]
				thisvar = Symbol(thisvarname)
				indices = Array{Any}(undef, length(splitstring) - 1)
				for j = 2:length(splitstring)
					indices[j - 1] = MetaProgTools.replacesymbol(Meta.parse(string("throwaway[", splitstring[j], "]")).args[2], :end, :(size($thisvar, $(j - 1))))#this throwaway[...] business is needed because parse("end") gives an error
				end
				thisex.args[5] = :(getlinearindex($(Val{thisvar}), $(indices...)))
				push!(code.args, thisex)
			end
		end
		return code
	elseif ex.head == :return
		numrowsexp = Expr(:call, :+, 0)
		for var in vars
			push!(numrowsexp.args, :(length($var)))
		end
		return :(return SparseArrays.sparse($specialsymbolI, $specialsymbolJ, $specialsymbolV, $numrowsexp, length($solutionsymbol)))
	else
		return Expr(ex.head, map(x->adjointsparsematrix(x, vars, solutionsymbol), ex.args)...)
	end
end

function adjointsparsematrix(x, vars, solutionsymbol)
	return x
end

#the row of the A_px gives the parameter, the column gives the equation
macro assemblesparsematrix(vartuple, solutionsymbol, funcdef)
	local vars::Array{Symbol, 1}
	if isa(vartuple, Symbol)
		vars = Symbol[vartuple]
	else
		vars = map(x->x, vartuple.args)#get it to give us an array of symbols
	end
	f_pxdef = deepcopy(funcdef)
	f_pxdeclaration = f_pxdef.args[1]
	f_pxdeclaration.args[1] = Symbol(string(f_pxdef.args[1].args[1], "_px"))
	f_pxdeclaration.args = [f_pxdef.args[1].args[1], solutionsymbol, f_pxdef.args[1].args[2:end]...]
	f_pxdef.args[1] = f_pxdeclaration
	f_pxbody = f_pxdef.args[2]
	f_pxbody = adjointsparsematrix(f_pxbody, vars, solutionsymbol)
	gli = writegetlinearindex(vars)
	prepend!(f_pxbody.args, [gli])
	prepend!(f_pxbody.args, [:($specialsymbolI = Int[]; $specialsymbolJ = Int[]; $specialsymbolV = Float64[];)])
	f_pxdef.args[2] = f_pxbody
	q = quote
		$(esc(funcdef))
		$(esc(f_pxdef))
	end
	return q
end
