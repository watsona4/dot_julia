# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module NumberTheory
using  Nemo, Products

export ModuleNumberTheory
export τ, σ, σ2, ϕ, ω, Ω, ⊥, ⍊, Divisors, PrimeDivisors, Factors, Radical, mods
export V000005, V000010, V000203, V001222, V001221, V008683, V181830, V034444
export I003277, L003277, V061142, V034386, V002110, I050384, L050384, V001157
export Divides, isPrime, isCyclic, isStrongCyclic, isOdd, PrimeList
export isPrimeTo, isStrongPrimeTo, isNonnegative, isPositive, isEven, isSquare
export isComposite, isSquareFree, isPrimePower, isPowerOfPrimes, isPerfectPower

"""
* τ, σ, σ2, ϕ, ω, Ω, ⊥, ⍊
* Divisors, PrimeDivisors, Factors, Radical, mods, Divides, isPrime, isCyclic, isStrongCyclic, isOdd, PrimeList, isPrimeTo, isStrongPrimeTo, isNonnegative, isPositive, isEven, isSquare, isComposite, isSquareFree, isPrimePower, isPowerOfPrimes, isPerfectPower
* V000005, V000010, V000203, V001222, V001221, V008683, V181830, V034444, I003277, L003277, V061142, V034386, V002110, I050384, L050384, V001157
"""
const ModuleNumberTheory = ""

"""
Return true if n is prime false otherwise.
"""
isPrime(n) = Nemo.isprime(fmpz(n))
#function isPrime(n)::Bool Nemo.isprime(fmpz(n)) end

"""
Return factors of ``n``.
"""
Factors(n) = n == 0 ? [] : Nemo.factor(fmpz(n))

"""
Return the positive integers dividing ``n``.
"""
function Divisors(m, dosort=false)
    n = ZZ(m)
    n == ZZ(0) && return fmpz[]
    Nemo.isprime(n) && return [ZZ(1), n]
    d = [ZZ(1)]
    for (p, e) in Nemo.factor(n)
        d *= permutedims([p^i for i in 0:e])
        d = reshape(d, length(d))
    end
    dosort && sort!(d)
    d
end

"""
Return the prime numbers dividing ``n``.
"""
function PrimeDivisors(n)
    n == 0 && return []
    isPrime(n) && return [fmpz(n)]
    f = Factors(n)
    sort!([p for (p, e) in f])
end

"""
Return the radical of ``n`` which is the product of the prime numbers dividing ``n`` (also called the squarefree kernel of ``n``).
"""
Radical(n) = ∏(PrimeDivisors(n))

"""
Return ``Ω(n)``, the number of prime divisors of ``n`` counted with multiplicity (cf. A001222).
"""
function Ω(n)
    n == fmpz(0) && return 0
    isPrime(n) && return fmpz(1)
    f = Factors(n)
    sum([e for (p, e) in f])
end

"""
Return the number of prime divisors of ``n`` counted with multiplicity.
"""
V001222(n) = Ω(n)

"""
Return the result of replacing each prime factor of n with 2.
"""
V061142(n) = 1 << Int(Ω(n))

"""
Return ``ω(n)``,  the number of distinct prime divisors of ``n`` (cf. A001221).
"""
ω(n) = fmpz(length(PrimeDivisors(n)))

"""
Return the number of distinct prime divisors of ``n``.
"""
V001221(n) = ω(n)

"""
Return the number of unitary divisors of ``n``, ``d`` such that ``d`` divides ``n`` and ``d ⊥ n/d``.
"""
V034444(n::Int) = 1 << Int(ω(n))

"""
Return ``τ(n)`` (a.k.a. ``σ_0(n)``), the number of divisors of ``n`` (cf A000005).
"""
τ(n) = Nemo.sigma(fmpz(n), 0)

"""
Return the number of divisors of ``n``.
"""
V000005(n) = τ(n)

"""
Return ``σ(n)`` (a.k.a. ``σ_1(n)``), the sum of the divisors of ``n`` (cf. A000203).
"""
σ(n) = Nemo.sigma(fmpz(n), 1)

"""
Return ``σ2(n)`` (a.k.a. ``σ_2(n)``), the sum of squares of the divisors of ``n`` (cf. A001157).
"""
σ2(n) = Nemo.sigma(fmpz(n), 2)

