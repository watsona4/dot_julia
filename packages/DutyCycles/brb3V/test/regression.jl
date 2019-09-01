@testset "bugs" begin
    @testset "fixed" begin
        # proper regression tests: these are here to ensure we don't
        # run into an old bug again
        @testset "agglomeration assignment failure" begin
            # incoherent case
            P1 = cycle(0.5 => 2*300W, 0.5 => 0W) + 1W
            P2 = cycle(0.5 => 2*300W, 0.5 => 0W) + 1W
            P3 = cycle(0.5 => 2*300W, 0.5 => 0W) + 1W
            @test mean(P1 + P2 + P3) ≈ 903W
            # coherent case
            d1 = cycle(16//2 => 2, 16//2 => 0)
            d2 = cycle(1//2 => 2, 1//2 => 0)
            d3 = cycle(4//2 => 2, 4//2 => 0)
            @test mean(d1 * d2 * d3) ≈ 1
        end
        @testset "_extractnondutycycle fail for 1.2A" begin
            @test DutyCycles._extractnondutycycle(1.2A) == 1.2A
        end
        @testset "instantiation w/ number to be converted" begin
            T = typeof((20 ± 1e-6) * Unitful.ms)
            U = Measurements.Measurement{Float64}
            V = Measurements.Measurement{Float64}
            Vin = Int64
            @eval @test (
                CoherentDutyCycle{$T,$U,$V}($Vin(1)) isa
                CoherentDutyCycle
            )
            @eval @test (
                IncoherentDutyCycle{$T,$U,$V}($Vin(1)) isa
                IncoherentDutyCycle
            )
        end
        @testset "type of cycle w/ coherent times" begin
            @test CoherentDutyCycle{
                typeof(default_period()),Float64,Int
            } == typeof(cycle(
                0.3default_period() => 1,
                0.7default_period() => 0
            ))
        end
        @testset "rms with BigFloat" begin
            val = big(1.3)
            @test rms(check(val * dutycycle(0.5, onvalue=1))) ≈
                sqrt(2*one(val))/2 * val
        end
        @testset "dutycycle with offvalue and onvalue" begin
            @test 5.5 ≈
                mean(dutycycle(0.5, offvalue=1, onvalue=10))
            @test 5.5 ≈
                mean(dutycycle(0.5, offvalue=1.0, onvalue=10.0))
        end
        @testset "dutycycle isa AbstractCoherentDutyCycle" begin
            @test check(dutycycle(0.5)) isa AbstractCoherentDutyCycle
        end
        @testset "valueat unitful failure" begin
            @test 1A == valueat(
                dutycycle(0.5, onvalue=1A, period=1.0s),
                0.1s
            )
        end
    end
    @testset "open" begin
        # bugs that have existing tests but for which there is no
        # bugfix yet: should typically be defined using @test_broken
        @testset "affine unit conversion" begin
            @test_broken uconvert(
                Unitful.°C,
                1Unitful.K*dutycycle(0.5,offvalue=1, onvalue=10)
            ) isa AbstractDutyCycle
        end
    end
    @testset "test dev" begin
        # tests under development: they don't work to catch a known
        # bug yet but are already here to share ideas
    end
end
