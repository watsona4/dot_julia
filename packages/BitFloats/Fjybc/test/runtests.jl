using BitFloats, Test

using BitFloats: BigFloat_mpfr, BuiltinInts, Int80, UInt80, decompose, explicit_bit,
                 exponent_half, exponent_mask, exponent_one, sign_mask, significand_mask,
                 uinttype, uniontypes

@testset "definitions" begin
    @test @isdefined Float80
    @test @isdefined UInt80
    @test @isdefined Float128
    @test sizeof(Float80)  == 10
    @test sizeof(UInt80)   == 10
    @test sizeof(Float128) == 16
    @test Float80  <: AbstractFloat
    @test UInt80   <: Unsigned
    @test Float128 <: AbstractFloat
    @test isprimitivetype(Float80)
    @test isprimitivetype(UInt80)
    @test isprimitivetype(Float128)
    @test uinttype(Float80)  == UInt80
    @test uinttype(Float128) == UInt128
end

# generate a random float in the whole range
function _rand(T::Type)
    r = rand(uinttype(T))
    s = r & significand_mask(T)
    e = r & exponent_mask(T)
    if T === Float80
        s >>= 1 # delete explicit bit
        if e != 0
            s |= explicit_bit(T)
        end
    end
    reinterpret(T, r & sign_mask(T) | e | s)
end

@testset "traits" begin
    @test explicit_bit() == explicit_bit(Float80) isa UInt80
    for T in (Float80, Float128)
        for ufun ∈ (sign_mask, exponent_mask, exponent_one, significand_mask)
            @test ufun(T) isa uinttype(T)
        end
        for ffun ∈ (eps, floatmin, floatmax, typemin, typemax)
            @test ffun(T) isa T
        end
        x = _rand(T)
        # @test floatmin(T) <= x <= floatmax(T)
        # @test nextfloat(T(1)) - T(1) == eps(T)
    end
    @test Inf80  isa Float80
    @test NaN80  isa Float80
    @test Inf128 isa Float128
    @test NaN128 isa Float128
    @test precision(Float80)  == 64
    @test precision(Float128) == 113
    @test Inf80  == typemax(Float80)  == -typemin(Float80)
    @test Inf128 == typemax(Float128) == -typemin(Float128)
    @test isnan(NaN80)
    @test isnan(NaN128)
    @test !isnan(_rand(Float80)) # very unlikely to fail
    @test !isnan(_rand(Float128))
    @test isinf(Inf80)
    @test isinf(Inf128)
    @test !isinf(_rand(Float80))
    @test !isinf(_rand(Float128))
end

@testset "exponent & significand" begin
    for F = (Float80, Float128)
        for k = -8.0:8.0
            n = 2.0^k
            x = rand(F) + 1
            @test exponent(n*x) == k
            @test significand(n*x) == significand(x)
        end
        @test significand(zero(F)) == zero(F)
        @test significand(F(NaN)) === F(NaN)
        @test significand(F(Inf)) === F(Inf)
        @test significand(F(-Inf)) === F(-Inf)
        @test_throws DomainError exponent(zero(F))
        @test_throws DomainError exponent(F(NaN))
        @test_throws DomainError exponent(F(Inf))
        @test_throws DomainError exponent(F(-Inf))
    end
end

@testset "nextfloat" begin
    for F = (Float80, Float128)
        while (x = _rand(F); isnan(x)) end
        setprecision(precision(x)) do
            b = BigFloat(x)
            @test x == b
            y = nextfloat(x)
            @test issubnormal(y) || issubnormal(x) || nextfloat(b) == y
            y = prevfloat(y)
            @test y == x
            y = prevfloat(y)
            @test issubnormal(y) || issubnormal(x) || prevfloat(b) == y
            @test nextfloat(y) == x
        end
    end
end

@testset "issubnormal" begin
    for F = (Float80, Float128)
        x = floatmin(F)
        @test !issubnormal(x)
        @test !issubnormal(-x)
        @test issubnormal(prevfloat(x))
        @test issubnormal(nextfloat(-x))
        @test !issubnormal(rand(F))
    end
end

@testset "ldexp & eps" begin
    for F = (Float80, Float128)
        x = _rand(F)
        b = big(x)
        d = 2^rand(1:16)
        n = rand(-d:d)
        r = ldexp(b, n)
        @test ldexp(x, n) == F(r) # conversion to F, in case of under or overflow

        # eps
        @test eps(F) == eps(F(1))
        @test isnan(eps(F(NaN)))
        @test isnan(eps(F(Inf)))
        @test isnan(eps(F(-Inf)))
    end
end

