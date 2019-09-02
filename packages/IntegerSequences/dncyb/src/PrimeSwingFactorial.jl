# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module PrimeSwingFactorial

using PrimesIterator, Products, Nemo

export ModulePrimeSwingFactorial
export PSfactorial, Swing

"""
 Cf. P. Luschny, [Swing, divide and conquer the factorial](https://oeis.org/A000142/a000142.pdf), excerpt.

* PSfactorial, Swing
"""
const ModulePrimeSwingFactorial = ""

const SwingOddpart = [1,1,1,3,3,15,5,35,35, 315, 63, 693, 231,
   3003, 429, 6435, 6435, 109395,12155,230945,46189,969969,
   88179,2028117, 676039,16900975,1300075,35102025,5014575,
   145422675,9694845,300540195,300540195]

"""
Computes the odd part of the swinging factorial ``n≀`` (cf. A163590).
"""
function swing_oddpart(n::Int)
    n < 33 && return ZZ(SwingOddpart[n+1])

    sqrtn = isqrt(n)
    factors = Primes(div(n,2) + 1, n)
    P = Primes(sqrtn + 1, div(n, 3))
    s = [p for p in P if isodd(div(n, p))]

    for prime in Primes(3, sqrtn)
        p, q = 1, n
        while true
            q = div(q, prime)
            q == 0 && break
            isodd(q) && (p *= prime)
        end
        p > 1 && push!(s, p)
    end

    return ∏(factors)*∏(s)
end

"""
Computes the swinging factorial (a.k.a. Swing numbers n≀) (cf. A056040).
"""
function Swing(n::Int)
    sh = count_ones(div(n, 2))
    swing_oddpart(n) << sh
end

const FactorialOddPart = [1, 1, 1, 3, 3, 15, 45, 315, 315, 2835, 14175, 155925,
    467775, 6081075, 42567525, 638512875, 638512875, 10854718875, 97692469875,
    1856156927625, 9280784638125, 194896477400625, 2143861251406875,
    49308808782358125, 147926426347074375, 3698160658676859375]

"""
Return the largest odd divisor of ``n!``. Cf. A049606.
"""
function factorial_oddpart(n::Int)
    n < length(FactorialOddPart) && return ZZ(FactorialOddPart[n+1])
    swing_oddpart(n)*(factorial_oddpart(div(n,2))^2)
end

"""
Return the factorial ``n! = 1×2× ... ×n``, which is the order of the symmetric group S_n or the number of permutations of n letters (cf. A000142).
"""
function PSfactorial(n::Int)
    n < 0 && ArgumentError("Argument must be >= 0")
    sh = n - count_ones(n)
    factorial_oddpart(n) << sh
end

#START-TEST-########################################################

using Test, BenchmarkTools

function test()
    @testset "PrimeSwingF" begin
        for n in 0:999
            S = PSfactorial(n)
            B = Base.factorial(BigInt(n))
            #@test S == B
            @test all(S .== B)
        end
    end
end

function demo()
end

"""
10^1  128.016 ns (3        allocations:     48 bytes)
10^2    8.148 μs (78       allocations:   3.31 KiB)
10^3   68.933 μs (469      allocations:  16.53 KiB)
10^4  832.578 μs (3780     allocations: 106.00 KiB)
10^5   17.717 ms (31657    allocations: 816.70 KiB)
10^6  288.445 ms (263237   allocations:   6.53 MiB)
10^7    5.484  s (2209289  allocations:  53.95 MiB)
10^8   86.723  s (18926351 allocations: 446.32 MiB)
10^9 1218.261  s (167.46 M allocations: 3.828 GiB)
"""
function superperf()
    GC.gc()
    println(10)
    @btime PSfactorial(10)
    GC.gc()
    println(100)
    @btime PSfactorial(100)
    GC.gc()
    println(1000)
    @btime PSfactorial(1000)
    GC.gc()
    println(10000)
    @btime PSfactorial(10000)
    GC.gc()
    println(100000)
    @btime PSfactorial(100000)
    GC.gc()
    println(1000000)
    @btime PSfactorial(1000000)
    GC.gc()
    println(10000000)
    @btime PSfactorial(10000000)
    GC.gc()
    println(100000000)
    @btime PSfactorial(100000000)
    GC.gc()
    println(1000000000)
    @time PSfactorial(1000000000)
end

function perf()
    GC.gc()
    @time Base.factorial(BigInt(1000000))
    @time PSfactorial(1000000)
end

function main()
    test()
    demo()
    perf()
end

main()

end # module
