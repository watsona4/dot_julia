@testset "waveforms" begin
    TT = typeof(default_period())
    T = default_period()
    dc_coh = CoherentDutyCycle{TT,Rational{Int},Int}(1)
    dc_incoh = IncoherentDutyCycle{TT,Rational{Int},Int}(1)
    @testset "waveform" begin
        @test waveform(dc_coh)(0.5*default_period()) == 1
        @test waveform(dc_incoh)(0.5*default_period()) == 1
        d = cycle(0.5default_period() => 1, 0.5default_period() => -1)
        @test d isa AbstractCoherentDutyCycle
        # repeat often enough to likely fail if the return value is
        # randomly chosen, as it should be for an incoherent duty
        # cycle
        for i = 1:10
            @test waveform(d)(1//4*default_period()) == 1
            @test waveform(d)(1π/2) == 1
            @test waveform(d)(3π/2) == -1
            @test waveform(d)(3//4*default_period()) == -1
        end
    end
    @testset "spectrum" begin
        T1 = (2±0.1)s
        U = check(dutycycle(0.5, onvalue = 1.0mV, period = T1))
        @test Unitful.dimension(mV/sqrt(Hz)) ==
            Unitful.dimension((psd(U))(0.0Hz))
        # To Do: build a test such as @test (integrate psd(U)(ν)
        #        around ν = fundamental_frequency(U)) ≈ 1mV / sqrt(Hz)
        #@test psd(U)(0Hz) == 0.5mV / sqrt(Hz)
        I = check(dutycycle(0.5, onvalue = 1.0A, period = T1))
        @test Unitful.dimension(A/sqrt(Hz)) ==
            Unitful.dimension((psd(I))(0.0Hz))
        @test Unitful.dimension(W/Hz) ==
            Unitful.dimension((psd(U*I))(0.0Hz))
    end
end
