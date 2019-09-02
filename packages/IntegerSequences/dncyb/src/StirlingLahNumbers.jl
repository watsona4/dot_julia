# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module StirlingNumbers

using Nemo, IterTools, Triangles

export ModuleStirlingNumbers
export I132393, L132393, V132393, M132393
export I048993, L048993, V048993, M048993
export I271703, L271703, V271703, M271703
export I094587, L094587, V094587, M094587
export I008279, L008279, V008279, M008279
# export Lah, StirlingSet, StirlingCycle

"""
* I132393, L132393, V132393, M132393, I048993, L048993, V048993, M048993, I271703, L271703, V271703, M271703, I094587, L094587, V094587, M094587, I008279, L008279, V008279, M008279
"""
const ModuleStirlingNumbers = ""

"""
Recurrence for A132393, StirlingCycle numbers.
"""
function R132393(n::Int, k::Int, prevrow::Function)
    (k == 0 && n == 0) && return ZZ(1)
    (n - 1)*prevrow(k) + prevrow(k - 1)
end
"""
Recurrence for A048993, StirlingSet numbers.
"""
function R048993(n::Int, k::Int, prevrow::Function)
    (k == 0 && n == 0) && return ZZ(1)
    k*prevrow(k) + prevrow(k - 1)
end
"""
Recurrence for A271703, Lah numbers.
"""
function R271703(n::Int, k::Int, prevrow::Function)
    (k == 0 && n == 0) && return ZZ(1)
    (k - 1 + n)*prevrow(k) + prevrow(k - 1)
end
"""
Recurrence for A094587.
"""
function R094587(n::Int, k::Int, prevrow::Function)
    (k == 0 && n == 0) && return ZZ(1)
    (n - k)*prevrow(k) + prevrow(k - 1)
end
"""
Recurrence for A008279. Number of permutations of n things k at a time.
"""
function R008279(n::Int, k::Int, prevrow::Function)
    (k == 0 && n == 0) && return ZZ(1)
    prevrow(k) + k*prevrow(k - 1)
end
"""
Iterates over the first n rows of `A132393`.
"""
I132393(n) = RecTriangle(n, R132393)
"""
Iterates over the first n rows of `A048993`.
"""
I048993(n) = RecTriangle(n, R048993)
"""
Iterates over the first n rows of `A271703`.
"""
I271703(n) = RecTriangle(n, R271703)
"""
Iterates over the first n rows of `A094587`.
"""
I094587(n) = RecTriangle(n, R094587)
"""
Iterates over the first n rows of `A008279`.
"""
I008279(n) = RecTriangle(n, R008279)
"""
Lists the first n rows of `A132393` by concatenating.
"""
L132393(n) = vcat(I132393(n)...)
"""
Lists the first n rows of `A048993` by concatenating.
"""
L048993(n) = vcat(I048993(n)...)
"""
Lists the first n rows of `A271703` by concatenating.
"""
L271703(n) = vcat(I271703(n)...)
"""
Lists the first n rows of `A094587` by concatenating.
"""
L094587(n) = vcat(I094587(n)...)
"""
Lists the first n rows of `A008279` by concatenating.
"""
L008279(n) = vcat(I008279(n)...)
"""
Return the triangular array as a square matrix with dim rows.
"""
M132393(dim) = fromΔ(I132393(dim))
"""
Return the triangular array as a square matrix with dim rows.
"""
M048993(dim) = fromΔ(I048993(dim))
"""
Return the triangular array as a square matrix with dim rows.
"""
M271703(dim) = fromΔ(I271703(dim))
"""
Return the triangular array as a square matrix with dim rows.
"""
M094587(dim) = fromΔ(I094587(dim))
"""
Return the triangular array as a square matrix with dim rows.
"""
M008279(dim) = fromΔ(I008279(dim))
"""
Return row n of A132393 based on the iteration `I132393`(n).
"""
V132393(n) = nth(I132393(n+1), n+1)
"""
Return row n of A048993 based on the iteration `I048993`(n).
"""
V048993(n) = nth(I048993(n+1), n+1)
"""
Return row n of A271703 based on the iteration `I271703`(n).
"""
V271703(n) = nth(I271703(n+1), n+1)
"""
Return row n of A094587 based on the iteration `I094587`(n).
"""
V094587(n) = nth(I094587(n+1), n+1)
"""
Return row n of A008279 based on the iteration `I008279`(n).
"""
V008279(n) = nth(I008279(n+1), n+1)

