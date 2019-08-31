module ImportAll

macro importall(moduleIn, verbose=false)
    modName = @eval($(moduleIn))
    out = []
    for name in names(modName)
            symbolname = @eval $(name)
            expression = :(import $(moduleIn): $(name))
            push!(out, expression)
    end
	
    ret = Expr(:block,out...)
	return ret
end

export @importall

end
