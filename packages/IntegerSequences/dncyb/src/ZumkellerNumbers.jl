# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module ZumkellerNumbers

using NumberTheory, IterTools, CombinationsIterator

export ModuleZumkellerNumbers
export isZumkeller, is083207, I083207, F083207, L083207, V083207

"""
A Zumkeller number ``n`` is an integer whose divisors can be partitioned into two disjoint sets whose sums are both ``σ(n)/2``.

* isZumkeller, is083207, I083207, F083207, L083207, V083207
"""
const ModuleZumkellerNumbers = ""

"""
Is ``n`` a Zumkeller number? A Zumkeller number ``n`` is an integer whose divisors can be partitioned into two disjoint sets whose sums are both ``σ(n)/2``.
"""
function isZumkeller(n::Int)
    n == 0 && return false
    s = σ(n)
    ((s % 2 ≠ 0) || (s < 2n)) && return false
    S = s >> 1 - n
    D = [d for d in Divisors(n) if d ≤ S]
    D == [] && return true
    for c in Combinations(D)
        S == sum(c) && return true
    end
    return false
end

"""
Is ``n`` a Zumkeller number?
"""
is083207(n) = isZumkeller(n)

"""
Iterate over the first ``n`` Zumkeller numbers.
"""
I083207(n) = Iterators.take(Iterators.filter(isZumkeller, Iterators.countfrom(1)), n)

"""
Iterate over the Zumkeller numbers ``z`` which are below ``n, (1 ≤ z ≤ n)``.
"""
F083207(n) = Iterators.filter(isZumkeller, 1:n)

"""
List the first ``n`` Zumkeller numbers.
"""
L083207(n) = collect(I083207(n))

"""
Return the ``n``-th Zumkeller number.
"""
V083207(n) = nth(I083207(n), n)

#START-TEST-########################################################

using Test

function test()
    @testset "Zumkeller" begin
        @test isZumkeller(17000) == true
        @test isZumkeller(27472) == true
        @test isZumkeller(29062) == false
        @test isZumkeller(43464) == true
    end
end

function demo()
    println(L083207(10))
    for a in I083207(30) print(a, ", ") end; println("...")
    for a in F083207(30) print(a, ", ") end; println("...")

    for n in 20:30
        println(n, " ↦ ",  isZumkeller(n))
    end

    for (index, value) in enumerate(I083207(10))
        println("$index -> $value")
    end

    println(V083207(10))

    for n in 1:6
        println(n, " ↦ ", L083207(n))
    end
end

"""
@time (for n in 1:2000 isZumkeller(n) end) ::
    0.311896 seconds (1.86 M allocations: 63.875 MiB, 31.28% gc time)
@time L083207(500) ::
    0.295718 seconds (2.21 M allocations: 75.920 MiB, 40.89% gc time)
"""
function perf()
    GC.gc()
    @time (for n in 1:2000 isZumkeller(n) end)
    @time L083207(500)
end

function main()
    test()
    demo()
    perf()
end

main()

end # module

#=
[6, 12, 20, 24, 28, 30, 40, 42, 48, 54]
6, 12, 20, 24, 28, 30, 40, 42, 48, 54, 56, 60, 66, 70, 78, 80, 84,
88, 90, 96, 102, 104, 108, 112, 114, 120, 126, 132, 138, 140, ...
6, 12, 20, 24, 28, 30, ...

20 ↦ true
21 ↦ false
22 ↦ false
23 ↦ false
24 ↦ true
25 ↦ false
26 ↦ false
27 ↦ false
28 ↦ true
29 ↦ false
30 ↦ true

1 -> 6
2 -> 12
3 -> 20
4 -> 24
5 -> 28
6 -> 30
7 -> 40
8 -> 42
9 -> 48
10 -> 54
54

1 ↦ [6]
2 ↦ [6, 12]
3 ↦ [6, 12, 20]
4 ↦ [6, 12, 20, 24]
5 ↦ [6, 12, 20, 24, 28]
6 ↦ [6, 12, 20, 24, 28, 30]

  0.311551 seconds (1.86 M allocations: 63.820 MiB, 60.62% gc time)
  0.294909 seconds (2.21 M allocations: 75.858 MiB, 41.31% gc time)
=#
