# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module Hyper1F1

using Nemo

export ModuleHyper1F1
export GammaHyp, V000255, V000262, V001339, V007060, V033815, V099022, V251568

"""
GammaHyp: ``(a, b, c, d)`` ↦ ``Γ(a) `` Hypergeometric``1F1(b, c, d).``

* GammaHyp, V000255, V000262, V001339, V007060, V033815, V099022, V251568
"""
const ModuleHyper1F1 = ""

# Numerical evaluation based on hypergeometric functions.
# Nemo.hyp1f1(a::acb, b::acb, x::acb)
# May fail if the required precicison is > 10000.
# A Python implementation is here:
# http://luschny.de/math/seq/GammaHypPython.html

"""
Return ``Γ(a) `` Hypergeometric``1F1(b, c, d).``
"""
function GammaHyp(a, b, c, d)
    prec = 64
    while prec <= 10000
        CC = AcbField(prec)
        g = gamma(CC(a)) * hyp1f1(CC(b), CC(c), CC(d))
        b, i = unique_integer(g)
        b && return i
        prec = div(8*prec, 5)
    end

    error("GammaHyp with $a $b $c $d gives an InexactError!")
end

"""
Return ``(n+1)!`` Hypergeometric1F1``[-n, -n-1, -1]``. Number of fixedpoint-free permutations beginning with 2. (L. Euler).
"""
V000255(n) = n == 0 ? ZZ(1) : GammaHyp(n + 2, -n, -n-1, -1)

"""
Return ``n!`` Hypergeometric1F1``[1-n, 2, -1]``. Number of partitions of ``{1,...,n}`` into any number of ordered subsets.
"""
V000262(n) = n == 0 ? ZZ(1) : GammaHyp(n + 1, 1 - n, 2, -1)

"""
Return ``(n+1)!`` Hypergeometric1F1``[-n, -n-1, 1]``. Number of arrangements of ``{1, 2, ..., n+1}`` containing the element 1.
"""
V001339(n) = n == 0 ? ZZ(1) : GammaHyp(n + 2, -n, -n-1, 1)

"""
Return ``(2n)!`` Hypergeometric1F1``[-n, -2n, -2]``. Number of ways ``n`` couples can sit in a row without any spouses next to each other.
"""
V007060(n) = n == 0 ? ZZ(1) : GammaHyp(2n + 1, -n, -2n, -2)

"""
Return ``(2n)!`` Hypergeometric1F1``[-n, -2n, -1]``. Number of acyclic orientations of the Turán graph ``T(2n,n)``.
"""
V033815(n) = n == 0 ? ZZ(1) : GammaHyp(2n + 1, -n, -2n, -1)

"""
Return ``(2n)!`` Hypergeometric1F1``[-n, -2n, 1]``.
"""
V099022(n) = n == 0 ? ZZ(1) : GammaHyp(2n + 1, -n, -2n, 1)

"""
Return ``((2n)!/(n+1)!)`` Hypergeometric1F1``[1-n, n+2, -1]``. Egf. exp ``(x C(x)^2)`` where ``C(x) = 1 + xC(x)^2`` is the generating function of the Catalan numbers.
"""
function V251568(n::Int)
    n == 0 && return fmpz(1)
    prec = 64
    while prec <= 10000
        CC = ComplexField(prec)
        c = gamma(CC(2 * n + 1)) * hyp1f1(CC(1 - n), CC(n + 2), CC(-1)) / gamma(CC(n + 2))
        b, i = unique_integer(c)
        b && return i
        prec *= 2
    end
    error("n = $n gives an InexactError!")
end

#START-TEST-########################################################

using Test, SeqTests

function test()

    @testset "Hyper1F1" begin
        @test V000255(10) == ZZ(16019531)
        @test V000262(10) == ZZ(58941091)
        @test V001339(10) == ZZ(98641011)
        @test V007060(10) == ZZ(871804170613555200)
        @test V033815(10) == ZZ(1465957162768492800)
        @test V099022(10) == ZZ(3984884716852972800)
        @test V251568(10) == ZZ(123320412181)

        if is_oeis_installed()
            V = [V000255, V000262, V001339, V007060, V033815,
                 V099022, V251568]
            for v in V SeqTest(v, 'V') end
        end
    end
end

function demo()
    a, b, c, d =  11,  -9,     2, -1; GammaHyp(a, b, c, d) |> println
    a, b, c, d =  21,  -10,  -20, -2; GammaHyp(a, b, c, d) |> println
    a, b, c, d =  21,  -10,  -20, -1; GammaHyp(a, b, c, d) |> println
    a, b, c, d =  21,  -10,  -20,  1; GammaHyp(a, b, c, d) |> println
    a, b, c, d =  74,  -72,    2, -1; GammaHyp(a, b, c, d) |> println
    a, b, c, d = 147,  -73, -146, -2; GammaHyp(a, b, c, d) |> println
    a, b, c, d = 147,  -73, -146, -1; GammaHyp(a, b, c, d) |> println
    a, b, c, d = 147,  -73, -146,  1; GammaHyp(a, b, c, d) |> println
    a, b, c, d = 151, -149,    2, -1; GammaHyp(a, b, c, d) |> println
    a, b, c, d = 301, -150, -300, -2; GammaHyp(a, b, c, d) |> println
    a, b, c, d = 301, -150, -300, -1; GammaHyp(a, b, c, d) |> println
    a, b, c, d = 301, -150, -300,  1; GammaHyp(a, b, c, d) |> println
end

"""
(for n in 0:150 V000262(n) end) ::
    0.010073 seconds (3.75 k allocations: 166.422 KB)
"""
function perf()
    GC.gc()
    @time (for n in 0:150 V000262(n) end)
end

function main()
    test()
    demo()
    perf()
end

main()

end # module