# σ2(n) = sum(d^2 for d in Divisors(n))

"""
Return ``σ2(n)`` (a.k.a. ``σ_2(n)``), the sum of squares of the divisors of ``n``.
"""
V001157(n) = σ2(n)

"""
Return the Euler totient ``ϕ(n)``, numbers which are ``≤ n`` and prime to ``n``.
"""
ϕ(n) = Nemo.eulerphi(fmpz(n))

"""
Return the number of integers ``≤ n`` and prime to ``n``.
"""
V000010(n) = ϕ(n)

"""
Return the value of the Möbius function ``μ(n)`` which is the sum of the primitive n-th roots of unity.
"""
μ(n) = Nemo.moebiusmu(fmpz(n))

"""
Return the value of the Möbius function ``μ(n)`` which is the sum of the primitive n-th roots of unity.
"""
V008683(n) = μ(n)

"""
Return the sum of the divisors of ``n``.
"""
V000203(n) = σ(n)

"""
Query if ``m`` is prime to ``n``.
"""
isPrimeTo(m, n) = Nemo.gcd(fmpz(m), fmpz(n)) == fmpz(1)

"""
Query if ``m`` is prime to ``n``. Knuth, Graham and Patashnik write in "Concrete Mathematics": "Hear us, O mathematicians of the world! Let us not wait any longer! We can make many formulas clearer by defining a new notation now! Let us agree to write m ⊥ n, and to say "m is prime to n", if m and n are relatively prime."
"""
⊥(m, n) = isPrimeTo(m, n)

"""
Query if ``m`` is strong prime to ``n``. ``m`` is strong prime to ``n`` iff ``m`` is prime to ``n`` and ``m`` does not divide ``n-1``.
"""
isStrongPrimeTo(m, n) = isPrimeTo(m, n) && n ∉ Divisors(m - 1)

"""
Query if ``m`` is strong prime to ``n``. ``m`` is strong prime to ``n`` iff ``m`` is prime to ``n`` and ``m`` does not divide ``n-1``.
"""
⍊(m, n) = isStrongPrimeTo(m, n)

function NumbersStronglyPrimeTo(n::Int)
    P = fmpz[m for m in 1:n if ⊥(m, n)]
    D = Divisors(n - 1)
    return setdiff(P, D)
end

"""
Return the number of integers ``≤ n`` which are strong prime to ``n``.
"""
V181830(n) = n == 0 ? 0 : ϕ(n) - τ(n - 1)

"""
Is ``n`` a cyclic number? ``n`` such that there is just one group of order ``n``.
"""
isCyclic(n) = n == 0 ? false : ⊥(n, ϕ(n))

"""
Iterate over the first ``n`` cyclic numbers.
"""
I003277(n::Int) = Iterators.take(Iterators.filter(isCyclic, Iterators.countfrom(1)), n)

"""
Return the first ``n`` cyclic numbers in an array.
"""
L003277(n::Int) = collect(I003277(n))

"""
Is ``n`` a strong cyclic number?
"""
isStrongCyclic(n) = n == 0 ? false : ⍊(n, ϕ(n))

"""
Iterate over the first ``n`` strong cyclic numbers.
"""
I050384(n::Int) = Iterators.take(Iterators.filter(isStrongCyclic, Iterators.countfrom(1)), n)

"""
Return the first ``n`` strong cyclic numbers in an array.
"""
L050384(n::Int) = collect(I050384(n))

"""
Return the least absolute remainder. mods uses the symmetric representation for integers modulo m, i.e. remainders will be reduced to integers in the range ``[-``div``(|m| - 1, 2), ``div``(|m|, 2)]``.
"""
function mods(b, a)
    b == 0 && return a
    h = a >> 1
    (q, r) = divrem(b, a)
    if h <  r  r -= a end
    if h < -r  r += a end
    r
end

"""
Is the integer ``n`` nonnegative?
"""
isNonnegative(n) = n ≥ 0

"""
Is the integer ``n`` positive?
"""
isPositive(n) = n > 0

"""
Is the integer ``n`` a square number?
"""
isSquare(n) = Nemo.issquare(fmpz(n))

"""
Is the integer ``n`` a composite number?
"""
isComposite(n) = (n > 0) && 1 < Ω(n)