#START-TEST-########################################################

using Test, Combinatorics

function test()

    @testset "Stirling1" begin

        for (n, S1) in enumerate(I132393(10))
            SC = [stirlings1(n-1, k) for k in 0:n-1]
            @test S1 == SC
        end
    end

    @testset "Stirling2" begin

        for (n, S2) in enumerate(I048993(10))
            SC = [stirlings2(n-1, k) for k in 0:n-1]
            @test S2 == SC
        end
    end
end # test

function demo()
    for row in I132393(9) println(row) end
    println()

    for n in 0:8 println(n, ": ", V132393(n)) end
    println()

    ShowAsΔ(I132393(9), "\t")

    println(L132393(9))
    println()

    ShowAsMatrix(I132393(9))
    println()

    println(M132393(9))
    println()

    println(V132393(8))
    println()

    # ===================================

    for row in I048993(9) println(row) end
    println()

    for n in 0:8 println(n, ": ", V048993(n)) end
    println()

    ShowAsΔ(I048993(9), "\t")

    println(L048993(9))
    println()

    ShowAsMatrix(I048993(9))
    println()

    println(M048993(9))
    println()

    println(V048993(8))
    println()

    # ===================================

    for row in I008279(9) println(row) end
    println()

    for n in 0:8 println(n, ": ", V008279(n)) end
    println()

    ShowAsΔ(I008279(9), "\t")

    println(L008279(9))
    println()

    ShowAsMatrix(I008279(9))
    println()

    println(M008279(9))
    println()

    println(V008279(8))
    println()
end

"""
(for row in I132393(500) end)
    0.246288 seconds (379.25 k allocations: 8.748 MiB)
"""
function perf()
    GC.gc()
    @time (for row in I132393(500) end)
    GC.gc()
    @time (for row in I048993(500) end)
    GC.gc()
    @time (for row in I271703(500) end)
end

function main()
    test()
    demo()
    perf()
end

main()

end # module

#=
1;
0,    1;
0,    1,     1;
0,    2,     3,     1;
0,    6,    11,     6,    1;
0,   24,    50,    35,   10,    1;
0,  120,   274,   225,   85,   15,   1;
0,  720,  1764,  1624,  735,  175,  21,  1;
0, 5040, 13068, 13132, 6769, 1960, 322, 28, 1;

1
0  1
0  1   1
0  1   3     1
0  1   7     6     1
0  1   15    25    10     1
0  1   31    90    65     15     1
0  1   63    301   350    140    21    1
0  1   127   966   1701   1050   266   28   1

1
0  1
0  2       1
0  6       6       1
0  24      36      12      1
0  120     240     120     20      1
0  720     1800    1200    300     30      1
0  5040    15120   12600   4200    630     42    1
0  40320   141120  141120  58800   11760   1176  56   1

1
1       1
2       2       1
6       6       3       1
24      24      12      4       1
120     120     60      20      5      1
720     720     360     120     30     6     1
5040    5040    2520    840     210    42    7    1
40320   40320   20160   6720    1680   336   56   8    1

1
1  1
1  2  2
1  3  6   6
1  4  12  24   24
1  5  20  60   120  120
1  6  30  120  360  720   720
1  7  42  210  840  2520  5040  5040
1  8  56  336  1680 6720  20160 40320  40320
=#
