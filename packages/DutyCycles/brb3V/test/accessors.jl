@testset "accessors" begin
    TT = typeof(default_period())
    T = default_period()
    dc_coh = CoherentDutyCycle{TT,Rational{Int},Int}(1)
    dc_incoh = IncoherentDutyCycle{TT,Rational{Int},Int}(1)
    @testset "period" begin
        @test period(1.0s) == T
        @test period(dc_coh) == T
        @test isinf(period(dc_incoh))
        @test period(cycle(1.3m => 1mV)) == 1.3m
    end
    @testset "fundamental_frequency" begin
        f =  1 / T
        @test fundamental_frequency(1.0s) ≈ f
        @test fundamental_frequency(dc_coh) ≈ f
        @test iszero(fundamental_frequency(dc_incoh))
        @test fundamental_frequency(cycle(1.3m => 1mV)) ≈ 1/(1.3m)
    end
    @testset "extrema" begin
        # method is not explicitly provided, but should work because
        # we have a max() and a min() method
        @test extrema(1.0) == (1.0, 1.0)
        @test extrema(1A) == (1A, 1A)
        @test extrema(1.2A) == (1.2A, 1.2A)
        @test begin
            d = dutycycle(0.5)
            extrema(d) == (d,d)
        end
        @test begin
            d = dutycycle(0.5) * 1.2A
            extrema(d) == (d, d)
        end
    end
end
