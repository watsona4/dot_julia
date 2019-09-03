@testset "BernsteinPolynomial" begin
    @testset "evaluation" begin
        b = BernsteinPolynomial(1, 2, 3, 4)
        @test b(0) === 1
        @test b(1) === 4
    end

    @testset "utility" begin
        b = BernsteinPolynomial(1, 2, 3, 4)
        @test zero(b) === zero(typeof(b)) === BernsteinPolynomial(0, 0, 0, 0)
        @test constant(b) == 1
    end

    @testset "derivative" begin
        b = BernsteinPolynomial(1, 2, 3, 4)
        b′ = derivative(b)
        for t in range(0., 1., length=10)
            @test ForwardDiff.derivative(b, t) ≈ b′(t) atol=1e-10
        end
    end

    @testset "exponential integral" begin
        b = BernsteinPolynomial(1, 2, 3, 4)
        c = 5
        for t in range(0., 1., length=10)
            @test ForwardDiff.derivative(t -> exponential_integral(b, c, t), t) ≈ b(t) * exp(c * t) atol=1e-10
        end
        @test exponential_integral(b, c) ≈ exponential_integral(b, c, 1.0) atol=1e-10
    end

    @testset "arithmetic" begin
        b = BernsteinPolynomial(1, 2, 3, 4)
        c = 5
        for t in range(0., 1., length=10)
            @test (b + c)(t) ≈ b(t) + c
            @test (b - c)(t) ≈ b(t) - c
            @test (c + b)(t) ≈ c + b(t)
            @test (c - b)(t) ≈ c - b(t)
        end
        b1 = BernsteinPolynomial(1, 2, 3, 4)
        b2 = BernsteinPolynomial(2, 3, 4, 5)
        for t in range(0., 1., length=10)
            @test (b1 + b2)(t) ≈ b1(t) + b2(t)
            @test (b1 - b2)(t) ≈ b1(t) - b2(t)
        end
    end

    @testset "scaling" begin
        b1 = BernsteinPolynomial(2, 3, 4)
        @test b1 * 4 === 4 * b1 === BernsteinPolynomial(8, 12, 16)
        @test b1 / 2 === BernsteinPolynomial(2 / 2, 3 / 2, 4 / 2)
        for t in range(0., 1., length=10)
            @test (b1 * 4)(t) ≈ b1(t) * 4
            @test (b1 / 2)(t) ≈ b1(t) / 2
        end
        b2 = BernsteinPolynomial(ntuple(i -> 21 - i, Val(20)))
        allocs = let b2 = b2
            @allocated b2 * 4
        end
        @test allocs == 0
    end

    @testset "BernsteinPolynomial to Polynomial" begin
        b = BernsteinPolynomial(5, 4, 3, 2, 1, 10)
        p = Polynomial(b)
        for t in range(0., 1., length=10)
            @test b(t) ≈ p(t)
        end
        allocs = let b = b
            @allocated Polynomial(b)
        end
        @test allocs == 0
    end
end
