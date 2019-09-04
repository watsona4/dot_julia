#   This file is part of Wilkinson.jl. It is licensed under the MIT license
#   Copyright (C) 2018 Michael Reed

struct PolynomialAnalysis <: NumericalData
    expr::Any
    set::AbstractRange
    val::Tuple
    stj::Tuple
    smp::Number
    function PolynomialAnalysis(expr,T::Tuple=(Float64,),set=nothing,ω=nothing,stj=nothing;logi=log,expi=exp)
        val = SyntaxTree.exprval(expr)
        set == nothing && (set = floatset(T[end],3000;scale=logi))
        stj == nothing && (stj = stieltjes(set,expr,T...;logi=logi,expi=expi))
        smp = simpson(set,stj[1],ω == nothing ? Ω(stj[1]) : ω)
        return new(expr,set,val,stj,smp)
    end
end

function print(io::IO,x::PolynomialAnalysis)
    display(RExpr(x.expr)); println()
    println(io,"characteristic values (c,σ,s,p): $(x.val[2:5])")
    println(io,"expression value ν: $(x.val[1])")
    println(io,"predicted error bound ϕ: $(x.smp)")
    #println(io,"renormalized error bound: $(geonorm(x.smp))")
    println(io,"bytes allocated: $(x.stj[2]/length(x.set))")
end

show(io::IO, ::MIME"text/plain", x::PolynomialAnalysis) = print(io,x)

struct PolynomialComparison <: NumericalData
    expr::Any
    set::AbstractRange
    results::Array{PolynomialAnalysis,1}
    extra::Bool
    rxtra::Bool
    ω::Number
    exact::Array
    integral::Array
    log::Function
    exp::Function
    typ::DataType
    function PolynomialComparison(j,T::DataType=Float64,N::Int=3000;logi=log,expi=exp,round=false)
        set = floatset(T,N;scale=logi)
        rr = Reduce.Rational()
        Reduce.Rational(false)
        #j = squash(expr)
        exprs = Array{Any,1}(undef,5)
        rof = round ? [:rounded] : []
        exprs[1] = j |> optimal             #ea
        exprs[2] = rcall(j,:expand,rof...)  #ee
        exprs[3] = rcall(j,:horner,rof...)  #eh
        exprs[4] = rcall(j,:factor)         #ef
        exprs[5] = rcall(j,:factor,:rounded)#er
        Reduce.Rational(rr)
        extra = (j ≠ exprs[2]) & (j ≠ exprs[3]) & (j ≠ exprs[4])
        rxtra = exprs[4] ≠ exprs[5]
        !rxtra && deleteat!(exprs,5)
        extra && push!(exprs,j)
        stj = [stieltjes(set,expr,T;logi=logi,expi=expi) for expr ∈ exprs[2:end]]
        ω = min(Ω.([stj[1][1],stj[2][1],stj[3][1]])...)
        res=[PolynomialAnalysis(exprs[k+1],(T,),set,ω,stj[k];logi=logi,expi=expi) for k ∈ 1:length(stj)]
        pushfirst!(res,PolynomialAnalysis(exprs[1],(BigFloat,T),set,ω;logi=logi,expi=expi))
        EE = exacterr(set,exprs,T,rxtra,extra;logi=logi,expi=expi)
        s = [simpson(set,r,ω) for r ∈ EE]
        #(res[2], res[3], res[4]) = (res[2]-res[1], res[3]-res[1], res[4]-res[1])
        #(EE[2], EE[3], EE[4]) = (EE[2]-res[1], EE[3]-res[1], EE[4]-res[1])
        return new(j,set,res,extra,rxtra,ω,EE,s,logi,expi,T)
    end
end

function print(io::IO, x::PolynomialComparison)
    display(RExpr(x.expr)); println()
    n = ["e","h","f"]
    x.rxtra && push!(n,"r")
    x.extra && push!(n,"o")
    L = 1:length(n)
    println(io,"characteristic values (c,σ,s,p):")
    [println(io,"$(n[k]) = ",x.results[k+1].val[2:5]) for k ∈ L]
    println(io,"expression value ν:")
    [println(io,"$(n[k]) = $(x.results[k+1].val[1])") for k ∈ L]
    println(io,"predicted error bound Φ:")
    [println(io,"$(n[k]) = $(x.results[k+1].smp/x.results[1].smp)") for k ∈ L]
    gsa = geonorm(x.results[1].smp)
    #println(io,"renormalized error bound:")
    #[println(io,"$(n[k]) = $(geonorm(x.results[k+1].smp)/gsa)") for k ∈ L]
    #println(io,"actual error bound:")
    #[println(io,"$(n[k]) = $(x.integral[k]/x.results[1].smp)") for k ∈ L]
    println(io,"bytes allocated:")
    N = length(x.set)
    [println(io,"$(n[k]) = $(x.results[k+1].stj[2]/N)") for k ∈ L]
    #println(io,(x.results[1].smp, x.results[1].stj[2]/length(x.set)))
end

