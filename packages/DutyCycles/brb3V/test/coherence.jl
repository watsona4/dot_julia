@testset "coherence" begin
    @testset "coherencetime" begin
        d = check(dutycycle(0.5, period=1))
        d2 = check(dutycycle(0.5, period=(2±0.1)))
        d3 = check(dutycycle(0.5, period=(2±0.1)*s))
        @test isinf(coherencetime(d))
        @test 40 ≈ coherencetime(d2)
        @test 40s ≈ coherencetime(d3)
    end
    T = typeof(default_period())
    dc_coh = CoherentDutyCycle{T,Rational{Int},Int}(1)
    dc_incoh = IncoherentDutyCycle{T,Rational{Int},Int}(1)
    @testset "incoherent cases" begin
        # except for assert-like tests used in the setup, only test
        # cases where a result of "incoherent" is expected.

        # an error or uncertainty that is just too big for the #
        # default tolerance when attached as independent standard
        # deviation to two (2) variables
        err = sqrt(2)*sqrt(eps(1.0))*1.0001
                
        @testset "disqualifying value" begin
            @test hascoherence_ratio(0) == false
            @test hascoherence_ratio(0.0) == false
            @test hascoherence_ratio(1//0) == false
            @test hascoherence_ratio(1.0/0) == false
            @test hascoherence_ratio(1 ± err) == false
            @test hascoherence_ratio(0s) == false
            @test hascoherence_ratio(0.0s) == false
            @test hascoherence_ratio(1s//0) == false
            @test hascoherence_ratio(1.0s/0) == false
            @test hascoherence_ratio((1 ± err)s) == false
            @testset "with $a" for a in [1, 0.9, 1//3, 1s, 0.31s, 2s//3]
                @test hascoherence_ratio(a) == true
                @test hascoherence_ratio(a, 0) == false
                @test hascoherence_ratio(a, 0.0) == false
                @test hascoherence_ratio(a, 1//0) == false
                @test hascoherence_ratio(a, 1.0/0) == false
                @test hascoherence_ratio(a, 1 ± err) == false
                @test hascoherence_ratio(a, 1.0 ± err) == false
                @test hascoherence_ratio(a, 0s) == false
                @test hascoherence_ratio(a, 0.0s) == false
                @test hascoherence_ratio(a, 1s//0) == false
                @test hascoherence_ratio(a, 1.0s/0) == false
                @test hascoherence_ratio(a, (1 ± err)s) == false
                @test hascoherence_ratio(a, (1.0 ± err)s) == false
                @test hascoherence_ratio(0, a) == false
                @test hascoherence_ratio(0.0, a) == false
                @test hascoherence_ratio(1//0, a) == false
                @test hascoherence_ratio(1.0/0, a) == false
                @test hascoherence_ratio(1 ± err, a) == false
                @test hascoherence_ratio(1.0 ± err, a) == false
                @test hascoherence_ratio(0s, a) == false
                @test hascoherence_ratio(0.0s, a) == false
                @test hascoherence_ratio(1s//0, a) == false
                @test hascoherence_ratio(1.0s/0, a) == false
                @test hascoherence_ratio((1 ± err)s, a) == false
                @test hascoherence_ratio((1.0 ± err)s, a) == false
            end
            @testset "iscoherent" begin
                @test !iscoherent(dc_incoh)
                @test !iscoherent(dc_incoh*1.3A)
                @test !iscoherent(dc_incoh, dc_coh)
                @test !iscoherent(dc_incoh*1.1mV, dc_coh*1.3A)
                @test !iscoherent(dc_coh, dc_incoh)
                @test !iscoherent(dc_incoh, dc_incoh)
            end
        end        
        @testset "independent values" begin
            # choose a "minimal" uncertainty to ascertain we trigger
            # even on relatively small values
            @test hascoherence_ratio(1.0 ± err, 1.0 ± err) == false
            @test hascoherence_ratio((1.0 ± err)*s, (1.0 ± err)*s) == false
            m = sqrt(eps(1.0))
            @test hascoherence_ratio(1.0 ± sqrt(2)*m, 1.0 ± sqrt(2)*m; tol=0.99999m) == false
        end
        @testset "maxperiods" begin
            @test hascoherence_ratio(1, 101, maxperiods=100) == false
            @test hascoherence_ratio(99, 101, maxperiods=100) == false
            @test hascoherence_ratio(101, 1, maxperiods=100) == false
            @test hascoherence_ratio(101, 99, maxperiods=100) == false
            @test hascoherence_ratio(1.01, 0.99, maxperiods=100) == false
            @test hascoherence_ratio(-1, 101, maxperiods=100) == false
            @test hascoherence_ratio(99, -101, maxperiods=100) == false
            @test hascoherence_ratio(-101, -1, maxperiods=100) == false
            @test hascoherence_ratio(-101, -99, maxperiods=100) == false
            @test hascoherence_ratio(-1.01, 0.99, maxperiods=100) == false
            @test hascoherence_ratio(1.01, -0.99, maxperiods=100) == false
            @test hascoherence_ratio(-1.01, -0.99, maxperiods=100) == false
        end
        @testset "return type" begin
            r = 3 ± 1
            @test typeof(coherence_ratio(1, 101, maxperiods=100)) == Rational{Int}
            @test typeof(coherence_ratio(big(1), 101, maxperiods=100)) == Rational{BigInt}
            @test typeof(coherence_ratio(1, big(101), maxperiods=100)) == Rational{BigInt}
            @test typeof(coherence_ratio(big(1), big(101), maxperiods=100)) == Rational{BigInt}
            @test typeof(coherence_ratio(1.0, 101.0, maxperiods=100)) == Rational{Int}
            @test typeof(coherence_ratio(big(1.0), 101.0, maxperiods=100)) == Rational{BigInt}
            @test typeof(coherence_ratio(1.0, big(101.0), maxperiods=100)) == Rational{BigInt}
            @test typeof(coherence_ratio(big(1.0), big(101.0), maxperiods=100)) == Rational{BigInt}
            @test typeof(coherence_ratio(1.0r, 101.0r, maxperiods=100)) == Rational{Int}
            @test typeof(coherence_ratio(big(1.0r), 101.0r, maxperiods=100)) == Rational{BigInt}
            @test typeof(coherence_ratio(1.0r, big(101.0)*r, maxperiods=100)) == Rational{BigInt}
            @test typeof(coherence_ratio(big(1.0r), big(101.0)*r, maxperiods=100)) == Rational{BigInt}
            x = r*mV
            y = r*mA
            D = _extractD(x/y)
            U = _extractU(x/y)
            @test typeof(coherence_ratio(1.0x, 101.0y, maxperiods=100)) == Unitful.Quantity{Rational{Int}}{D}{U}
            @test typeof(coherence_ratio(big(1.0)*x, 101.0y, maxperiods=100)) == Unitful.Quantity{Rational{BigInt}}{D}{U}
            @test typeof(coherence_ratio(1.0x, big(101.0)*y, maxperiods=100)) == Unitful.Quantity{Rational{BigInt}}{D}{U}
            @test typeof(coherence_ratio(big(1.0)*x, big(101.0)*y, maxperiods=100)) == Unitful.Quantity{Rational{BigInt}}{D}{U}
            @test typeof(coherence_ratio(x, 101y, maxperiods=100)) == Unitful.Quantity{Rational{Int}}{D}{U}
            @test typeof(coherence_ratio(big(1)*x, 101y, maxperiods=100)) == Unitful.Quantity{Rational{BigInt}}{D}{U}
            @test typeof(coherence_ratio(x, big(101)*y, maxperiods=100)) == Unitful.Quantity{Rational{BigInt}}{D}{U}
            @test typeof(coherence_ratio(big(1)*x, big(101)*y, maxperiods=100)) == Unitful.Quantity{Rational{BigInt}}{D}{U}
        end
    end
    @testset "coherent cases" begin
        @testset "hascoherence_ratio" begin
            # only minimally test this method, as the more critical
            # test is that of the underlying method coherence_ratio
            x = 1.0 ± 0.9
            @test hascoherence_ratio(x, x)
            @test hascoherence_ratio(3x, x/5)
            @test hascoherence_ratio(0.193x, 0.921x)
            @test hascoherence_ratio(x, 3x, x/5, 0.193x, 0.921x)
        end
        @testset "iscoherent" begin
            @test iscoherent(dc_coh)
            @test iscoherent(dc_coh*1.3A)
            @test iscoherent(dc_coh, dc_coh)
            @test iscoherent(dc_coh*3.1mV, dc_coh*1.3A)
        end
        x = 1.0 ± 0.9
        y = 0.9 ± 0.7
        @testset "ratio $(nd[1]) : $(nd[2])" for nd in [
            (99, 101),
            (-101, 99),
            (1.01, 0.99),
            (-1.01, 0.99),
            (1.01, -0.99),
            (-1.01, -0.99),
            (3//7, 13//5),
            (3//7, 13.0/5),
            (3.0/7, 13//5),
            (3.0/7, 13.0/5)
        ]
            a, b = nd
            r = abs(rationalize(a * 1.0 / b))
            @test r == coherence_ratio(a, b)
            @test r == coherence_ratio(13a, 13b)
            @test r == coherence_ratio(13//2*a, 13//2*b)
            @test r == coherence_ratio(1/7b, 1/7a)
            @test r == coherence_ratio(0.21a, 0.21b)
            @test 1//r == coherence_ratio(0.21b, 0.21a)
            @test r == coherence_ratio(a*x, b*x)
            @test r == coherence_ratio(a*x + a*y, b*x + b*y)
        end
        @testset "return type" begin
            r = 3 ± 1
            @test typeof(coherence_ratio(1, 101)) == Rational{Int}
            @test typeof(coherence_ratio(big(1), 101)) == Rational{BigInt}
            @test typeof(coherence_ratio(1, big(101))) == Rational{BigInt}
            @test typeof(coherence_ratio(big(1), big(101))) == Rational{BigInt}
            @test typeof(coherence_ratio(1.0, 101.0)) == Rational{Int}
            @test typeof(coherence_ratio(big(1.0), 101.0)) == Rational{BigInt}
            @test typeof(coherence_ratio(1.0, big(101.0))) == Rational{BigInt}
            @test typeof(coherence_ratio(big(1.0), big(101.0))) == Rational{BigInt}
            @test typeof(coherence_ratio(1.0r, 101.0r)) == Rational{Int}
            @test typeof(coherence_ratio(big(1.0r), 101.0r)) == Rational{BigInt}
            @test typeof(coherence_ratio(1.0r, big(101.0)*r)) == Rational{BigInt}
            @test typeof(coherence_ratio(big(1.0r), big(101.0)*r)) == Rational{BigInt}
            x = r*mV
            y = r*mA
            D = _extractD(x/y)
            U = _extractU(x/y)
            @test typeof(coherence_ratio(1.0x, 101.0y)) == Unitful.Quantity{Rational{Int}}{D}{U}
            @test typeof(coherence_ratio(big(1.0)*x, 101.0y)) == Unitful.Quantity{Rational{BigInt}}{D}{U}
            @test typeof(coherence_ratio(1.0x, big(101.0)*y)) == Unitful.Quantity{Rational{BigInt}}{D}{U}
            @test typeof(coherence_ratio(big(1.0)*x, big(101.0)*y)) == Unitful.Quantity{Rational{BigInt}}{D}{U}
            @test typeof(coherence_ratio(x, 101y)) == Unitful.Quantity{Rational{Int}}{D}{U}
            @test typeof(coherence_ratio(big(1)*x, 101y)) == Unitful.Quantity{Rational{BigInt}}{D}{U}
            @test typeof(coherence_ratio(x, big(101)*y)) == Unitful.Quantity{Rational{BigInt}}{D}{U}
            @test typeof(coherence_ratio(big(1)*x, big(101)*y)) == Unitful.Quantity{Rational{BigInt}}{D}{U}
        end
    end
end
