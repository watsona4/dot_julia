function Base.show(io::IO, obj::RBE)
    println(io, "Bioequivalence Linear Mixed Effect Model")
    println(io, "")
    println(io, "REML: ", round(obj.reml, sigdigits=6))
    println(io, "")
    coef  = coefnames(obj.model);
    rcoef = coefnames(obj.rmodel);
    pm = Array{Any,2}(undef, length(coef)+1, 5);
    pm[1,1] = "Level"; pm[1,2] = "Value"; pm[1,3] = "SE"; pm[1,4] = "DF"; pm[1,5] = "F";

    for i = 1:length(coef)
        pm[i+1,1] = coef[i]
        pm[i+1,2] = obj.β[i];
        pm[i+1,3] = obj.se[i];
        pm[i+1,4] = obj.df[i];
        pm[i+1,5] = obj.f[i];
    end

    #
    for r = 1:size(pm)[1]
        for c = 1:size(pm)[2]
            if isa(pm[r,c], Float64) pm[r,c] = round(pm[r,c], sigdigits=6) end
        end
    end
    #─┼┴┬│
    pm    = string.(pm)
    len   = Array{Int,1}(undef, 0)
    vch   = Array{Vector{Char},1}(undef, 0)
    line  = ""
    #Line
    for c = 1:size(pm)[2]
        ml = maximum(length.(pm[:,c]))
        push!(len, ml)
        ch = Vector{Char}(undef, ml+2)
        ch .= '─'
        line *= String(ch)
    end
    #
    println(io, line)
    #Head
    for c = 1:size(pm)[2]
        print(io, pm[1,c])
        ch  = Vector{Char}(undef, len[c]-length(pm[1,c]))
        ch .= ' '
        print(io, String(ch))
        print(io, "  ")
    end
    println(io, "")
    #
    #Line
    println(io, line)
    #
    #Body
    for r = 2:size(pm)[1]
        for c = 1:size(pm)[2]
            print(io, pm[r,c])
            ch  = Vector{Char}(undef, len[c]-length(pm[r,c]))
            ch .= ' '
            print(io, String(ch))
            print(io, "  ")
        end
        println(io, "")
    end
    #
    #line
    println(io, line)
    #
    println(io, "Intra-individual variation:")
    println(io, rcoef[1], "  ", round(obj.θ[1], sigdigits=6), "   CVᵂ: ", round(geocv(obj.θ[1]), sigdigits=6))
    println(io, rcoef[2], "  ", round(obj.θ[2], sigdigits=6), "   CVᵂ: ", round(geocv(obj.θ[2]), sigdigits=6))
    println(io, "")
    println(io, "Inter-individual variation:")
    println(io, rcoef[1], "  ", round(obj.θ[3], sigdigits=6))
    println(io, rcoef[2], "  ", round(obj.θ[4], sigdigits=6))
    println(io,   "Cov:", "  ", round(sqrt(obj.θ[4]*obj.θ[3])*obj.θ[5], sigdigits=6))
    println(io, line)
    println(io, "Confidence intervals(90%):")
    println(io, "")
    ci = confint(obj, 0.1, expci = true, inv = false)
    println(io, rcoef[1], " / ", rcoef[2])
    println(io, round(ci[end][1]*100, digits=4), " - ", round(ci[end][2]*100, digits=4), " (%)")
    println(io, "")
    ci = confint(obj, 0.1, expci = true, inv = true)
    println(io, rcoef[2], " / ", rcoef[1])
    println(io, round(ci[end][1]*100, digits=4), " - ", round(ci[end][2]*100, digits=4), " (%)")

end

function geocv(var)
    return sqrt(exp(var)-1.0)
end
