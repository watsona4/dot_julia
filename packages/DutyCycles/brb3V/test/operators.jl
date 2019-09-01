@testset "operators" begin
    Imax = 1000.0mA
    duty = 0.1
    period = (20±0.02)ms # a period that is not synchronized with the
                         # default period, leading to incoherent
                         # combinations
    pulse = check(dutycycle(duty, onvalue=1.0, period=period))
    pulse_incoh = check(dutycycle(duty, onvalue=1.0))
    I = check(dutycycle(duty, onvalue = Imax, period=period))
    I_incoh = check(dutycycle(duty, onvalue = Imax))
    I2 = check(dutycycle(duty, onvalue = Imax^2, period=period))
    I2_incoh = check(dutycycle(duty, onvalue = Imax^2))
    Irms = rms(I)
    Imean = mean(I)
    @testset "setup" begin
        @test mean(Irms) ≈ sqrt(Imax^2 * duty)
        @test mean(I2) ≈ Imax^2 * duty
        @test rms(I2) ≈ sqrt(Imax^4 * duty)
        @test Imean ≈ Imax * duty
    end
    @testset "isapprox" begin
        Itest = I
        @test Itest ≈ Itest
        @test rms(Itest) ≈ Irms
        @test mean(Itest) ≈ Imean
        @test Imean ≈ mean(Itest)
        @test check(Itest^2) ≈ check(Itest^2)
        @test mean(Itest^2) ≈ Irms^2
        @test mean(Itest^2) ≈ Irms^2
        Itest = I_incoh
        @test Itest ≈ Itest
        @test rms(Itest) ≈ Irms
        @test mean(Itest) ≈ Imean
        @test Imean ≈ mean(Itest)
        @test check(Itest^2) ≈ check(Itest^2)
        @test mean(Itest^2) ≈ Irms^2
        @test mean(Itest^2) ≈ Irms^2
    end
    @testset "^" begin
        @test check(
            dutycycle(0.5, onvalue=8, offvalue=0) * A^3
        ) ≈ check(
            (dutycycle(0.5, onvalue=2, offvalue=0) * A) ^ 3
        )
        @test check(
            dutycycle(0.5, onvalue=1//2, offvalue=2) / sqrt(Hz)
        ) ≈ check(
            (dutycycle(0.5, onvalue=4, offvalue=1//4) * Hz) ^ (-1//2)
        )
    end
    @testset "*, /" begin
        @test rms(check(2I)) ≈ 2Irms
        @test rms(check(2I_incoh)) ≈ 2Irms
        @test check(I*I) ≈ check(I^2) 
        @test check(I_incoh*I_incoh) ≈ check(I_incoh^2)
        #@test isnan(mean(check(I / I))) # 0/0 division during off time; To Do: Implement isnan for a DutyCycle
        @test check(I / (I+eps(Imax))) ≈ pulse
        @test check(I / Irms) ≈ check((1.0 / Irms) * I)
    end
    @testset "+, -" begin
        @test check(I + I) ≈ check(2I)
        @test mean(check(I + I)) ≈ mean(2I)
        @test rms(check(I + I)) ≈ rms(2I)
        @test mean(check(I + Imean)) ≈ 2Imean
        @test mean(check(I + 3mA)) ≈ Imean + 3mA
        @test mean(check(7mA + I)) ≈ Imean + 7mA
        @test mean(check(check(I + 3mA) + 1.2mA)) ≈ Imean + 4.2mA
        @test check(I - I) ≈ 0I
        @test rms(check(I - I)) ≈ 0mA
        @test mean(check(I - Imean)) ≈ 0mA

        @test check(I_incoh + I_incoh) ≈ 2I_incoh
        @test mean(check(I_incoh + Imean)) ≈ 2Imean
        @test mean(check(I_incoh + 3mA)) ≈ Imean + 3mA
        @test mean(check(7mA + I_incoh)) ≈ Imean + 7mA
        @test mean(check(check(I_incoh + 3mA) + 1.2mA)) ≈ Imean + 4.2mA
        @test check(I_incoh - I_incoh) ≈ incoherent!(0I_incoh)
        @test check(I_incoh - I_incoh) ≈ 0I_incoh
        @test check(I_incoh - I_incoh) ≉ incoherent!(0mA)
        @test mean(check(I_incoh - I_incoh)) ≈ 0mA
        @test mean(check(I_incoh - Imean)) ≈ 0mA
    end
    @testset "==, !=" begin
        @test I == I
        @test I^2 == I2
        @test !(I == I + eps(Imax))
        @test I != I + eps(Imax)
    end
    @testset "real, imag" begin
        period = default_period()
        @test 3 == real(check(cycle(1period => 3+5im)))
        @test 5 == imag(check(cycle(1period => 3+5im)))
        @test 3mV == real(check(cycle(1period => (3+5im) * mV)))
        @test 5A == imag(check(cycle(1period => (3+5im) * A)))
    end
end
