@testset "promotion" begin
    @testset "to [In]CoherentDutyCycle" begin
        @testset "values::$V" for V in [
            Int, #Rational{Int}, Float64, big(Int), big(Float64),
            typeof(1±1)
        ]
            @testset "durations::$U" for U in [
                Int, Float16 #, Rational{Int}, Float64, big(Int), big(Float64)
            ]
                @testset "periods::$T" for T in unique([
                    typeof(one(U)*s),
                    typeof(one(U)*Unitful.ms),
                    typeof(one(U)/Unitful.MHz)
                ])

                    @test promote_type(V, CoherentDutyCycle{T,U,V}) ==
                        CoherentDutyCycle{T,U,V}
                    @test typeof(@test_logs min_level=Logging.Error (
                        CoherentDutyCycle{T,U,V}(2)
                    )) ==
                        CoherentDutyCycle{T,U,V}
                    if !(one(T) isa Integer)
                        @test promote_type(V, IncoherentDutyCycle{T,U,V}) ==
                            IncoherentDutyCycle{T,U,V}
                        @test typeof(IncoherentDutyCycle{T,U,V}(2)) ==
                            IncoherentDutyCycle{T,U,V}
                    end
                end
            end
        end
    end
    testcases = [
        # each contains T1,T2,T, U1,U2,U, V1,V2,V where the last of
        # each group of three is the resulting type
    (
        Int, Rational{Int}, Rational{Int},
        Float16, Rational{BigInt}, BigFloat,
        typeof(1), typeof((7±1)), typeof(1±1)
    ), (
        typeof((1±1)), typeof(1), typeof((1±1)),
        Float64, Rational{Int}, Float64,
        typeof(2//3), typeof(1), typeof(2//3)
    )
        # To Do: add test cases
    ]
    @testset "two CoherentDutyCycles" begin
        for case in testcases
            T1,T2,T, U1,U2,U, V1,V2,V = case
            @eval @test @test_logs min_level=Logging.Error (
                _typeof_promote(
                    CoherentDutyCycle{$T1,$U1,$V1}(one($V1)),
                    CoherentDutyCycle{$T2,$U2,$V2}(one($V2))
                )
            ) == CoherentDutyCycle{$T,$U,$V}
        end
    end
    @testset "coherent and incoherent" begin
        for case in testcases
            T1,T2,T, U1,U2,U, V1,V2,V = case
            # promote time types to suit IncoherentDutyCycle
            T2 = promote_type(T2, Rational{Int})
            T = promote_type(T, Rational{Int})
            @eval @test @test_logs min_level=Logging.Error (
                _typeof_promote(
                    CoherentDutyCycle{$T1,$U1,$V1}(one($V1)),
                    IncoherentDutyCycle{$T2,$U2,$V2}(one($V2))
                )
            ) == IncoherentDutyCycle{$T,$U,$V}
            # switch coherent/incoherent property: almost the same
            # again, but still a (usually) distinct test case
            T1,T2,T, U1,U2,U, V1,V2,V = case
            # promote time types to suit IncoherentDutyCycle
            T1 = promote_type(T1, Rational{Int})
            T = promote_type(T, Rational{Int})
            @eval @test @test_logs min_level=Logging.Error (
                _typeof_promote(
                    IncoherentDutyCycle{$T1,$U1,$V1}(one($V1)),
                    CoherentDutyCycle{$T2,$U2,$V2}(one($V2))
                )
            ) == IncoherentDutyCycle{$T,$U,$V}
        end
    end
    @testset "two IncoherentDutyCycles" begin
        for case in testcases
            T1,T2,T, U1,U2,U, V1,V2,V = case
            # promote time types to suit IncoherentDutyCycle
            T1 = promote_type(T1, Rational{Int})
            T2 = promote_type(T2, Rational{Int})
            T = promote_type(T, Rational{Int})
            @eval @test @test_logs min_level=Logging.Error (
                _typeof_promote(
                    IncoherentDutyCycle{$T1,$U1,$V1}(one($V1)),
                    IncoherentDutyCycle{$T2,$U2,$V2}(one($V2))
                )
            ) == IncoherentDutyCycle{$T,$U,$V}
        end
    end
end
