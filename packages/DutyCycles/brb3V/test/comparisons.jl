@testset "comparisons" begin
    # the default period
    defaultperiod = 1*s
    defaultdutycycle = 1//2
    # nominal durations for test cases with two phases
    ontime = defaultdutycycle * defaultperiod
    offtime = (1-defaultdutycycle) * defaultperiod
    # comparison operators to test
    operators = [
        # egal and not egal
        :≡, Symbol("==="), :!==,
        # equal and not equal
        Symbol("=="), :!=,
        # approximate equality and negated, approx. equality
        :isapprox, :≈, :≉
    ]
    negatedoperators = [:!==, :!=, :≉]
    Ints = [UInt8,Int8,Int16,Int32,Int64,Int128,BigInt]
    Exacts = copy(Ints)
    for T in Ints
        push!(Exacts, Rational{T})
    end
    Floats = [Float16, Float32, Float64, BigFloat]
    #Types = [Exacts; Ints]
    # dictionary to add descriptions to test values
    valuedesc = Dict{Number}{String}()
    # test helper: return the operator corresponing to op that does
    #              not imply a negation (e.g. :== istead of :!=)
    function unnegated(op::Symbol)
        if op == :!==
            return Symbol("===")
        elseif op == :!=
            return Symbol("==")
        elseif op == :≉
            return :≈
        elseif op in operators
            return op
        end
        throw(DomainError("unknown comparison operator :$op"))
    end
    # test helper: @eval the expression a $op b, plus some extra info
    #              to make op more readily identifiable in the ouput a
    #              failed test generates
    function testexpr(
        a::Number,
        op::Symbol,
        b::Number,
        expected_result_for_unnegated_op::Bool;
        kwargs...
    )
        desc = "no desc"
        if haskey(valuedesc, b)
            desc = valuedesc[b]
        end
        expected_result = xor(
            expected_result_for_unnegated_op,
            op != unnegated(op)
        )
        if length(kwargs) == 0
            if expected_result
                @eval @test begin
                    $desc; Base.$op($a, $b)
                end
            else
                @eval @test begin
                    $desc; !Base.$op($a, $b)
                end
            end
        else
            if expected_result
                @eval @test begin
                    $desc; Base.$op($a, $b; $kwargs...)
                end
            else
                @eval @test begin
                    $desc; !Base.$op($a, $b; $kwargs...)
                end
            end           
        end
    end
    # same but with a vector instead of a single value for b
    function testexpr(
        a::Number,
        op::Symbol,
        bs::Vector{<:Number},
        expected_result_for_unnegated_op::Bool;
        kwargs...
    )
        for b in bs
            testexpr(
                a, op, b,
                expected_result_for_unnegated_op;
                kwargs...
            )
        end
    end
    # helper to extract the kwargs variable expressing key word
    # arguments
    getkwargs(; kwargs...) = kwargs
    # test helper to perform tests on using given values; use exacting
    # type specifiers to catch bugs (via a MethodError) where an
    # unexpected promotion happened in the calling code
    function testcomparisons(
        d::T,
        magnitude::ValueT,
        degals::Vector{T},
        dequals::Vector{T},
        customtolerances::Vector{ValueT},
        d_approxequals::Function,
    ) where {
        ValueT<:Number,
        T<:DutyCycle{TimeT,PhaseT,ValueT} where {TimeT,PhaseT}
    }
        # a sample of values inequal to d
        dinequals = d_approxequals(
            magnitude,
            true;
            rtol=first(customtolerances)
        )
        # egal operator ≡ and ===, plus negated operator !== (Note: ≡
        # is currently a constant with value === in julia Base, but
        # keep the separate tests in case that ever changes)
        @testset "operator $op" for op in [:≡, Symbol("==="), :!==]
            @testset "egal args" begin
                testexpr(d, op, degals, true)
            end
            @testset "distinct but equal args" begin
                testexpr(d, op, dequals, false)
            end
            @testset "distinct and inequal args" begin
                testexpr(d, op, dinequals, false)
            end
        end
        @testset "operator $op" for op in [Symbol("=="), :!=]
            @testset "egal args" begin
                testexpr(d, op, degals, true)
            end
            @testset "distinct but equal args" begin
                testexpr(d, op, dequals, true)
            end
            @testset "distinct and inequal args" begin
                testexpr(d, op, dinequals, false)
            end
        end
        @testset "operator $op" for op in [:isapprox, :≈, :≉]
            @testset "egal args" begin
                testexpr(d, op, degals, true)
            end
            @testset "distinct but equal args" begin
                testexpr(d, op, dequals, true)
            end
            @testset "approx. equal args" begin
                testexpr(d, op, dinequals, true)
            end
            @testset "within rtol=$tol" for tol in customtolerances
                testexpr(
                    d,
                    op,
                    d_approxequals(magnitude, true; rtol=tol),
                    true;
                    rtol=tol
                )
            end
            @testset "outside rtol=$tol" for tol in customtolerances
                testexpr(
                    d,
                    op,
                    d_approxequals(magnitude, false; rtol=tol),
                    false;
                    rtol=tol
                )
            end
            @testset "within atol=$tol" for tol in customtolerances
                testexpr(
                    d,
                    op,
                    d_approxequals(magnitude, true; atol=tol),
                    true;
                    atol=tol
                )
            end
            @testset "outside atol=$tol" for tol in customtolerances
                testexpr(
                    d,
                    op,
                    d_approxequals(magnitude, false; atol=tol),
                    false;
                    atol=tol
                )
            end
        end
    end
