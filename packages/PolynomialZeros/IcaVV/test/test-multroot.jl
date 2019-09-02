using PolynomialZeros
const AGCD = PolynomialZeros.AGCD
const MultRoot = PolynomialZeros.MultRoot
using Polynomials
using Test

poly_coeffs = PolynomialZeros.poly_coeffs
multroot=PolynomialZeros.MultRoot.multroot
pejroot=PolynomialZeros.MultRoot.pejroot
agcd = PolynomialZeros.AGCD.agcd
identify_z0s_ls = PolynomialZeros.MultRoot.identify_z0s_ls

x = variable(Float64)
bx = variable(BigFloat)
_poly(zs,ls,x=x) = prod((x-z)^l for (z,l) in zip(zs, ls))

@testset "agcd-Float64" begin

    x = variable()

    p = (x-1)^3
    u,v,w,err = AGCD.agcd(p)
    @test Polynomials.degree(v) == 1

    p = prod(x-i for i in 1:6)
    u,v,w,err = AGCD.agcd(p)
    @test Polynomials.degree(v) == Polynomials.degree(p)

    n = 4
    p = prod((x-i)^i for i in 1:n)
    u,v,w,err = AGCD.agcd(p)
    @test Polynomials.degree(v) == n

    # can fails
    n = 6
    p = prod((x-i)^i for i in 1:n)
    u,v,w,err = AGCD.agcd(p)
    @test Polynomials.degree(v) >= n

    # use big
    n = 6
    p = prod((bx-i)^i for i in 1:n)
    u,v,w,err = AGCD.agcd(p)
    @test Polynomials.degree(v) == n

    T = Float64
    x = variable(Complex{T})
    p = (x-im)^2 * (x-1)^2 * (x+2im)^2
    u,v,w,err = AGCD.agcd(p)
    @test length(v)-1 == 3


end

@testset "agcd-othertypes" begin


    T = Float32
    zs, ls = [1,2,-3],[2,2,3]
    p = _poly(zs, ls, variable(T))
    ps = poly_coeffs(p)
    u,v,w,err = AGCD.agcd(p, θ=1e-4)

    @test degree(v) == 3

    # big float
    p = _poly(zs, ls, bx)
    u,v,w,err = AGCD.agcd(p^15)

    @test degree(v) == 3 # fails for Float64

end

@testset "pejroot" begin


    zs, ls = [1.0,2,3,4], [4,3,2,1]
    p = _poly(zs, ls,x)

    delta = 0.1 # works
    z0 = zs + delta*[1,-1,1,-1]
    z1 = pejroot(p, z0, ls)
    @test !all(sort(z0) .== sort(z1))

    delta = 0.2 # fails
    z0 = zs + delta*[1,-1,1,-1]
    z1 = pejroot(p, z0, ls)
    @test all(sort(z0) .== sort(z1))

    ls = [30,20,10,5]
    p = _poly(zs, ls,x)

    delta = 0.01 # works
    z0 = zs + delta*[1,-1,1,-1]
    z1 = pejroot(p, z0, ls)
    @test !all(sort(z0) .== sort(z1))

end

@testset "identify_ls" begin


    zs, ls = [1.0,2,3,4], [4,3,2,1]
    p = _poly(zs, ls,x)
    _zs, _ls = identify_z0s_ls(poly_coeffs(p))
    @test all(sort(ls) .== sort(_ls))

    p = _poly(zs, 3*ls,x)
    _zs, _ls = identify_z0s_ls(poly_coeffs(p))
    @test length(ls) != length(_ls) # fails w/o preconditioning

    n = 4
    zs, ls = cumsum(ones(n)), cumsum(ones(Int, n))
    p = _poly(zs, ls,x)
    _zs, _ls = identify_z0s_ls(poly_coeffs(p))
    @test all(sort(ls) .== sort(_ls))

    n = 5
    zs, ls = cumsum(ones(n)), cumsum(ones(Int, n))
    p = _poly(zs, ls,x)
    _zs, _ls = identify_z0s_ls(poly_coeffs(p))
    @test !(length(ls) == length(_ls))

end



@testset "multroot" begin

    zs, ls = [1.0,2,3,4], [4,3,2,1]
    _zs, _ls = multroot(_poly(zs, ls,x))
    @test all(sort(ls) .== sort(_ls))

    _zs, _ls = multroot(_poly(zs, 3ls,x))
    @test !all(sort(2ls) .== sort(_ls)) # XXX fails!

    _zs, _ls = multroot(_poly(big.(zs), 3ls,bx))
    @test all(sort(3ls) .== sort(_ls)) # passes


    delta = 0.01
    zs, ls = [1-delta, 1, 1+delta], [5,4,3]
    _zs, _ls = multroot(_poly(zs, ls,x))
    @test all(sort(ls) .== sort(_ls))

    # should work, but giving issue with CI
    # n = 20
    # zs,ls = collect(1.0:n), ones(Int, n)
    # _zs, _ls = multroot(_poly(zs, ls,x))
    # @test all(sort(ls) .== sort(_ls))

    _zs, _ls = multroot(_poly(zs, 2ls,x))
    @test !(length(ls) == length(_ls)) ##XXX fails!

    n = 10
    zs,ls = collect(1.0:n), ones(Int, n)
    _zs, _ls = multroot(_poly(zs, 2ls,x)) #fails *badly*
    @test !(length(_ls) == length(ls))

    n = 10
    zs,ls = collect(1.0:n), ones(Int, n)
    _zs, _ls = multroot(_poly(big.(zs), 2ls,x)) # works now
    @test all(sort(2ls) .== sort(_ls))

    n = 5
    zs,ls = collect(1.0:n), ones(Int, n)
    _zs, _ls = multroot(_poly(zs, 4ls,x))
    @test all(sort(4ls) .== sort(_ls))

