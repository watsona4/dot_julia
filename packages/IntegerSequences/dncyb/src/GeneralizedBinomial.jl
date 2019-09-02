# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module GeneralizedBinomial
using Nemo, PrimesIterator, NumberTheory, Products, Triangles

export ModuleGeneralizedBinomial
export Binomial, Pascal, T007318

"""
 P. Luschny, [Generalized Binomial](http://oeis.org/wiki/User:Peter_Luschny/ExtensionsOfTheBinomial), OEIS Wiki.

* Binomial, Pascal, T007318
"""
const ModuleGeneralizedBinomial = ""

"""
The classical binomial coefficients defined for ``n≥0`` and ``0≤k≤n`` (a.k.a. Pascal's triangle).
"""
function Pascal(n::Int, k::Int)

    (k == 0 || k == n) && return 1
    if k > div(n, 2) k = n - k end

    nk = n - k
    factors = fmpz[]
    rootN = isqrt(n)

    # Make use of Kummer's theorem.
    for prime in Primes(2, n)

        if prime > nk
            push!(factors, prime)
            continue
        end

        prime > div(n, 2) && continue

        if prime > rootN
            (n % prime < k % prime) && push!(factors, prime)
            continue
        end

        r, N, K, p = 0, n, k, 1

        while N > 0
            r = N % prime < (K % prime + r) ? 1 : 0
            if r == 1 p *= prime end
            N = div(N, prime)
            K = div(K, prime)
        end

        p > 1 && push!(factors, p)
    end

    ∏(factors) end

"""
Pascal's triangle.
"""
function T007318(n::Int)
    T = zeros(QQ, div(n * (n + 1), 2))
    j = 1
    for m in 0:n - 1, k in 0:m
        T[j] = binom(m, k)
        j += 1
    end
    T
end

# See the discussion on
# [Extensions of the Binomial](http://oeis.org/wiki/User:Peter_Luschny/ExtensionsOfTheBinomial).
"""
Return the extended binomial coefficients defined for all ``n ∈ Z`` and ``k ∈ Z``. Behaves like the binomial function in Maple and Mathematica.

``\\binom{n}{k} = \\lim \\limits_{x \\rightarrow 1}(Γ(n + x) / (Γ(k + x) Γ(n - k + x))).``

"""
function Binomial(n::Int, k::Int)
    0 ≤ k ≤ n  && return binom(n, k)
    k ≤ n <  0 && return binom(-k - 1, n - k) * (-1)^(n - k)
    n <  0 ≤ k && return binom(-n + k - 1, k) * (-1)^k
    ZZ(0)
end

#START-TEST-########################################################

using Test
function test()

    @testset "Binomial" begin
        for n in 0:10, k in 0:n
            @test Binomial(n, k) == div(fac(n), (fac(n - k) * fac(k)))
            @test Binomial(n, k) == Pascal(n, k)
        end
    end
end

function demo()
    ShowAsΔ(T007318(8))
    println()

    for n in -10:10
        println([Binomial(n, k) for k in -10:10])
    end
end

"""
for n in 0:10000 Binomial(2*n,n) end
    0.504729 seconds (10.00 k allocations: 156.266 KiB)
for n in -100:100, k in -100:100 Binomial(n,k) end
    0.008669 seconds (55.55 k allocations: 867.984 KiB)
for k in -10000:10000 Binomial(-5,k) end
    0.005378 seconds (40.00 k allocations: 624.969 KiB)
"""
function perf()
    @time (for n in 0:10000 Binomial(2n, n) end)
    @time (for n in -100:100, k in -100:100 Binomial(n, k) end)
    @time (for k in -10000:10000 Binomial(-5, k) end)
end

function main()
    test()
    demo()
    perf()
end

main()

end # module
