# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module RationalTrees

using Nemo, NumberTheory, Counts

export ModuleRationalTrees
export EuclidTree, CalkinWilfTree, SchinzelSierpinskiEncoding


"""
Rational trees as understood here are binary trees enumerating the positive or
nonnegative rational numbers. Examples are the Euclid tree, the Kepler tree and the
Stern-Brocot tree (a.k.a. Farey tree). They are closely related to binary partitions
and to Stern's diatomic sequence or Dijkstra's fusc function.

Malter, Schleicher, Zagier, [New looks at old number theory](https://pdfs.semanticscholar.org/6d28/dcef911dd91f47e6ca4bd2c564c1f3099a05.pdf), Amer. Math. Monthly, 120(3), 2013, pp. 243-264.

* EuclidTree, CalkinWilfTree, SchinzelSierpinskiEncoding
"""
const ModuleRationalTrees = ""

# http://oeis.org/wiki/User:Peter_Luschny/SchinzelSierpinskiConjectureAndCalkinWilfTree
# A294442 A294446

"""
```
julia> for n in 1:4 Println(EuclidTree(n)) end
[1//1]
[1//2, 2//1]
[1//3, 3//2, 2//3, 3//1]
[1//4, 4//3, 3//5, 5//2, 2//5, 5//3, 3//4, 4//1]
```
"""
function EuclidTree(n)

    function DijkstraFusc(m)
        a, b, k = 1, 0, m
        while k > 0
            k % 2 == 1 ? b += a : a += b
            k = k >> 1
        end
    b end

    DF = [DijkstraFusc(k) for k in 2^(n-1):2^n]
    [fmpq(DF[j], DF[j+1]) for j in 1:2^(n-1)]
end

"""
Alias for the (much better named) EuclidTree. See Malter, Schleicher, Zagier, New looks at old number theory, Amer. Math. Monthly, 120(3), 2013, pp. 243-264.
"""
CalkinWilfTree(n) = EuclidTree(n)

"""
Return the Schinzel-Sierpinski encoding of the positive rational number r.

```
julia> for n in 1:4 println([SchinzelSierpinski(l) for l in EuclidTree(n)]) end
[1//1]
[2//5, 5//2]
[3//11, 5//3, 3//5, 11//3]
[2//11, 3//2, 11//19, 19//7, 7//19, 19//11, 2//3, 11//2]
```
"""
function SchinzelSierpinskiEncoding(l, searchLimit=500000)

    a, b = numerator(l), denominator(l)
    sgn = a < b ? -1 : 1
    p, q = 1, 2

    while q < searchLimit
        r = a*(q + 1)
        r % b == 0 && (p = div(r, b) - 1)
        isPrime(p) && return fmpq(p, q)
        q = NextPrime(q)
    end
    warn("Search limit reached for ", l )
    return 0
end

#START-TEST-########################################################

using Test, SeqUtils, PrimesIterator

function test()
    @testset "EuclidTree" begin
        S = [numerator(sum(r for r in EuclidTree(n))) for n in 1:9]
        L = Nemo.fmpz[1, 5, 11, 23, 47, 95, 191, 383, 767] # A052940
        @test all(S[1:9] .== L[1:9])
    end
end

function demo()
    println("\nEuclidTree")
    for n in 1:5
        Println(EuclidTree(n))
    end
    println()

    println("\nSchinzelSierpinskiEncoding of the Euclid tree")
    for n in 1:5
        Println([SchinzelSierpinskiEncoding(l) for l in EuclidTree(n)])
        # println(sum([SchinzelSierpinskiEncoding(l) for l in EuclidTree(n)]))
    end
    println()

    println("\nSchinzelSierpinskiEncoding of primes")
    Println([SchinzelSierpinskiEncoding(fmpq(p,1)) for p in Primes(100)])
    println()
end

"""
EuclidTree(100) ::
    0.000005 seconds (4 allocations: 224 bytes)
[SchinzelSierpinskiEncoding(l) for l in EuclidTree(100)] ::
    0.000007 seconds (6 allocations: 320 bytes)
"""
function perf()
    GC.gc()
    @time EuclidTree(100)
    GC.gc()
    @time [SchinzelSierpinskiEncoding(l) for l in EuclidTree(100)]
end

function main()
    test()
    demo()
    perf()
end

main()

end # module

#=
# A062251 := n -> SchinzelSierpinskiPrimes(n,"numer"):
# A062251 = 2, 5, 11, 11, 19, 17, 41, 23, 53, 29, 43, 47, 103, 41,
# 59, 47, 67, 53, 113, 59, 83, 131, 137, 71, 149, 103, 107, 83,
# A060324 := n -> SchinzelSierpinskiPrimes(n,"denom"):
# A060324 = 2, 2, 3, 2, 3, 2, 5, 2, 5, 2, 3, 3, 7, 2, 3, 2,
# 3, 2, 5, 2, 3, 5, 5, 2, 5, 3, 3, 2, 5, 2, 13, 3
=#
