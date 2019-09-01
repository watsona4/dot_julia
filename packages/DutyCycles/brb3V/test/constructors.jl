@testset "constructors" begin
    # test types returned from parametrized constructors, and that no
    # logging occurs
    defaultT = typeof(DutyCycles.DEFAULT_PERIOD)
    function shorttypeof(T)
        if T == defaultT
            return "(default)"
        elseif T <: Unitful.AbstractQuantity
            TT = DutyCycles._extract_T_from_Unitful_AbstractQuantity(T)
            return string(repr(TT), " ", repr(Unitful.unit(T)))
        end
        return repr(T)
    end
    warn_coherence =
        r"default period: adding coherence by removing rel. uncertainty.*"
    warn_dimensions =
        r"default period: dimensions given that differ from the input.*"
    #warning_rounding =
    #        "$warnprefix: rounding (avoiding zero) changed the value"
    # test cases with no warnings
    @testset "no warnings" begin
    @testset "T == $(shorttypeof(T))" for T in [
        defaultT,
        typeof((1.0±1)s),
    ]
        U = Rational{Int}
        @testset "value::$V" for V in [
            #Int, # needs accomodating the warning about rounding
            Rational{Int},
            #big(Int), # needs accomodating the warning about rounding
            Rational{BigInt},
            Float64, big(Float64)
        ]
            @eval @test typeof(@test_logs check(
                CoherentDutyCycle{$T,$U,$V}($V(3))
            )) == CoherentDutyCycle{$T,$U,$V}
            if T <: Integer
                #T2 = Rational{T}
                @test_throws InexactError (
                    IncoherentDutyCycle{T,U,V}(V(3))
                )
            else
                @test typeof(@test_logs check(
                    IncoherentDutyCycle{T,U,V}(V(3))
                )) == IncoherentDutyCycle{T,U,V}
            end
        end
    end
    end
    # test cases with coherence warning only
    @testset "added coherence" begin
    @testset "T == $(shorttypeof(T))" for T in [
        typeof((1.0)s)
    ]
        U = Rational{Int}
        @testset "value::$V" for V in [
            Float64
        ]
            @test typeof(@test_logs (
                :warn, warn_coherence
            ) check(
                CoherentDutyCycle{T,U,V}(V(3))
            )) == CoherentDutyCycle{T,U,V}
            if T <: Integer
                #T2 = Rational{T}
                @test_throws InexactError (
                    IncoherentDutyCycle{T,U,V}(V(3))
                )
            else
                @test typeof(@test_logs check(
                    IncoherentDutyCycle{T,U,V}(V(3))
                )) == IncoherentDutyCycle{T,U,V}
            end
        end
    end
    end
    # test cases with dimensions warning only
    @testset "wrong dimension" begin
    @testset "T == $(shorttypeof(T))" for T in [
        typeof(1.0±1), # dimensionless numbers might make sense, but
                       # warn since they should then be used
                       # consistently (and by changing the default
                       # period accordingly).
        typeof((1.0±1)m) # it's conceivable to use cycles that repeat
                         # in space
    ]
        U = Rational{Int}
        @testset "value::$V" for V in [
            #Int, # needs accomodating the warning about rounding
            Rational{Int}, Float64,
            #big(Int), # needs accomodating the warning about rounding
            Rational{BigInt},
            big(Float64)
        ]
            @test typeof(@test_logs (
                :warn, warn_dimensions
            ) check(
                CoherentDutyCycle{T,U,V}(V(3))
            )) == CoherentDutyCycle{T,U,V}
            if T <: Integer
                #T2 = Rational{T}
                @test_throws InexactError (
                    IncoherentDutyCycle{T,U,V}(V(3))
                )
            else
                @test typeof(@test_logs check(
                    IncoherentDutyCycle{T,U,V}(V(3))
                )) == IncoherentDutyCycle{T,U,V}
            end
        end
    end
    end
    # test cases with both warnings
    @testset "coh. and dim." begin
    @testset "T == $(shorttypeof(T))" for T in [
        #Int, # needs accomodating the warning about rounding
        Rational{BigInt},
        Float16,
        Float32,
        Float64,
        big(Float64)
    ]
        U = Rational{Int}
        @testset "value::$V" for V in [
            Int, Rational{Int}, Float64, big(Int), big(Float64)
        ]
            @test typeof(@test_logs (
                :warn, warn_dimensions
            ) (
                :warn, warn_coherence
            ) check(
                CoherentDutyCycle{T,U,V}(V(3))
            )) == CoherentDutyCycle{T,U,V}
            if T <: Integer
                #T2 = Rational{T}
                @test_throws InexactError (
                    IncoherentDutyCycle{T,U,V}(V(3))
                )
            else
                @test typeof(@test_logs check(
                    IncoherentDutyCycle{T,U,V}(V(3))
                )) == IncoherentDutyCycle{T,U,V}
            end
        end
    end
    end
end