#begin # To Do: remove
    # helper to populate test cases
    function pushcase!(
        cases::Vector{<:DutyCycle}, desc::String, x::AbstractDutyCycle
    )
        push!(cases, x)
        valuedesc[x] = desc
        return cases
    end
    pushcase!(
        cases::Vector{<:DutyCycle},
        desc::String,
        pairs...
    ) where {T<:Number, V<:Number} = begin
        pushcase!(cases, desc, cycle(pairs...))
    end
    @testset "Exact Types" begin
        # exact types (integers, rationals)
        @testset "$T" for T in Exacts
            offval = zero(T)
            # use a large value approximately half the type's maximum
            onval = one(T)
            if T <: BigInt
                onval = big(typemax(UInt128))^2
            elseif T <: Integer
                onval = T(div(typemax(T) - 1, 2))
            elseif T <: Rational{BigInt}
                intval = big(typemax(UInt128))^2
                onval = T(intval // (intval+1))
            elseif T <: Rational
                # construct an onval with numerator and denominator
                # set at approximately half of their respective maxima
                IntT = typeof(numerator(one(T)))
                intval = div(typemax(IntT) - 1, 2)
                onval = T(intval // (intval+1))
            else
                @test "tests for type $T are not implemented"
                break
            end

            d = cycle(ontime => onval, offtime => offval)
            # values that are expected to be egal (===) to d
            egals =
                Vector{DutyCycle{TT,PT,T} where {TT,PT}}(undef, 0)
            pushcase!(egals, "identical value", d)
            d2 = d;
            pushcase!(egals, "same value, assigned", d2)
            pushcase!(egals, "same value, copied", copy(d))
            # values that are expected to be equal (==) to d (but not
            # egal, i.e. not identical at bit level)
            equals =
                Vector{DutyCycle{TT,PT,T} where {TT,PT}}(undef, 0)
            pushcase!(equals,
                      "same args to constructor call",
                      ontime => onval, offtime => offval)
            if offval !== -offval
                pushcase!(equals,
                          "with negated zero as off-value",
                          ontime => onval, offtime => -offval)
            else
                @assert offval isa Rational || offval isa Integer
            end
            
        end
    end
    @testset "Floats" begin
        # floating point types
        @testset "$T" for T in Floats
            epsilon = eps(one(T))
            # the default approximate comparison tolerance
            default_tol = sqrt(epsilon)
            # a large but not excessively large on-value to allow
            # testing the difference between absolute and relative
            # tolerance; what is excessively large is limited by
            # numerical precision when combining it with absolute
            # tolerances
            onval = T(sqrt(1 / default_tol))
            offval = zero(T)
            # custom tolerance values, starting with the default value
            # for relative tolerances and only including values that
            # make sense given the precision of a type
            customtolerances = Vector{T}([
                default_tol; # IMPORTANT: default_tol must be the
                             # first value, as the case of no explicit
                             # tolerance depends on this
                filter(
                    tol -> tol >= default_tol,
                    [
                        # a very small number of tolerances to test,
                        # as adding more bloats the number of test
                        # cases
                        1e-6,
                        1e-1
                    ]
                )...
            ])
            # fraction of custom tolerance to be used to scale
            # variations expected to pass (e.g. close to but not quite
            # one to provide a "buffer" for numerical inaccuracies
            # when calculating the desired variation)
            justunder = one(T) - sqrt(default_tol)
            # same but for expected failure
            justover = one(T) / justunder *
                eps(one(T)) / eps(T(justunder))
            d = cycle(ontime => onval, offtime => offval)
            # values that are expected to be egal (===) to d
            egals =
                Vector{DutyCycle{TT,PT,T} where {TT,PT}}(undef, 0)
            pushcase!(egals, "identical value", d)
            d2 = d;
            pushcase!(egals, "same value, assigned", d2)
            pushcase!(egals, "same value, copied", copy(d))
            # values that are expected to be equal (==) to d (but not
            # egal, i.e. not identical at bit level)
            @assert offval !== -offval && offval == -offval
            equals =
                Vector{DutyCycle{TT,PT,T} where {TT,PT}}(undef, 0)
            pushcase!(equals,
                      "same args to constructor call",
                      ontime => onval, offtime => offval)
            pushcase!(equals,
                      "with negated zero as off-value",
                      ontime => onval, offtime => -offval)                
            # test cases for approximate comparison with d,
            # parametrized to provide a absolute(!) variation in phase
            # of (up to) pvar and a relative(!) variation in value of
            # (up to) vvar, and guarateed at least one variation of
            # comparable effect to having either one or the other, to
            # ensure strict inequality for all test cases
            function approxtestcases(apvar, rvvar, absolutevar::Bool)
                # multipliers
                mv = one(onval) + rvvar
                # additives
                ap = apvar
                av = rvvar * onval
                # the testcases to be populated
                cases =
                    Vector{DutyCycle{TT,PT,T} where {TT,PT}}(undef, 0)
                # begin populating test cases
                pushcase!(cases, "high when on",
                          ontime => onval * mv, offtime => offval)
                pushcase!(cases, "low when on",
                          ontime => onval / mv, offtime => offval)
                # return test cases
                return cases
            end
            getrtol(; rtol=missing, kwargs...) = rtol
            getatol(; atol=missing, kwargs...) = atol
            # values that are expected to be approximate equal to d
            # (but not equal) when compared with atol=atol, rtol=rtol
            function approxequals(
                magnitude::V, approx_equality::Bool; kwargs...
            ) where {V}
                atol = getatol(; kwargs...)
                rtol = getrtol(; kwargs...)
                if rtol === missing && atol === missing
                    @warn "both rtol and atol missing" rtol atol
                    rtol = sqrt(eps(one(V)))
                end
                # set absolute(!) variation in phase, apvar
                # and relative(!) variation in value, rvvar
                apvar = missing
                rvvar = missing
                mult = approx_equality ? justunder : justover
                if atol !== missing
                    # atol overrides any rtol that may be specified
                    apvar = V(mult * atol)
                    if magnitude != zero(magnitude)
                        rvvar = V(mult * atol/magnitude)
                    else
                        @warn "zero magnitude breaks test logic" mult atol magnitude
                        rvvar = zero(V)
                    end
                else
                    # only rtol is specified
                    @assert rtol isa Number
                    apvar = V(mult * rtol)
                    rvvar = V(mult * rtol)
                end
                # assert that for numbers themselves, isapprox works
                # as expected
                if approx_equality
                    @assert ≈(one(V), one(V) + apvar; kwargs...)
                    @assert ≈(one(V), one(V) - apvar; kwargs...)
                    @assert ≈(
                        magnitude, magnitude * (one(V) + rvvar);
                        kwargs...
                    )
                    @assert ≈(
                        magnitude, magnitude * (one(V) - rvvar);
                        kwargs...
                    )
                else
                    @assert ≉(one(V), one(V) + apvar; kwargs...)
                    @assert ≉(one(V), one(V) - apvar; kwargs...)
                    @assert ≉(
                        magnitude, magnitude * (one(V) + rvvar);
                        kwargs...
                    )
                    @assert ≉(
                        magnitude, magnitude * (one(V) - rvvar);
                        kwargs...
                    )
                end
                cases::Vector{DutyCycle{TT,PT,T} where {TT,PT}} =
                    approxtestcases(apvar, rvvar::V, atol !== missing)
                if approx_equality
                    # add more approximately equal cases
                    pushcase!(cases, "minimally high when on",
                              ontime => onval+eps(onval),
                              offtime => offval)
                    pushcase!(cases, "minimally low when on",
                              ontime => onval-eps(onval),
                              offtime => offval)
                end
                return cases
            end
            testcomparisons(
                d,
                onval,
                egals,
                equals,
                customtolerances,
                approxequals
            )
        end
    end
end
