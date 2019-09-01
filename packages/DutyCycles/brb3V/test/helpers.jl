# test the helpers from src/helpers.jl
@testset "helpers" begin
    @testset "_firstactual" begin
        _firstactual = DutyCycles._firstactual
        @test 1 == _firstactual(1, 2, 3)
        @test 2 == _firstactual(nothing, 2, 3)
        @test 3 == _firstactual(nothing, missing, 3)
    end
    @testset "_isrational" begin
        _isrational = DutyCycles._isrational
        @test _isrational(1)
        @test _isrational(1s)
        @test _isrational(UInt8(1))
        @test _isrational(-1//3)
        @test _isrational(-1//3s)
        @test _isrational(big"3"//7)
        @test !_isrational(1.0)
        @test !_isrational(big(1.0))
        @test !_isrational(Float16(1.0))
    end
    @testset "_infinity" begin
        function testisinf(expr)
            @test isinf(expr)
            return expr
        end
        _infinity = DutyCycles._infinity
        @test isinf(_infinity(1)::Rational{Int})
        @test isinf(_infinity(big"1")::Rational{BigInt})
        @test isinf(_infinity(1//2)::Rational{Int})
        @test isinf(_infinity(1.0)::Float64)
        @test isinf(_infinity(big"1.0")::BigFloat)
        @test isinf(_infinity(1.0±1)::typeof(1.0±1))
        @test isinf(_infinity((1.0±1)s)::typeof((1.0±1)s))
        @test isinf(_infinity((1.0±1)m)::typeof((1.0±1)m))
    end
    @testset "convert_warn" begin
        warnprefix = "Test Prefix"
        warning_dimensions = string(
            "$warnprefix: ",
            "dimensions given that differ from the input ",
            "more than just by stripping its units"
        )
        warning_coherence = Regex(string(
            warnprefix, ": ",
            "adding coherence by removing rel. uncertainty.*"
        ))
        warning_rounding =
            "$warnprefix: rounding (avoiding zero) changed the value"
        for testcase in [
            # (T, x, result, war_dim., warn_coh., warn_round.)
            (Int64, 1, 1, false, false, false),
            (Int64, 0.001, 1, false, false, true),
            (Int64, 0.001 ± 1, 1, false, true, true),
            (typeof(1s), 1, 1s, true, false, false),
            (typeof(1s), 0.001, 1s, true, false, true),
            (typeof(1s), 1±0.001, 1s, true, true, false),
            (Float64, 1, 1.0, false, false, false),
            (Float64, 0.001, 0.001, false, false, false),
            (typeof(0.1m), 0.1, 0.1m, true, false, false),
            (typeof(0.1m), 0.1±0.001, 0.1m, true, true, false),
            (Measurement{Float64}, 0.1, 0.1, false, false, false),
            # the following also asserts that
            # Measurements.Measurements continue to be floating point
            # backed by default (currently and sensibly, it must
            # always be an AbstractFloat)
            (typeof(1±1), 0.1, 0.1±0, false, false, false)
        ]
            T, x, r, warn_dims, warn_coh, warn_round = testcase
            # create log test patterns p...
            p = Vector{Tuple{Symbol, Any}}(undef, 0)
            warn_dims && push!(p, (:warn, warning_dimensions))
            warn_coh && push!(p, (:warn, warning_coherence))
            warn_round && push!(p, (:warn, warning_rounding))
            if length(p) == 0
                # no warnings are expected
                @test (@eval @test_logs begin
                       DutyCycles.convert_warn($T, $x, $warnprefix)
                       end) == r
            elseif length(p) == 1
                # one warning is expected
                p1 = p[1]
                @test (@eval @test_logs $p1 begin
                       DutyCycles.convert_warn($T, $x, $warnprefix)::$T
                       end) == r
            elseif length(p) == 2
                p1 = p[1]
                p2 = p[2]
                @test (@eval @test_logs $p1 $p2 begin
                       DutyCycles.convert_warn($T, $x, $warnprefix)::$T
                       end) == r
            elseif length(p) == 3
                p1 = p[1]
                p2 = p[2]
                p3 = p[3]
                @test (@eval @test_logs $p1 $p2 $p3 begin
                       DutyCycles.convert_warn($T, $x, $warnprefix)::$T
                       end) == r
            else
                throw(DomainError("more than 3 warnings are not implemented"))
            end
        end
    end
    @testset "_firstactual" begin
        _firstactual = DutyCycles._firstactual
        @test _firstactual(1,2) == 1
        @test _firstactual(1.0,2.0) == 1
        @test _firstactual(1.0,2.0) == 1
        @test _firstactual(nothing, 3, 5) == 3
        @test _firstactual(missing, 1//3, 1//2) == 1//3
        @test _firstactual(nothing, nothing, 5) == 5
    end
    @testset "_extractdutycycle" begin
        @test dutycycle(0.5) !== missing
        d = dutycycle(0.5)
        _extractdutycycle = DutyCycles._extractdutycycle
        @test d isa AbstractDutyCycle
        @test _extractdutycycle(1) == 1
        @test _extractdutycycle(1.0) == 1
        @test _extractdutycycle(big"1") == 1
        @test _extractdutycycle(big"1.0") == 1
        @test _extractdutycycle(1//3) == 1
        @test _extractdutycycle(d) == d
        @test _extractdutycycle(d*A) == d
        @test _extractdutycycle(d*1.2A) == 1.2d
        @test _extractdutycycle(d*1.3mV) == 1.3d
    end
    @testset "_extractnondutycycle" begin
        d = dutycycle(0.5)
        _extractnondutycycle = DutyCycles._extractnondutycycle
        @test _extractnondutycycle(1) == 1
        @test _extractnondutycycle(1.0) == 1.0
        @test _extractnondutycycle(big"1") == big"1"
        @test _extractnondutycycle(big"1.0") == big"1.0"
        @test _extractnondutycycle(1//3) == 1//3
        @test _extractnondutycycle(1.2A) == 1.2A
        @test _extractnondutycycle(d) == 1
        @test _extractnondutycycle(d*1.2A) == A
        @test _extractnondutycycle(d*1.3mV) == mV
    end
    # To Do: tests for check
    # To Do: tests for apply_phasewise (and _incoherently as well as _coherently)
end

