# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module RiordanSquares

using Nemo, SeriesExpansion, Triangles

export ModuleRiordanSquares
export RiordanProduct, RiordanSquare
export T039599, T116392, T172094, T321620, T321621
export T321623, T321624, T322942

"""
The Riordan product is a map a, b ↦ [a, b] associating two formal power series a, b with a lower triangular matrix [a, b]. The Riordan square is the case a = b of the Riordan product. Formally we can describe the Riordan square as a transform RS: Z[[x]] ↦ Mat[Z] which maps power series over the integers to (lower triangular) integer matrices.

* RiordanProduct, RiordanSquare
* T039599, T116392, T172094, T321620, T321621, T321623, T321624, T322942

[Introduction to the Riordan Square](http://luschny.de/math/seq/RiordanSquare.html)
"""
const ModuleRiordanSquares = ""

"""
Return the Riordan array associated with the generating functions a and b.
"""
function RiordanProduct(a, b, dim, expo=false)
    A = Coefficients(a, dim)
    B = b == nothing ? A : Coefficients(b, dim)
    M = identity_matrix(QQ, dim)
    for k in 1:dim M[k, 1] = A[k] end

    for k in 2:dim, m in k+1:dim
        M[m, k] = sum(M[j+1, k-1]*B[m-j] for j in k-2:m-2)
    end
    #expo ? ExponentialWeights(M) : M
    toΔ(M)
end

"""
Return the Riordan array (Riordan product) ``a \times a``.
"""
RiordanSquare(a, n, expo=false) = RiordanProduct(a, nothing, n, expo)

"""
The Riordan square of the Catalan numbers.
"""
T039599(n) = RiordanSquare(G000108, n)

"""
The Riordan square of the central trinomial.
"""
T116392(n) = RiordanSquare(G002426, n)

"""
The Riordan square of the little Schröder numbers.
"""
T172094(n) = RiordanSquare(G001003, n)

"""
The Riordan square of the Riordan numbers (with 1 prepended).
"""
T321620(n) = RiordanSquare(G005043, n)

"""
The Riordan square of the Motzkin numbers.
"""
T321621(n) = RiordanSquare(G001006, n)

"""
The Riordan square of the large Schröder numbers.
"""
T321623(n) = RiordanSquare(G006318, n)

"""
The Riordan square of the Lucas numbers.
"""
T321624(n) = RiordanSquare(G000032, n)

"""
The Riordan square of the Jacobsthal numbers.
"""
T322942(n) = RiordanSquare(G001045, n)

#"""
#The Riordan square of the number of rooted bicubic maps.
#(Does not yet exist in the OEIS.)
#"""
# Tx(n) = RiordanSquare(G000257, n)

#START-TEST-########################################################

using Test

function test()
    @testset "RiordanSqr" begin
        a = T039599(5)
        b = [1, 1, 1, 2, 3, 1, 5, 9, 5, 1, 14, 28, 20, 7, 1]
        @test all(a .== b)

        a = T116392(5)
        b = [1, 1, 1, 3, 4, 1, 7, 13, 7, 1, 19, 42, 32, 10, 1]
        @test all(a .== b)

        a = T172094(5)
        b = [1, 1, 1, 3, 4, 1, 11, 17, 7, 1, 45, 76, 40, 10, 1]
        @test all(a .== b)

        a = T321620(5)
        b = [1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 3, 2, 1, 1]
        @test all(a .== b)

        a = T321621(5)
        b = [1, 1, 1, 2, 3, 1, 4, 8, 5, 1, 9, 21, 18, 7, 1]
        @test all(a .== b)

        ###############################################
        a = T321623(5)
        b = T321623(5)
        @test all(a .== b)

        a = T321624(5)
        b = [1, 1, 1, 3, 4, 1, 4, 10, 7, 1, 7, 24, 26, 10, 1]
        @test all(a .== b)

        a = T322942(5)
        b = [1, 1, 1, 1, 2, 1, 3, 5, 3, 1, 5, 12, 10, 4, 1]
        @test all(a .== b)
    end
end

function demo()
    println("\nT039599")
    T039599(5) |> ShowAsΔ

    println("\nT116392")
    T116392(5) |> ShowAsΔ

    println("\nT172094")
    T172094(5) |> ShowAsΔ

    println("\nT321620")
    T321620(5) |> ShowAsΔ

    println("\nT321621")
    T321621(5) |> ShowAsΔ

    println("\nT321623")
    T321623(5) |> ShowAsΔ

    println("\nT321624")
    T321624(5) |> ShowAsΔ

    println("\nT322942")
    T322942(5) |> ShowAsΔ
end

function perf()
    # @time
end

function main()
    test()
    demo()
    perf()
end

main()

end # module