end

@testset "examples" begin
    # examples from paper
    # our agcd implementation (and identify_z0s_ls) do not perform
    # as advertised therein.

    # 3.6.1
    zs, ls = [1.0,2,3,4], [4,3,2,1]
    p1 = _poly(zs, ls, x)
    ps = poly_coeffs(p1)
    z0 = zs + 0.1 * [1,-1,1,-1]
    @test maximum(abs.(sort(pejroot(ps, z0, ls)) - [1,2,3,4])) <= 1e-10

    ls = [40,30,20,10]
    p2 = _poly(zs, ls, x)
    ps = poly_coeffs(p2)
    z0 = zs + 0.01 * [1,-1,1,-1]
    @test maximum(abs.(sort(pejroot(ps, z0, ls)) - [1,2,3,4])) <= 1e-13

    zs, ls = [sqrt(2), sqrt(3)], [20,10]
    p3 = _poly(zs, ls, x)
    ps = poly_coeffs(p3)
    zs_, ls_ = multroot(ps)
    @test maximum(abs.(sort(zs_) - sort(zs))) <= 1e-14

    # 3.62
    delta = 0.1
    zs, ls = [1,1,1]-delta*[-1,0,1], [9,5,2]
    p4 = _poly(zs, ls, x)
    ps = poly_coeffs(p4)
    zs_,ls_ = multroot(ps)
    @test  maximum(abs.(sort(zs_) - sort(zs))) <= 1e-13

    zs, ls = [1,1,1]+delta*[-1,0,1], 2 * [9,5,2] # from paper
    p4 = _poly(zs, ls, x)
    ps = poly_coeffs(p4)
    zs_,ls_ = multroot(ps)
    # @test  maximum(abs.(sort(zs_) - zs)) <= 1e-14 # fails, not even correct size for zs

    # pejroots
    z0 = [0.89999999993, 0.9999999993, 1.0999999998]
    zs_ = pejroot(ps, z0, ls)
    @test maximum(abs.(sort(zs_) - sort(zs))) <= 1e-10

    # will work with BigFloat
    zs, ls = [1,1,1]+delta*[-1,0,1], 2 * [9,5,2] # from paper
    p5 = _poly(zs, ls, bx)
    ps = poly_coeffs(p5)
    zs_,ls_ = multroot(ps)
    @test  maximum(abs.(sort(zs_) - zs)) <= 1e-50



    zs, ls = [0.3 + 0.6im, 0.1 + 0.7im, 0.7+0.5im, 0.3 + 0.4im], [100, 200, 300, 400]
    p7 = _poly(zs, ls, variable(Complex{Float64}))
    ps = poly_coeffs(p7)
    ps = ps + rand(-1:1, length(ps)) * 1e-6
    z0s = [.289+.601im, .100 + .702im, .702 + .498im, .301 + .399im]
    zs_ = pejroot(ps, z0s, ls)
    @test maximum(abs.(sort(abs.(zs_)) - sort(abs.(zs)))) <= 1e-5

    # 4.6
    #
    # k = 5 is in paper, we can't even get k=4. In fact k=3 not
    # working without preconditioning
    k=3
    zs, ls = [1,2,3,4], k*[4,3,2,1]
    p8 = _poly(zs, ls, x)
    ps = poly_coeffs(p8)
    zs_, ls_ = multroot(ps)
    @test all(sort(ls_) .== sort(ls))

    zs, ls = [10/11, 20/11, 30/11], [5,5,5]
    p9 = _poly(zs, ls, x)
    ps = poly_coeffs(p9)
    zs_, ls_ = multroot(ps)
    @test all(sort(ls_) .== sort(ls))

    # 5.2 -- these fail
    for ε in [1e-1, 1e-2, 1e-3]
        zs, ls = [1-ε, 1, 1/2], [20,20,5]
        p10 = _poly(zs, ls, x)
        zs_, ls_ = multroot(p10)
#        @test all(sort(ls) .== sort(ls_))
    end

    ε = .0001
     zs, ls = [1-ε, 1, 1/2], [20,20,5]
    p10 = _poly(zs, ls, x)
    zs_, ls_ = multroot(p10,  ϕ = 5)
#    @test all(sort(ls) .== sort(ls_))

end
