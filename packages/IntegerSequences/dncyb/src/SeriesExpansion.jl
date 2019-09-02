# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module SeriesExpansion
using Nemo

export ModuleSeriesExpansion
export Coefficients, G000045, G000257, L000257
export G000032, L000032, G000073, L000073, G000108, L000108, G000957, L000957
export G001003, L001003, G001006, L001006, G001045, L001045, G002426, L002426
export G005043, L005043, G006318, G068875, L068875

"""
The generating functions of various combinatorial and number-theoretic functions.

* Coefficients, G000045, G000257, L000257, G000032, L000032, G000073, L000073, G000108, L000108, G000957, L000957, G001003, L001003, G001006, L001006, G001045, L001045, G002426, L002426, G005043, L005043, G006318, G068875, L068875
"""
const ModuleSeriesExpansion = ""

"""
Return the list of coefficients of the power series s.
"""
function Coefficients(s, len)
    R, x = PowerSeriesRing(ZZ, len + 2, "x")
    ser = s(x)
    [coeff(ser, k) for k in 0:len-1]
end

"""
The generating function of the Lucas numbers.
"""
G000032(x) = 1 + divexact(x*(1 + 2x), 1 - x - x^2)

"""
Return a list of Lucas numbers.
"""
L000032(n) = Coefficients(G000032, n)

"""
The generating function of the Fibonacci numbers.
"""
G000045(x) = divexact(x, 1 - x - x^2)

"""
The generating function of the Tribonacci numbers.
"""
G000073(x) = inv(1 - x - x^2 - x^3)

"""
Return a list of Tribonacci numbers.
"""
L000073(n) = Coefficients(G000073, n)

"""
The generating function of the Catalan numbers.
"""
G000108(x) = divexact(1 - sqrt(1 - 4x), 2x)

"""
Return a list of Catalan numbers.
"""
L000108(n) = Coefficients(G000108, n)

"""
The generating function of the number of rooted bicubic maps.
"""
G000257(x) = divexact(sqrt((1 - 8x)^3) + 8x^2 + 12x - 1, 32x^2)

"""
Return a list of the number of rooted bicubic maps.
"""
L000257(n) = Coefficients(G000257, n)

"""
The generating function of the Fine numbers (with a(0) = 1).
"""
G000957(x) = 1 + divexact(1 - sqrt(1 - 4x), 3 - sqrt(1 - 4x))

"""
Return a list of Fine numbers.
"""
L000957(n) = Coefficients(G000957, n)

"""
The generating function of the little Schröder numbers.
"""
G001003(x) = divexact(1 + x - sqrt(1 - 6x + x^2), 4x)

"""
Return a list of little Schröder numbers.
"""
L001003(n) = Coefficients(G001003, n)

"""
The generating function of the Motzkin numbers.
"""
G001006(x) = divexact(1 - x - sqrt(1 - 2x - 3x^2), 2x^2)

"""
Return a list of Motzkin numbers.
"""
L001006(n) = Coefficients(G001006, n)

"""
The generating function of the Jacobsthal numbers (with a(0) = 1).
"""
G001045(x) = divexact(2x^2 - 1, (x + 1)*(2x - 1))

"""
Return a list of Jacobsthal numbers.
"""
L001045(n) = Coefficients(G001045, n)

"""
The generating function of the central trinomial.
"""
G002426(x) = inv(sqrt(1 - 2x - 3x^2))

"""
Return a list of the central trinomials.
"""
L002426(n) = Coefficients(G002426, n)

"""
The generating function of the Riordan numbers with 1 prepended.
"""
G005043(x) = 1 + divexact(2x , 1 + x + sqrt(1 - 2x - 3x^2))

"""
Return a list of the Riordan numbers (1 prepended).
"""
L005043(n) = Coefficients(G005043, n)

"""
The generating function of the large Schröder numbers.
"""
G006318(x) = divexact(1 - x - sqrt(1 - 6x + x^2), 2x)

# already defined in module 'SelfConvolutive'.
#L006318(n) = Coefficients(G006318, n)

"""
The generating function of twice the Catalan numbers.
"""
G068875(x) = shift_right(1 - x - sqrt(1 - 4x), 1)

"""
Return a list of twice the Catalan numbers.
"""
L068875(n) = Coefficients(G068875, n)

#START-TEST-########################################################

using Test, SeqUtils

function test()
    @testset "SeriesCoefficients" begin

        a = L000032(14)
        b = [1, 1, 3, 4, 7, 11, 18, 29, 47, 76, 123, 199, 322, 521]
        @test all(a .== b)

        a = L000073(15)
        b = [1, 1, 2, 4, 7, 13, 24, 44, 81, 149, 274, 504, 927, 1705, 3136]
        @test all(a .== b)

        a = L000108(13)
        b = [1, 1, 2, 5, 14, 42, 132, 429, 1430, 4862, 16796, 58786, 208012]
        @test all(a .== b)

        a = L000257(12)
        b = [1, 1, 3, 12, 56, 288, 1584, 9152, 54912, 339456, 2149888, 13891584]
        @test all(a .== b)

        a = L000957(13)
        b = [1, 1, 0, 1, 2, 6, 18, 57, 186, 622, 2120, 7338, 25724]
        @test all(a .== b)

        a = L001003(12)
        b = [1, 1, 3, 11, 45, 197, 903, 4279, 20793, 103049, 518859, 2646723]
        @test all(a .== b)

        a = L001006(14)
        b = [1, 1, 2, 4, 9, 21, 51, 127, 323, 835, 2188, 5798, 15511, 41835]
        @test all(a .== b)

        a = L001045(13)
        b = [1, 1, 1, 3, 5, 11, 21, 43, 85, 171,341, 683, 1365]
        @test all(a .== b)

        a = L002426(12)
        b = [1, 1, 3, 7, 19, 51, 141, 393, 1107, 3139, 8953, 25653]
        @test all(a .== b)

        a = L005043(12)
        b = [1, 1, 0, 1, 1, 3, 6, 15, 36, 91, 232, 603]
        @test all(a .== b)

        xL006318(n) = Coefficients(G006318, n)
        a = xL006318(12)
        b = [1, 2, 6, 22, 90, 394, 1806, 8558, 41586, 206098, 1037718, 5293446]
        @test all(a .== b)

        a = L068875(10)
        b = [1, 2, 4, 10, 28, 84, 264, 858, 2860, 9724]
        @test all(a .== b)
    end
end

function demo()
    L068875(12) |> println
end

"""
L068875(1000)
    0.025675 seconds (1.03 k allocations: 24.813 KiB)
"""
function perf()
    @time L068875(1000)
end

function main()
    test()
    demo()
    perf()
end

main()

end # module
