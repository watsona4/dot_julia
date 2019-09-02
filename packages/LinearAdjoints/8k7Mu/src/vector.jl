function adjointvector(ex::Expr, vars, vectorsymbol)
	if (ex.head == :(=) || ex.head == :+=) && isa(ex.args[1], Expr) && ex.args[1].head == :ref && ex.args[1].args[1] == vectorsymbol
		lhs, tvectorsymbol = transformrefs(ex.args[1], [vectorsymbol])
		splitstring = split(string(lhs), specialrefstring)
		vectorindexex = MetaProgTools.replacesymbol(Meta.parse(string("throwaway[", splitstring[2], "]")).args[2], :end, :(length($vectorsymbol)))#this throwaway[...] business is needed because parse("end") gives an error
		tv, tvars = transformrefs(ex.args[2], vars)
		tvars = unique([tvars; vars])
		dtv_dvars = Calculus.differentiate(tv, tvars)
		code = quote end
		for i = 1:length(tvars)
			thisex = deepcopy(ex)
			thisex.args[2] = untransformrefs(dtv_dvars[i])
			if thisex.args[2] != :(0)
				splitstring = split(string(tvars[i]), specialrefstring)
				thisvarname = splitstring[1]
				thisvar = Symbol(thisvarname)
				indices = Array{Any}(undef, length(splitstring) - 1)
				for j = 2:length(splitstring)
					indices[j - 1] = MetaProgTools.replacesymbol(Meta.parse(string("throwaway[", splitstring[j], "]")).args[2], :end, :(size($thisvar, $(j - 1))))#this throwaway[...] business is needed because parse("end") gives an error
				end
				paramindexex = :(getlinearindex($(Val{thisvar}), $(indices...)))
				push!(code.args, :(LinearAdjoints.addentry($specialsymbolI, $specialsymbolJ, $specialsymbolV, $paramindexex, $vectorindexex, $(thisex.args[2]))))
			end
		end
		return code
	elseif ex.head == :return
		numrowsexp = Expr(:call, :+, 0)
		for var in vars
			push!(numrowsexp.args, :(length($var)))
		end
		return :(return SparseArrays.sparse($specialsymbolI, $specialsymbolJ, $specialsymbolV, $numrowsexp, length($vectorsymbol)))
	else
		return Expr(ex.head, map(x->adjointvector(x, vars, vectorsymbol), ex.args)...)
	end
end

function adjointvector(x, vars, vectorysmbol)
	return x
end

macro assemblevector(vartuple, vectorsymbol, funcdef)
	local vars::Array{Symbol, 1}
	if isa(vartuple, Symbol)
		vars = Symbol[vartuple]
	else
		vars = map(x->x, vartuple.args)#get it to give us an array of symbols
	end
	f_pdef = deepcopy(funcdef)
	f_pdeclaration = f_pdef.args[1]
	f_pdeclaration.args[1] = Symbol(string(f_pdef.args[1].args[1], "_p"))
	f_pdef.args[1] = f_pdeclaration
	f_pbody = f_pdef.args[2]
	f_pbody = adjointvector(f_pbody, vars, vectorsymbol)
	gli = writegetlinearindex(vars)
	prepend!(f_pbody.args, [gli])
	prepend!(f_pbody.args, [:($specialsymbolI = Int[]; $specialsymbolJ = Int[]; $specialsymbolV = Float64[];)])
	f_pdef.args[2] = f_pbody
	q = quote
		$(esc(funcdef))
		$(esc(f_pdef))
	end
	return q
end
