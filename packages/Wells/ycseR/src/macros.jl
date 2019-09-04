macro timedep(timesymbol, ratesymbol, funcdef)
	qmsymbol = ratesymbol
	qprevsymbol = gensym()
	ddsymbol = gensym()
	isymbol = gensym()
	argsymbols = MetaProgTools.getargumentsymbols(funcdef)
	funcname = MetaProgTools.getfunctionsymbol(funcdef)
	timedepfuncdef = deepcopy(funcdef)
	for i = 1:length(argsymbols)
		if argsymbols[i] == ratesymbol
			timedepfuncdef.args[1].args[i + 1] = :($qmsymbol::Matrix)
		end
	end
	innerloopargs = Array{Any}(undef, length(argsymbols))
	for i = 1:length(argsymbols)
		if argsymbols[i] == ratesymbol
			innerloopargs[i] = :($qmsymbol[$isymbol, 2] - $qprevsymbol)
		elseif argsymbols[i] == timesymbol
			innerloopargs[i] = :($timesymbol - $qmsymbol[$isymbol, 1])
		else
			innerloopargs[i] = argsymbols[i]
		end
	end
	timedepfuncdef.args[2] = quote
		if $timesymbol <= 0 return 0. end
		$ddsymbol = 0.
		$qprevsymbol = 0.
		$isymbol = 1
		while $isymbol <= size($qmsymbol, 1) && $timesymbol > $qmsymbol[$isymbol, 1]
			$ddsymbol += $funcname($(innerloopargs...))
			$qprevsymbol = $qmsymbol[$isymbol, 2]
			$isymbol += 1
		end
		return $ddsymbol
	end
	code = quote
		$(esc(funcdef))
		$(esc(timedepfuncdef))
	end
	return code
end
