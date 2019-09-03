@testset "monomial_basis" begin
    @testset "construction" begin
        @test Polynomial{4}(Polynomial(1, 2)).coeffs === (1, 2, 0, 0)
        @test Polynomial{4, Float64}(Polynomial(1, 2)).coeffs === (1.0, 2.0, 0.0, 0.0)

        p = Polynomial(ntuple(i -> 21 - i, Val(10)))
        Polynomial{20, Float64}(p)
        allocs = @allocated Polynomial{20, Float64}(p)
        @test allocs == 0

        @test Polynomial{2}(Polynomial(1, 2, 0)).coeffs === (1, 2)
        @test_throws InexactError Polynomial{2}(Polynomial(1, 2, 3))
    end

    @testset "evaluation" begin
        @test Polynomial(1)(2) == 1
        @test Polynomial(2, 3, 4)(5) == 2 + 3 * 5 + 4 * 5^2
    end

    @testset "utility" begin
        p = Polynomial(2, 3, 4)
        @test constant(p) === 2
        @test zero(p) === Polynomial(0, 0, 0)
        @test transpose(p) === p
        @test conj(p) === p
        @test conj(Polynomial(1 + 2im, 3 + 4im, 5 - 6im)) === Polynomial(1 - 2im, 3 - 4im, 5 + 6im)
    end

    @testset "padding" begin
        p = Polynomial(2, 3, 4)
        q = Polynomial{20}(p)
        @test p(5) == q(5)
        allocs = @allocated Polynomial{20}(p)
        @test allocs == 0
    end

    @testset "arithmetic" begin
        p1 = Polynomial(2, 3, 4)
        p2 = Polynomial(6, 7, 8)
        p3 = Polynomial(ntuple(i -> 21 - i, Val(20)))
        @test (p1 + p2)(7) == p1(7) + p2(7)
        allocs = @allocated p1 + p2
        @test allocs == 0
        @test (p1 + p3)(7) == p1(7) + p3(7)
        allocs = @allocated p1 + p3
        @test allocs == 0
        @test p1 + 1 === Polynomial(3, 3, 4)
        @test 1 - p2 === Polynomial(-5, -7, -8)
        @test +p1 === p1
        @test -p1 === Polynomial(-2, -3, -4)
        p4 = p1 * p3
        @test (p1 * p3)(3) == p1(3) * p3(3)
        allocs = @allocated p1 * p3
        @test allocs == 0
    end

    @testset "scaling" begin
        p1 = Polynomial(2, 3, 4)
        @test p1 * 4 === 4 * p1 === Polynomial(8, 12, 16)
        @test p1 / 2 === Polynomial(2 / 2, 3 / 2, 4 / 2)
        p2 = Polynomial(ntuple(i -> 21 - i, Val(20)))
        p2 * 4
        allocs = @allocated p2 * 4
        @test allocs == 0
    end

    @testset "derivative" begin
        p1 = Polynomial(3)
        @test derivative(p1) === Polynomial(0)

        p2 = Polynomial(1, 2, 3, 4)
        @test derivative(p2) === Polynomial(2, 2 * 3, 3 * 4)

        p3 = Polynomial(ntuple(i -> 21 - i, Val(20)))
        derivative(p3)
        allocs = @allocated derivative(p3)
        @test allocs == 0
    end

    @testset "integral" begin
        p = Polynomial(ntuple(i -> 21 - i, Val(20)))
        c = 5
        P = integral(p, c)
        @test constant(P) == c
        P′ = derivative(P)
        for x in 0 : 0.1 : 1
            @test P′(x) ≈ p(x) atol=1e-14
        end
    end

    @testset "gradient w.r.t coefficients" begin
        for x in [0, 1, 2]
            @test coefficient_gradient(x, Val(5)) === (1, x, x^2, x^3, x^4)
            @test coefficient_gradient(x, Val(5), Val(1)) === (0, 1, 2x, 3x^2, 4x^3)
            @test coefficient_gradient(x, Val(5), Val(2)) === (0, 0, 2, 6x, 12x^2)

            @test @allocated(coefficient_gradient(x, Val(5))) == 0
            @test @allocated(coefficient_gradient(x, Val(5), Val(1))) == 0
            @test @allocated(coefficient_gradient(x, Val(5), Val(2))) == 0
        end
    end

    @testset "exponential integral" begin
        p = Polynomial(1, 2, 3, 4)
        c = 5
        for t in range(0., 1., length=10)
            @test ForwardDiff.derivative(t -> exponential_integral(p, c, t), t) ≈ p(t) * exp(c * t) atol=1e-10
        end
    end

    @testset "broadcast" begin
        p1 = Polynomial(1, 2)
        p2 = Polynomial(3, 4)
        @test [p1, p2] .+ 1 == [Polynomial(2, 2), Polynomial(4, 4)]
    end
end
