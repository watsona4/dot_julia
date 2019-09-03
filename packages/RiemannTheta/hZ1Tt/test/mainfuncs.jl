≈(a::Number,b::Number) = isapprox(a, b, rtol=1e-3, atol=1e-8)

# with small calculations, such that the finite_sum_small branch is used
@testset "values of riemanntheta (small)" begin

    # using the Wolfram example
    # https://reference.wolfram.com/language/ref/SiegelTheta.html

    Ω = [ im -0.5 ; -0.5 im ]
    zs = [ComplexF64[0.5, 0.]]

    res = riemanntheta(zs, Ω)

    @test real(res[1]) ≈ 1.00748
    @test imag(res[1]) ≈ 0.

    zs = [ ComplexF64[x, 2x] for x in -1:0.1:1 ]
    res = riemanntheta(zs, Ω, eps=1e-3)

    @test maximum(real, res) ≈ 1.165
    @test minimum(real, res) ≈ 0.901
    @test maximum(imag, res) ≈ 0.
    @test minimum(imag, res) ≈ 0.

    # using example in abelfunctions doc
    # https://github.com/abelfunctions/abelfunctions/blob/master/doc/GettingStarted.md

    Ω = [ -1.309017+0.951057im -0.809017+0.587785im ;
          -0.809017+0.587785im -1.000000+1.175571im ]
    z = [0.5, 0.5im]
    res = riemanntheta([z], Ω, eps=1e-3)

    @test real(res[1]) ≈ 1.11415
    @test imag(res[1]) ≈ 0.8824
end

# with larger calculations, such that the finite_sum_large branch is used
@testset "values of riemanntheta (large)" begin

    # using the Wolfram example
    # https://reference.wolfram.com/language/ref/SiegelTheta.html

    Ω = [ im -0.5 ; -0.5 im ]
    zs = fill(ComplexF64[0.5, 0.], 10000)

    res = riemanntheta(zs, Ω)

    @test real(res[1]) ≈ 1.00748
    @test imag(res[1]) ≈ 0.

    zs = repeat( [ ComplexF64[x, 2x] for x in -1:0.01:1 ], outer=100)
    res = riemanntheta(zs, Ω, eps=1e-3)

    @test maximum(real, res) ≈ 1.165
    @test minimum(real, res) ≈ 0.901
    @test maximum(imag, res) ≈ 0.
    @test minimum(imag, res) ≈ 0.

    # using example in abelfunctions doc
    # https://github.com/abelfunctions/abelfunctions/blob/master/doc/GettingStarted.md

    Ω = [ -1.309017+0.951057im -0.809017+0.587785im ;
          -0.809017+0.587785im -1.000000+1.175571im ]
    z = [0.5, 0.5im]
    res = riemanntheta(fill(z,10000), Ω, eps=1e-3)

    @test real(res[1]) ≈ 1.11415
    @test imag(res[1]) ≈ 0.8824
end


################################################################################

g = 3
δ = 1e-8
Random.seed!(0)
tmp = (rand()*10 - 5.) * rand(g,g) ; Ω = Complex.(rand(g, g), tmp*tmp')
z₀ = (rand()*10 - 5.) * rand(ComplexF64, g)

@testset "oscillatory_part derivs are correct (small)" begin

    circvec = [Complex(1.,0.); zeros(ComplexF64, g-1)]

    # calculate function at slightly shifted z₀
    z = [[z₀] ; [z₀ + circshift(δ * circvec, i) for i in 0:g-1]]
    res = oscillatory_part(z, Ω)
    dres = [ (res[i] - res[1]) / δ for i in 2:g+1 ]

    # and compare to calculated derivates
    for i in 0:g-1
        derivs = [ circshift(circvec, i) ]
        res2 = RiemannTheta.oscillatory_part([z₀], Ω, derivs=derivs)
        # println(res2[1], dres[i+1])
        # res2[1]/δ , dres[i+1]/δ
        @test res2[1] ≈ dres[i+1]
    end

end

@testset "oscillatory_part derivs are correct (large)" begin

    circvec = [Complex(1.,0.); zeros(ComplexF64, g-1)]

    # calculate function at slightly shifted z₀
    z = [[z₀] ; [z₀ + circshift(δ * circvec, i) for i in 0:g-1]]
    res = RiemannTheta.oscillatory_part(z, Ω)
    dres = [ (res[i] - res[1]) / δ for i in 2:g+1 ]

    # and compare to calculated derivates
    for i in 0:g-1
        derivs = [ circshift(circvec, i) ]
        res2 = oscillatory_part(repeat([z₀], outer=10000), Ω, derivs=derivs)
        @test res2[1] ≈ dres[i+1]
    end

end


@testset "riemanntheta derivs are correct" begin

    circvec = [Complex(1.,0.); zeros(ComplexF64, g-1)]

    # calculate function at slightly shifted z₀
    z = [[z₀] ; [z₀ + circshift(δ * circvec, i) for i in 0:g-1]]
    res = riemanntheta(z, Ω)
    dres = [ (res[i] - res[1]) / δ for i in 2:g+1 ]

    # and compare to calculated derivates
    for i in 0:g-1
        derivs = [ circshift(circvec, i) ]
        res2 = riemanntheta([z₀], Ω, derivs=derivs)
        # println(res2[1], dres[i+1])
        # res2[1]/δ , dres[i+1]/δ
        @test res2[1] ≈ dres[i+1]
    end
end
