using Knet
using AutoGrad
import AutoGrad: gcheck
using Taarruz
using Test


@testset "mnist" begin
    include(Knet.dir("data", "mnist.jl"))
    global dtrn, dtst = mnistdata()
    global atype = dtrn.xtype
    @test dtrn.length == 60000
    @test dtst.length == 10000
    @test dtrn.xsize[1:end-1] == dtst.xsize[1:end-1] == (28, 28, 1)
    @test length(dtrn) == div(dtrn.length, dtrn.batchsize)
    @test length(dtst) == div(dtst.length, dtst.batchsize)
end


@testset "linear" begin
    global linear = Taarruz.Chain(
        (Taarruz.Dense(784,10,identity; atype=atype), ))
    x, y = first(dtst); x = param(x)
    @test gcheck(linear, x, y; atol=0.05)
    @test typeof(linear) == Taarruz.Chain
    @test size(linear(x)) == (10, dtst.batchsize)
    @test accuracy(linear, dtst) < 0.50
    progress!(adam(linear, dtrn))
    global tstacc = accuracy(linear, dtst)
    @test tstacc > 0.75
end


@testset "lenet" begin
    lenet = Lenet(; atype=atype)
    x, y = first(dtst); x = param(x)
    @test gcheck(lenet, x, y; atol=0.05)
    @test typeof(lenet) == Taarruz.Chain
    @test size(lenet(x)) == (10, dtst.batchsize)
end


@testset "fgsm" begin
    x, y = first(dtst)

    ϵ = 0.2
    x̂s = FGSM(linear, ϵ, x, y)
    x̂ = x̂s[1]
    @test length(x̂s) == 1
    @test size(x̂) == size(x)
    @test typeof(x̂) == typeof(x)
    @test maximum(x̂) == 1
    @test minimum(x̂) == 0

    example(x,y,ϵ=0.2,f=linear) = FGSM(f,ϵ,x,y)[1]
    abuse(x,y,ϵ=0.2,f=linear; o...) = accuracy(f(example(x,y)), y; o...)
    abuse(d::Knet.Data, ϵ=0.2, f=linear) = sum(abuse(x,y,ϵ,f; average=false) for (x,y) in d) / d.length

    fgsmacc = abuse(dtst)
    @test tstacc - fgsmacc > 0.2

    fgsmacc = map(ϵi->abuse(x,y,ϵi), 0.1:0.05:0.5)
    @test issorted(fgsmacc, rev=true)

    ϵ = 0.2
    xp = param(x)
    J = @diff linear(xp, y)
    ∇x = grad(J, xp)
    x̂ = min.(1, max.(0, x + ϵ * sign.(∇x)))
    @test length(Taarruz.∇xJ(linear, x, y)) == 1
    @test ∇x ≈ Taarruz.∇xJ(linear, x, y)[1]
    @test x̂ ≈ FGSM(x, ∇x, ϵ)
    @test x̂ ≈ FGSM(linear, ϵ, x, y)[1]
end