"""
Is the integer ``n`` a squarefree number?
"""
isSquareFree(n) = (n > 0) && ω(n) == Ω(n)

"""
Is the integer ``n`` a prime power?
"""
isPrimePower(n) = ω(n) == 1

"""
Is the integer ``n`` a power of primes?
"""
isPowerOfPrimes(n) = (n == 1) || (ω(n) == 1)

"""
Is the integer ``n`` a perfect powers?
"""
isPerfectPower(n) = ω(n) == 1 && Ω(n) ≠ 1

"""
Return `true` if b is divisible by a, otherwise return `false`.
"""
Divides(a, b) = a ≠ 0 && rem(fmpz(b), fmpz(a)) == fmpz(0)

# Defined in the module Base.
"""
Is ``n`` divisble by 2?
"""
isEven(n) = Base.iseven(n)
# n % 2 == 0 ? true : false

"""
Is ``n`` indivisble by 2?
"""
isOdd(n) = Base.isodd(n)
# n % 2 != 0 ? true : false

"""
Return the primorial of ``n``, the product of the primes ``≤ n``.
"""
V034386(n) = Nemo.primorial(n)

"""
Return a list of the first ``n`` primes.
"""
PrimeList(len::Int) = Iterators.take(Iterators.filter(isPrime, Iterators.countfrom(1)), len)

"""
Return the product of first ``n`` primes.
"""
V002110(n) = ∏(PrimeList(n))

# In the module GaussFactorial are the definitions of
# HasPrimitiveRoot
# HasNoPrimitiveRoot

# In the module Abundant
# isAbundant

# Further indicators, less suited for computations.

# isA008578(n::Int) = all(⊥(k, n)     for k in 1:n-1)
# isA002182(n::Int) = all(τ(k) < τ(n) for k in 1:n-1)
# isA002110(n::Int) = all(ω(k) < ω(n) for k in 1:n-1)
# isA131577(n::Int) = all(Ω(k) < Ω(n) for k in 1:n-1)

#START-TEST-########################################################

using Test, SeqTests, SeqUtils

function test()

    # 0-based version of sequences
    Data = Dict{Int,Array{fmpz}}(034386 => [1, 1, 2, 6, 6, 30, 30, 210, 210, 210],
    061142 => [1, 1, 2, 2, 4, 2, 4, 2, 8, 4],
    002110 => [1, 2, 6, 30, 210, 2310, 30030, 510510, 9699690, 223092870],
    000005 => [0, 1, 2, 2, 3, 2, 4, 2, 4, 3],
    000010 => [0, 1, 1, 2, 2, 4, 2, 6, 4, 6],
    000203 => [0, 1, 3, 4, 7, 6, 12, 8, 15, 13],
    001222 => [0, 0, 1, 1, 2, 1, 2, 1, 3, 2],
    001221 => [0, 0, 1, 1, 1, 1, 2, 1, 1, 1],
    008683 => [0, 1, -1, -1, 0, -1, 1, -1, 0, 0],
    181830 => [0, 1, 0, 0, 0, 1, 0, 2, 2, 2],
    034444 => [1, 1, 2, 2, 2, 2, 4, 2, 2, 2])

    @testset "NumTheory" begin
        @test τ(7560) == 64
        @test τ(46080) == 66
        @test τ(25920) == 70

        @test σ(7560) == 28800
        @test σ(46080) == 159666
        @test σ(25919) == 25920
        @test σ(25920) == 92202

        @test ω(7560) == 4
        @test ω(46080) == 3
        @test ω(25919) == 1
        @test ω(25920) == 3

        @test Ω(7560) == 8
        @test Ω(46080) == 13
        @test Ω(25919) == 1
        @test Ω(25920) == 11

        @test Radical(58564) == 22
        @test Radical(58565) == 58565

        FB(n::Int) = (r = 1; for k in 1:n ⊥(n, k) && (r = mods(r * k, n)) end; r)
        FA(n::Int) = mods(∏([j for j in 1:n if ⊥(j, n)]), n)

        for n in 1:20
            @test FA(n) == FB(n)
        end

        if is_oeis_installed()
            V = [V061142, V000005, V000010, V000203, V001222, V001221, V008683]
            W = [V034386, V002110, V181830, V034444]
            for v in V SeqTest(v, 'V', 1) end

            L = [L003277]
            SeqTest(L, 'L')
        end
    end

    composita = [false, false, false, false, true, false, true, false]
    @testset "Queries" begin
        for n in 0:7
            @test isComposite(n) == composita[n + 1]
        end
    end
