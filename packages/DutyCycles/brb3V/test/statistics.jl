@testset "statistics" begin
d1 = check(1.2 * dutycycle(0.3, onvalue = 1.0))
d1mean = 1.2 * 0.3
d1rms = sqrt(1.2^2 * 0.3)
d2 = check(cycle(
    0.3default_period() => 1.2,
    1.7default_period() => 0.1
))
d2mean = (1.2 * 0.3 + 0.1 * 1.7) / (0.3 + 1.7)
d2rms = sqrt((1.2^2 * 0.3 + 0.1^2 * 1.7) / (0.3 + 1.7))

# due to the name conflict with Statistics.mean, test it a bit more
# thoroughly than yet another derived method would otherwise warrant
@testset "Base.Statistics" begin
    @testset "mean" begin
        @test Statistics.mean([1,2]) ≈ 1.5
        @test Statistics.mean([d1, d2]) ≈ (d1 + d2) / 2
        @test Statistics.mean(x->x^2, [d1, d2]) ≈
            (d1^2 + d2^2) / 2
        @testset "with $val::$(typeof(val))" for val in [
            1 #, 1.0, big"1", big"1.0", 3//2, "big"3/2
        ]
            @test Statistics.mean([val, d1]) ≈ (val + d1) / 2
            @test Statistics.mean([d1, val]) ≈ (val + d1) / 2
            @test Statistics.mean(x->x^2, [d1, val]) ≈
                (val^2 + d1^2) / 2

            meas = val ± (val*2/3)
            @test Statistics.mean([meas, d1]) ≈ (meas + d1) / 2
            @test Statistics.mean([d1, meas]) ≈ (meas + d1) / 2
            @test Statistics.mean(x->x^2, [d1, meas]) ≈
                (meas^2 + d1^2) / 2
        end
    end
end
@testset "averages" begin
    @testset "mean" begin
        d1d2mean = (d1mean + d2mean) / 2
        @test mean(d1) ≈ d1mean
        @test mean(d2) ≈ d2mean
        @testset "with $val::$(typeof(val))" for val in [1, 1.0, big"1", big"1.0", 3//2, big"3"//2]
            @test mean(val) ≈ val
        end
    end
    @testset "rms" begin
        d3 = check(
            cycle(0.3s => 1200mV, 1.7s => 100.0mV)
        )
        d3rms = sqrt((1.2^2 * 0.3 + 0.1^2 * 1.7) /
                  (0.3 + 1.7)) * 1000mV
        d4 = check(
            cycle(300ms => 1.2A, 1700ms => 0.1A)
        )
        d4rms = sqrt((1.2^2 * 0.3 + 0.1^2 * 1.7) /
                  (0.3 + 1.7)) * A
        @test rms(d1) ≈ d1rms
        @test rms(d2) ≈ d2rms
        @test rms(d3) ≈ d3rms
        @test rms(d4) ≈ d4rms
        @test d1 ≉ d1rms
        @test d2 ≉ d2rms
        @test d3 ≉ d3rms
        @test d4 ≉ d4rms
        @testset "with $val::$(typeof(val))" for val in [
            3, 5.1, big(7), big(4.1), 3//2, big(3)//2
        ]
            @test rms(val) ≈ val
            Tval = typeof(val)
            @test rms(check(val * dutycycle(0.5, onvalue=1))) ≈
                sqrt(2*one(Tval))/2 * val
        end
        # assert that we haven't made rms excessively analogous to
        # Statistics.mean
        @test_throws MethodError rms(identity, [1,1])
    end
    @testset "auto" begin
        d = check(dutycycle(0.01, onvalue=1000.0))
        dmean = 10.0
        drms = 100.0
        @test drms ≉ dmean # stop us from breaking the following tests
        @test mean(d) ≈ dmean
        @test rms(d) ≈ drms
        @test autoavg(d) ≈ dmean
        @test autoavg(d*1A) ≈ drms*1A
        @test autoavg(d*1mV) ≈ drms*1mV
        @test drms*1A*1mV ≉ dmean*1A*1mV # stop any potential strange
                                         # behavior of units (or of
                                         # isapprox) from breaking the
                                         # following tests
        @test rms(d*1A*1mV) ≈ drms*1A*1mV
        @test autoavg(d*1A*1mV) ≈ dmean*1A*1mV
        @test autoavg(d*1m) ≈ dmean*1m
        @test autoavg(d*1mbar) ≈ dmean*1mbar
        @testset "with $val::$(typeof(val))" for val in [
            1 #, 1.0, big"1", big"1.0", 3//2, big"3"//2
        ]
            @test autoavg(val) ≈ val
            @test autoavg(check(val*dutycycle(0.5, onvalue=1))) ≈ 0.5val
            @test autoavg(check(val*A*dutycycle(0.5, onvalue=1))) ≈
                sqrt(2)/2*val*A
            @test autoavg(check(val*mV*dutycycle(0.5, onvalue=1))) ≈
                sqrt(2)/2*val*mV
            @test autoavg(check(val*val*W*dutycycle(0.5, onvalue=1))) ≈ 0.5*val*W
            @test autoavg(check(val*m*dutycycle(0.5, onvalue=1))) ≈ 0.5*val*m
            @test autoavg(check(val*mbar*dutycycle(0.5, onvalue=1))) ≈
                0.5*val*mbar
        end
    end
end
@testset "extrema" begin
    @testset "maxval" begin
        @test maxval(1.2) == 1.2
        @test maxval(1.2A) == 1.2A
        @test maxval(check(dutycycle(0.5, onvalue=1.2))) == 1.2
        @test maxval(
            check(dutycycle(0.5, onvalue=1.2)),
            check(dutycycle(0.5, onvalue=1.3)),
            check(dutycycle(0.5, onvalue=1.1))
        ) == 1.3
        @test maxval(
            check(dutycycle(0.5, onvalue=1.2A)),
            check(dutycycle(0.5, onvalue=1.3A)),
            check(dutycycle(0.5, onvalue=1.1A))
        ) == 1.3A
    end
    @testset "extremavals" begin
        @test (-2,3) == extremavals(
            check(dutycycle(0.5, offvalue=-2, onvalue=3)),
        )
        @test (-3,5) == extremavals(
            check(dutycycle(0.5, offvalue=-2, onvalue=3)),
            check(dutycycle(0.5, offvalue=-3, onvalue=1)),
            check(dutycycle(0.5, offvalue=-1, onvalue=5)),
        )
    end
end
end
