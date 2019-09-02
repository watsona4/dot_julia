# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module Partitions

export ModulePartitions
export Partition, V080577

"""
An alternative to Combinatorics.partitions.

For n = 100 the benchmark shows:

* 167.598273 seconds (15 allocations: 4.813 KiB)
*  86.960344 seconds (381.14 M allocations:  48.735 GiB, 11.29% gc time)

Our function takes twice as long but the Combinatorics's function takes vastly more space.

* Partition, V080577
"""
const ModulePartitions = ""

"""
Generates the integer partitions of ``n`` in lexicographic order. Ported from Wilf/Nijenhuis "Combinatorial Algorithms". (cf. A080577).
"""
function NEXPAR(N::Int)
    PAR = Array{Int}(undef, N)
    R = Dict{Int,Int}()
    M = Dict{Int,Int}()
    NLAST = 0
    D = 0
@label(L10)
    N == NLAST && @goto(L20)
    NLAST = N
@label(L30)
    S = N
    D = 0
@label(L50)
    D = D + 1
    R[D] = S
    M[D] = 1
@label(L40)
    MTC = M[D] ≠ N
    fill!(PAR, 0)
    K = 0
    for I in 1:D, J in 1:M[I]
        K = K + 1
        PAR[K] = R[I]
    end
    VISIT(PAR)
    ! MTC && return
    @goto(L10)
@label(L20)
    ! MTC && @goto(L30)
    SUM = 1
    R[D] > 1 && @goto(L60)
    SUM = M[D] + 1
    D = D - 1
@label(L60)
    F = R[D] - 1
    M[D] == 1 && @goto(L70)
    M[D] = M[D] - 1
    D = D + 1
@label(L70)
    R[D] = F
    M[D] = 1 + div(SUM, F)
    S = SUM % F
    S == 0 && @goto(L40)
    @goto(L50)
end

"""
Prints the partitions given in the format used in function NEXPAR.
"""
function VISIT(P)
    # comment out when benchmarking
    println(P)
end

"""
Generates the integer partitions of ``n`` in graded reverse lexicographic order, the canonical ordering of partitions.
"""
Partition(n) = NEXPAR(n)

"""
Generates the integer partitions of ``n`` in graded reverse lexicographic order, the canonical ordering of partitions.
"""
V080577(n) = NEXPAR(n)

#START-TEST-########################################################

function test()
    V080577(7)
    println()
end

function demo()
    for i in 1:6
        Partition(i)
        println()
    end
end

"""
i=10:    0.000021 seconds (9 allocations:  1.344 KiB)
i=20:    0.000303 seconds (9 allocations:  1.422 KiB)
i=30:    0.002985 seconds (9 allocations:  1.516 KiB)
i=40:    0.024671 seconds (9 allocations:  1.578 KiB)
i=50:    0.141849 seconds (9 allocations:  1.672 KiB)
i=60:    0.700077 seconds (9 allocations:  1.750 KiB)
i=70:    3.109317 seconds (15 allocations: 4.594 KiB)
i=80:   12.719695 seconds (15 allocations: 4.656 KiB)
i=90:   47.378861 seconds (15 allocations: 4.734 KiB)
i=100: 167.598273 seconds (15 allocations: 4.813 KiB)
"""

# using Combinatorics
function perf()

    # -- first comment out println in VISIT
    #for i in 10:10:100
    #    print("i=", i, ": ")
    #    @time Partition(i)
    #end

    # -- For comparison (in particular note the allocations!)
    #for i in 10:10:100
    #    print("$i : ")
    #    @time (for p in Combinatorics.partitions(i) p end)
    #end
end

function main()
    test()
    demo()
    perf()
end

main()

end # module

#=
using Combinatorics:

10 :   0.000011 seconds (    84   allocations:   5.688 KiB)
20 :   0.000133 seconds (  1.25 k allocations:  97.469 KiB)
30 :   0.001324 seconds ( 11.21 k allocations: 973.563 KiB)
40 :   0.036148 seconds ( 74.68 k allocations:   6.930 MiB, 63.24% gc time)
50 :   0.111040 seconds (408.45 k allocations:  40.882 MiB, 21.10% gc time)
60 :   0.372454 seconds (  1.93 M allocations: 206.614 MiB, 12.76% gc time)
70 :   1.631106 seconds (  8.18 M allocations: 926.427 MiB, 12.39% gc time)
80 :   6.668876 seconds ( 31.59 M allocations:   3.685 GiB, 12.25% gc time)
90 :  24.779135 seconds (113.27 M allocations:  13.858 GiB, 11.76% gc time)
100:  86.960344 seconds (381.14 M allocations:  48.735 GiB, 11.29% gc time)
=#
# https://www.math.upenn.edu/~wilf/website/CombinatorialAlgorithms.pdf