show(io::IO, ::MIME"text/plain", x::PolynomialComparison) = print(io,x)

function plot(x::PolynomialComparison)
    #(fe, fh, ff) = (fe-fa, fh-fa, ff-fa)
    #(ts, hs, fs) = (ts-fa, hs-fa, fs-fa)
    sc = collect(x.set)
    figure()
    MS=1
    x.rxtra && plot(sc,x.results[5].stj[1]-x.results[1].stj[1],c="y",lw=0.7)
    plot(sc,x.results[2].stj[1]-x.results[1].stj[1],c="r",lw=0.7)
    plot(sc,x.results[3].stj[1]-x.results[1].stj[1],c="b",lw=0.7)
    plot(sc,x.results[4].stj[1]-x.results[1].stj[1],c="g",lw=0.7)
    leg = ["expand (bound)","horner (bound)","factor (bound)"]
    if x.rxtra
        plot(sc,x.exact[4]-x.results[1].stj[1],c="y",marker="o",ms=MS,ls="--",lw=0.7)
        pushfirst!(leg,"approx (bound)")
        push!(leg,"approx (actual)")
    end
    if x.extra
        plot(sc,x.results[end].stj[1]-x.results[1].stj[1],c="k",lw=0.7)
        plot(sc,x.exact[end]-x.results[1].stj[1],c="k",marker="o",ms=MS,ls="--",lw=0.7)
        insert!(leg,1+Int(x.rxtra),"orignal (bound)")
        push!(leg,"original (actual)")
    end
    push!(leg,"expand (actual)","horner (actual)","factor (actual)")
    plot(sc,x.exact[1]-x.results[1].stj[1],c="r",marker="o",ms=MS,ls="--",lw=0.7)
    plot(sc,x.exact[2]-x.results[1].stj[1],c="b",marker="o",ms=MS,ls="--",lw=0.7)
    plot(sc,x.exact[3]-x.results[1].stj[1],c="g",marker="o",ms=MS,ls="--",lw=0.7)
    legend(leg)
    xlabel("\$\\log|x|,\\,\\Delta=$(@sprintf("%.2e",Float64(x.set.step)))\$")
    ylabel("\$\\log\\,\\frac{|[alg(f)](x)-f(x)|}{\\delta(f,x,2^{$(Int(log(2,eps(BigFloat))))})},\\,\\log\\,\\frac{\\delta(f,x,2^{$(Int(log(2,eps(x.typ))))})}{\\delta(f,x,2^{$(Int(log(2,eps(BigFloat))))})}\$")
    #=figure()
    (x.results[2].stj[1],x.results[3].stj[1],x.results[4].stj[1]) = (x.results[2].stj[1]-x.results[1].stj[1], x.results[3].stj[1]-x.results[1].stj[1], x.results[4].stj[1]-x.results[1].stj[1])
    plot(sc,x.results[2].stj[1],sc,x.results[3].stj[1],sc,x.results[4].stj[1])
    (x.exact[1],x.exact[2],x.exact[3]) = (x.exact[1]-x.results[1].stj[1], x.exact[2]-x.results[1].stj[1], x.exact[3]-x.results[1].stj[1])
    plot(sc,x.exact[1],sc,x.exact[2],sc,x.exact[3])
    legend(["expand64","horner64","factor64","expand","horner","factor"])=#
    tight_layout()
    return x
end

function testpoly(expr,T::DataType)
    ee = expand(expr)
    eh = horner(expr)
    ef = factor(eh)
    ehv = SyntaxTree.exprval(eh)
    ehb = errval(eh,T)
    eev = SyntaxTree.exprval(ee)
    eeb = errval(ee,T)
    fact = false
    agree = false
    conj = false
    if eh == ef
        fact = false
        agree = true
        conj = (ehv ≤ eev) && (ehb[1] < eeb[1] || ehb[2] ≤ eeb[2])
    else
        fact = true
        efv = SyntaxTree.exprval(ef)
        efb = errval(ef,T)
        println("$eev\n$ehv\n$efv")
        println("$eeb\n$ehb\n$efb")
        agree = (ehv ≤ efv) == (ehb[1] < efb[1] || ehb[2] ≤ efb[2])
        conj = ((ehv ≤ eev) && (ehb[1] < eeb[1] || ehb[2] ≤ eeb[2])) ||
            ((efv ≤ eev) && (efb[1] < eeb[1] || efb[2] ≤ eeb[2]))
    end
    return (agree,fact,conj)
end

function tests(d::Integer,n::Integer,T::DataType=Float64;apply::Function=polyfactors)
    rr = Reduce.Rational()
    Reduce.Rational(false)
    agree = 0
    fact = 0
    conj = 0
    res = (0,0,0)
    for k ∈ 1:n
        res = Int.(testpoly(apply(:x,rand(d)),T))
        agree += res[1]
        fact += res[2]
        conj += res[3]
    end
    Reduce.Rational(rr)
    println("agree = $agree\nfactorizable = $fact")
    return (agree//n, fact//n, conj//n)
end
