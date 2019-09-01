@testset "pre-doctests" begin
    @testset "DutyCycles.jl" begin
        @test (@test_logs @eval begin
            using DutyCycles
            using Unitful: Ω, mA, mW
            I = dutycycle(0.5, onvalue=100mA)
            R = 50Ω
            P = I^2 * R
            mean(P) ≈ 250mW
        end)
    end
    @testset "defaults.jl" begin
        # this should come absolutely last because it tampers with
        # internals (the default_period method definition)
        @testset "default_period doc" begin
            @test (@test_logs @eval begin
                using DutyCycles, Unitful
                using Unitful: Ω, mA, Hz
                DutyCycles.default_period(::Number) = 50Hz/60Hz*default_period()
                I = dutycycle(0.5, onvalue = 50mA)
                U = dutycycle(0.5, onvalue = 50Ω * 50mA)
                uconvert(Hz, fundamental_frequency(U * I))
            end) ≈ (60±3e-6)*Hz
            @test (@test_logs @eval begin
                using DutyCycles, Unitful, Measurements
                using Unitful: Ω, mA, mW, Hz
                DutyCycles.default_period(::Number) = 1/((60±3e-6)*Hz)
                I = dutycycle(0.5, onvalue = 50mA)
                U = dutycycle(0.5, onvalue = 50Ω * 50mA)
                uconvert(Hz, fundamental_frequency(U * I))
            end) == 0.0Hz
        end
    end
end