@testset "conversions" begin
    for F = (Float80, Float128)
        for T = (uniontypes(BuiltinInts)..., Float16, Float32, Float64, Float80, Float128)
            t = rand(T)
            @test F(t) isa F
            T == Bool && continue
            if T <: Integer
                @test unsafe_trunc(T, F(t)) isa T
                @test trunc(T, F(t)) isa T
                @test trunc(T, F(2.3)) == 2
                if T <: Signed
                    @test trunc(T, F(-2.3)) == -2
                else
                    @test_throws InexactError trunc(T, F(-2.3))
                end
                if F != Float128 # BROKEN
                    @test_throws InexactError T(F(2.3))
                end

                @test promote_type(F, T) == F
            else
                @test T(F(t)) isa T
                @test isnan(F(T(NaN)))
                @test isnan(T(F(NaN)))
                @test isinf(F(T(Inf)))
                @test isinf(T(F(Inf)))
                @test isinf(F(T(-Inf)))
                @test isinf(T(F(-Inf)))

                R = sizeof(T) < sizeof(F) ? F : T
                @test promote_type(F, T) == R
                @test F(zero(T)) == T(zero(F)) == 0
            end
            @test one(F) + one(T) === promote_type(F, T)(2)
        end
        @test one(F) isa F
        @test zero(F) isa F
        x = _rand(F)
        @test reinterpret(Unsigned, x) === reinterpret(uinttype(F), x)
        @test reinterpret(Signed, x) === reinterpret(F == Float80 ? Int80 : Int128, x)
        @test trunc(Signed, F(1.2)) === 1
        @test trunc(Integer, F(1.2)) === 1
        @test trunc(Unsigned, F(1.2)) === UInt(1)
        @test Signed(F(1)) === 1
        @test Unsigned(F(1)) === UInt(1)
        if F != Float128 #BROKEN
            @test_throws InexactError Signed(F(1.2))
            @test_throws InexactError Unsigned(F(1.2))
        end
        # BigFloat
        @test BigFloat(F(1)) == 1.0
        @test isnan(BigFloat(F(NaN)))
        @test BigFloat(F(Inf)) == Inf
        @test BigFloat(F(-Inf)) == -Inf
        x = rand(Int32)+rand()
        @test BigFloat(F(x)) == x
        @test F(BigFloat(F(x))) === F(x)
        y = _rand(F)
        @test isequal(F(BigFloat(y)), y)
    end
    x = _rand(Float128)
    @test isequal(BigFloat(x), BigFloat_mpfr(x))
end

@testset "round" begin
    for F = (Float80,) # broken for Float128
        @test round(F(1.2), RoundToZero) == F(1.0)
        @test round(F(1.2), RoundNearest) == F(1.0)
        @test round(F(1.2), RoundDown) == F(1.0)
        @test round(F(1.2), RoundUp) == F(2.0)
        @test round(F(1.8), RoundToZero) == F(1.0)
        @test round(F(1.8), RoundNearest) == F(2.0)
        @test round(F(1.8), RoundDown) == F(1.0)
        @test round(F(1.8), RoundUp) == F(2.0)
    end
end

@testset "comparisons" begin
    for F = (Float80, Float128)
        x, y = _rand(F), _rand(F)
        for op = (==, !=, <, <=, >, >=, isless, isequal)
            @test op(x, y) isa Bool
        end
        @test F(1) == F(1)
        @test F(1) != F(2)
        @test F(1) <  F(2)
        @test F(1) <= F(2)
        @test F(1) <= F(1)
        @test F(2) >  F(1)
        @test F(2) >= F(1)
        @test F(1) >= F(1)
        @test (x == y) == !(x != y)
        @test !(F(1) == F(2))
        @test !(F(1) != F(1))
        @test isequal(x, x)
        @test isequal(y, y)
        @test isequal(x, y) || isless(x, y) || isless(y, x)
        N = F(NaN)
        @test N != N
        @test isequal(N, N)
        @test !(N == N)
    end
end

@testset "arithmetic" begin
    for T = (Float80, Float128)
        n = rand(Int)
        for op = (*, /, +, -, rem, ^)
            for randfun = (_rand, rand)
                a, b = randfun(T), randfun(T)
                randfun == _rand && op == (^) && T == Float128 && continue # BUG crash otherwise
                r = op(a, b)
                @test r isa T
                op == (^) && T == Float128 && continue # BUG crash otherwise
                @test op(a, n) isa T
            end
        end
        x = _rand(T)
        @test -x  isa T
        @test -(-x) == x
        @test x >= 0 ? x == abs(x) : x == -abs(x)
        @test abs(T(-1)) == T(1)
        @test abs(T(1)) == T(1)
        @test T(2)^3 == 8
        @test T(2)^-1.0 == 0.5
        # LLVM intrinsics only called for Float80, otherwise conversion to BigFloat
        @test log2(T(16)) == 4
        @test log2(T(32)) == 5
        @test exp2(T(10)) == 1024
        @test sqrt(T(16)) == 4
        @test sqrt(T(25)) == 5
        # ≈ for sin/cos because this is not exact with Float128, due to intermediate conversion to BigFloat
        @test sin(T(big(pi)/2)) ≈ 1.0
        @test sin(T(-big(pi)/2)) ≈ -1.0
        @test cos(T(big(pi))) ≈ -1.0
        @test cos(T(0)) ≈ 1.0
        @test exp(T(0)) == 1
        @test exp(T(1)) ≈ exp(1)
        @test log(T(exp(1))) ≈ 1 atol=10^-16
        @test log10(T(10)) == 1.0
        T == Float128 && continue
        @test log(T(1)) == 0 # segfaults for Float128
    end
end

@testset "hashing" begin
    for T = (Float80, Float128)
        x = _rand(T)
        num, pow, den = BitFloats.decompose(x)
        # TODO: WAT? this intermediate value y needs to be computed for the test to not fail
        y = T(num) * T(2)^pow / den
        @test T(num) * T(2)^pow / den == x
    end
    n = rand(Int)
    @test hash(n) == hash(Float80(n)) == hash(Float128(n))
    f = _rand(Float64)
    @test hash(f) == hash(Float80(f)) == hash(Float128(f))
end

@testset "rand" begin
    for T = (Float80, Float128)
        x = rand(T)
        @test x isa T
        u = reinterpret(uinttype(T), x)
        @test u & sign_mask(T) == 0
        u2 = reinterpret(uinttype(T), (rand(T) + one(T)))
        u2 &= exponent_mask(T)
        if T == Float80
            u2 |= explicit_bit(T)
        end
        @test u2 == exponent_one(T)
    end
end

@testset "misc" begin
    for F = (Float80, Float128)
        x = _rand(F)
        @test bswap(x) !== x
        @test bswap(bswap(x)) === x

        @test "$(F(12))" == "12.0"
    end
end