end

function demo()
    for n in 390:400
        println(n, " ---")
        println(Factors(n))
        println(Divisors(n))
        println(τ(n), ", ", σ(n))
        println(PrimeDivisors(n))
        println(Radical(n))
    end

    println()
    println([n for n in 1:200 if isCyclic(n)])
    println([n for n in 1:200 if isStrongCyclic(n)])
    println(L050384(24))

end

"""
[Divisors(n) for n in 1:10000]
    0.278807 seconds (1.32 M allocations: 39.099 MiB, 46.04% gc time)
[Radical(n)  for n in 1:10000]
    0.070448 seconds (257.87 k allocations: 16.681 MiB)
"""
function perf()
    @time [Divisors(n) for n in 1:10000]
    @time [Radical(n)  for n in 1:10000]
end

function main()
    test()
    demo()
    perf()
end

main()

 end # module

#=

390 ---
1 * 5 * 13 * 2 * 3
Nemo.fmpz[1, 5, 13, 65, 2, 10, 26, 130, 3, 15, 39, 195, 6, 30, 78, 390]
16, 1008
Nemo.fmpz[2, 3, 5, 13]
390
391 ---
1 * 17 * 23
Nemo.fmpz[1, 17, 23, 391]
4, 432
Nemo.fmpz[17, 23]
391
392 ---
1 * 7^2 * 2^3
Nemo.fmpz[1, 7, 49, 2, 14, 98, 4, 28, 196, 8, 56, 392]
12, 855
Nemo.fmpz[2, 7]
14
393 ---
1 * 131 * 3
Nemo.fmpz[1, 131, 3, 393]
4, 528
Nemo.fmpz[3, 131]
393
394 ---
1 * 197 * 2
Nemo.fmpz[1, 197, 2, 394]
4, 594
Nemo.fmpz[2, 197]
394
395 ---
1 * 5 * 79
Nemo.fmpz[1, 5, 79, 395]
4, 480
Nemo.fmpz[5, 79]
395
396 ---
1 * 2^2 * 11 * 3^2
Nemo.fmpz[1, 2, 4, 11, 22, 44, 3, 6, 12, 33, 66, 132, 9, 18, 36, 99, 198, 396]
18, 1092
Nemo.fmpz[2, 3, 11]
66
397 ---
1 * 397
Nemo.fmpz[1, 397]
2, 398
Nemo.fmpz[397]
397
398 ---
1 * 2 * 199
Nemo.fmpz[1, 2, 199, 398]
4, 600
Nemo.fmpz[2, 199]
398
399 ---
1 * 7 * 3 * 19
Nemo.fmpz[1, 7, 3, 21, 19, 133, 57, 399]
8, 640
Nemo.fmpz[3, 7, 19]
399
400 ---
1 * 5^2 * 2^4
Nemo.fmpz[1, 5, 25, 2, 10, 50, 4, 20, 100, 8, 40, 200, 16, 80, 400]
15, 961
Nemo.fmpz[2, 5]
10

[1, 2, 3, 5, 7, 11, 13, 15, 17, 19, 23, 29, 31, 33, 35, 37, 41, 43,
47, 51, 53, 59, 61, 65, 67, 69, 71, 73, 77, 79, 83, 85, 87, 89, 91,
95, 97, 101, 103, 107, 109, 113, 115, 119, 123, 127, 131, 133, 137,
139, 141, 143, 145, 149, 151, 157, 159, 161, 163, 167, 173, 177, 179,
181, 185, 187, 191, 193, 197, 199]
[1, 15, 33, 35, 51, 65, 69, 77, 85, 87, 91, 95, 115, 119, 123, 133,
141, 143, 145, 159, 161, 177, 185, 187]
[1, 15, 33, 35, 51, 65, 69, 77, 85, 87, 91, 95, 115, 119, 123, 133,
141, 143, 145, 159, 161, 177, 185, 187]

  0.275991 seconds (1.32 M allocations: 39.054 MiB, 51.98% gc time)
  0.070448 seconds (257.87 k allocations: 16.681 MiB)

=#
