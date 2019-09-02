using Test
using NonPromoting

# Create and examine from floating types
for T in [Float16, Float32, Float64, BigFloat]
    for x in T[1//3, 0//1, -3//2, pi]
        y1 = NP{T}(x)
        r1 = convert(T, y1)
        @test isequal(r1, x)

        y2 = NP(x)
        r2 = convert(T, y2)
        @test isequal(r2, x)
    end
end

# Create and examine from integer types
for T in [Float16, Float32, Float64, BigFloat]
    for L in [UInt8, UInt16, Int32, Int64, Int128, BigInt]
        makeL = L ∘ (L<:Unsigned ? abs : identity)
        for x in makeL.([1, 0, -3])
            y = NP{T}(x)
            r = convert(T, y)
            @test isequal(r, T(x))
        end
    end
end

# Create and examine from rational types
for T in [Float16, Float32, Float64, BigFloat]
    for L in [Rational{S} for S in [Int32, Int64, Int128, BigInt]]
        for x in L[1//3, 0//1, -3//2]
            y = NP{T}(x)
            r = convert(T, y)
            @test isequal(r, T(x))
        end
    end
end

# Ensure that operations on NP again return NP
for T in [Float16, Float32, Float64, BigFloat]
    for fun in [one, zero]
        @test typeof(fun(NP{T})) === NP{T}
    end

    for fun in [+, -, abs, sign]
        @test typeof(fun(NP{T}(1))) === NP{T}
    end

    for fun in [+, -, *, /, hypot]
        @test typeof(fun(NP{T}(1), NP{T}(2))) === NP{T}
    end
end

# Ensure binary functions don't promote
for fun in [:(-), :(/), :(\), :(^),
            :atan, :copysign, :hypot, :modf, :rem,
            :(==), :(!=), :(<), :(>), :(<=), :(>=),
            :(+), :(*), :max, :min]
    for T1 in [Float16, Float32, Float64, BigFloat]
        for T2 in [Float16, Float32, Float64, BigFloat]
            x1 = T1(1)
            x2 = T2(2)
            x3 = T1(3)
            y1 = NP(x1)
            y2 = NP(x2)
            y3 = NP(x3)
    
            @test isequal(x1 + x2, x3)
            if T1 === T2
                @test isequal(y1 + y2, y3)
            else
                @test_throws Union{ErrorException, MethodError} (y1 + y2)
            end
            @test_throws Union{ErrorException, MethodError} (x1 + y2)
            @test_throws Union{ErrorException, MethodError} (y1 + x2)
        end
    end
end

# Check output
for T in [Float16, Float32, Float64, BigFloat]
    for x in T[1//3, 0//1, -3//2, pi]
        buf1 = IOBuffer()
        buf2 = IOBuffer()
        show(buf1, NP(x))
        show(buf2, x)
        str1 = String(take!(buf1))
        str2 = String(take!(buf2))
        @test str1 == str2
    end
end
