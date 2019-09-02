# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module DelehamDelta

using Nemo, NumberTheory, Triangles

export ModuleDelehamDelta
export DeléhamΔ, T084938, T060693, T106566, T094665, T090238, T225478
export T055883, T184962, T088969, T090981, T011117

"""
Philippe Deléham’s Δ-operation maps, similar to the Riordan product, two integer sequences on a lower triangular matrix.
It effectively computes a continued fraction depending on the two input sequences!

Applying Deléham's Δ-operation often gives an additional first column or an additional main diagonal in the resulting triangle compared to what is listed in the OEIS.

[Introduction to the Riordan Square](http://luschny.de/math/seq/RiordanSquare.html)

* DeléhamΔ, T084938, T060693, T106566, T094665, T090238, T225478, T055883, T184962, T088969, T090981, T011117
"""
const ModuleDelehamDelta = ""

"""
Return the product of two integer sequences introduced by Philippe Deléham in A084938.
"""
function DeléhamΔ(n::Int, S::Function, T::Function)
    n ≤ 0 && return fmpz[]
    R, x = PolynomialRing(ZZ, "x")
    A = [R(S(k) + x * T(k)) for k in 0:n - 2]
    C = [R(1) for i in 0:n]; C[1] = R(0)
    M = ZTriangle(n)
    m = 1

    for k in 0:n - 1
        for j in k + 1:-1:2
            C[j] = C[j - 1] + C[j + 1] * A[j - 1]
        end
        for j in 0:k
            M[m] = coeff(C[2], j)
            m += 1
        end
    end
    M
end

"""
Return the number of permutations of ``{1,2,...,n}`` having ``k`` cycles such that the elements of each cycle of the permutation form an interval. (Ran Pan)
"""
T084938(n::Int) = DeléhamΔ(n, i -> div(i + 1, 2), i -> 0^i)

"""
Return the number of lattice paths from ``(0,0)`` to ``(x,y)`` that never pass below ``y = x`` and use step set ``{(0,1), (1,0), (2,0), (3,0), ...}``.
"""
T011117(n::Int) = DeléhamΔ(n, i -> 0^i, i -> isodd(i) ? 1 : (i > 0 ? 2 : 0))

"""
Return the number of Schroeder paths (i.e., consisting of steps ``U=(1,1), D=(1,-1), H=(2,0)`` and never going below the x-axis) from ``(0,0)`` to ``(2n,0)``, having ``k`` peaks.
"""
T060693(n::Int) = DeléhamΔ(n, i -> 1, i -> isodd(i) ? 0 : 1)

"""
Return the the Catalan convolution triangle.
"""
T106566(n::Int) = DeléhamΔ(n, i -> i == 0 ? 0 : 1, i -> i == 0 ? 1 : 0)

"""
Return the number of increasing 0-2 trees (A002105) on ``2n`` edges in which the minimal path from the root has length ``k``.
"""
T094665(n::Int) = DeléhamΔ(n, i -> div(i * (i + 1), 2), i -> i + 1)

"""
Return the number of lists of ``k`` unlabeled permutations whose total length is ``n``.
"""
T090238(n::Int) = DeléhamΔ(n, i -> div(i, 2) + (isodd(i) ? 2 : 0), i -> i == 0 ? 1 : 0)

"""
Return the triangle ``4^k S_4(n, k)`` where ``S_m(n, k)`` are the Stirling-Frobenius cycle numbers of order ``m``.
"""
T225478(n::Int) = DeléhamΔ(n, i -> 2(i + 1) + (i + 1) % 2, i -> isodd(i) ? 0 : 4)

"""
Return the exponential transform of Pascal's triangle.
"""
T055883(n::Int) = DeléhamΔ(n, i -> isodd(i) ? div(i + 1, 2) : 1, i -> isodd(i) ? div(i + 1, 2) : 1)

"""
Return the number of Schroeder paths of length ``2n`` and having ``k`` ascents.
"""
T090981(n::Int) = DeléhamΔ(n, i -> i == 0 ? 1 : (isodd(i) ? 0 : 2), i -> isodd(i) ? 1 : 0)

"""
Return a triangle related to the median Euler numbers.
"""
T088969(n::Int) = DeléhamΔ(n, i -> i^2, i -> isodd(i) ? 3div(i, 2) + 2 : 5div(i, 2) + 1)

"""
Return the Bell transform of the Fubini numbers.
"""
T184962(n::Int) = DeléhamΔ(n, i -> div((i + 1) - (i + 1) % 2, 2 - (i + 1) % 2), i -> isodd(i) ? 0 : 1)

#START-TEST-########################################################
# References to the OEIS A-numbers are always approximately only!

using Test

function test()

    Data = Dict{Int, Array{fmpz}}(
        084938 => [1, 0, 1,  0,  1,  1,   0,   2,   2,  1],
        060693 => [1, 1, 1,  2,  3,  1,   5,  10,   6,  1],
        106566 => [1, 0, 1,  0,  1,  1,   0,   2,   2,  1],
        094665 => [1, 0, 1,  0,  1,  3,   0,   4,  15, 15],
        090238 => [1, 0, 1,  0,  2,  1,   0,   6,   4,  1],
        225478 => [1, 3, 4, 21, 40, 16, 231, 524, 336, 64],
        055883 => [1, 1, 1,  2,  4,  2,   5,  15,  15,  5],
        184962 => [1, 0, 1,  0,  1,  1,   0,   3,   3,  1],
        088969 => [1, 0, 1,  0,  1,  3,   0,   5,  20, 21],
        090981 => [1, 1, 0,  1,  1,  0,   1,   4,   1,  0],
        011117 => [1, 1, 0,  1,  1,  0,   1,   2,   3,  0]
    )

    # [0] 1
    # [1] 1    1
    # [2] 2    4     2
    # [3] 5    15    15    5
    # [4] 15   60    90    60    15
    # [5] 52   260   520   520   260   52
    # [6] 203  1218  3045  4060  3045  1218  203

    @testset "Deléham" begin

        n = 7
        B = [bell(n) * binomial(n, j) for j in 0:n]
        R = Row(T055883(n+1), n)
        @test all(B .== R)

        a = fmpz[0, 5040, 2208, 828, 272, 70, 12, 1]
        b = Row(T090238(8), 7)
        @test all(a .== b)

        SeqNum(seq) =  parse(Int, string(seq)[end-5:end])
        Seq = [T084938, T060693, T106566, T094665, T090238, T225478, T055883,
              T184962, T088969]

        for seq in Seq
            S = seq(20)
            anum = SeqNum(seq)
            data = Data[anum]
            @test all(S[1:9] .== data[1:9])
        end
    end
end

function demo()
    dim = 5
    for n in 0:dim
        println(T055883(n))
    end

    ShowAsΔ(T055883(dim))
end

"""
T225478(100) :: 0.071950 seconds (15.27 k allocations: 638.438 KiB)
T055883(100) :: 0.076918 seconds (15.27 k allocations: 638.438 KiB)
"""
function perf()
    GC.gc()
    @time T225478(100)
    @time T055883(100)
end

function main()
    test()
    demo()
    perf()
end

main()

end # module
