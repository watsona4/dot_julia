# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module Products
using Nemo

export ModuleProducts
export ∏, Product, F!, RisingFactorial, ↑, FallingFactorial, ↓, MultiFactorial
export V000407, V124320, V265609, V000142, V081125, V001147
export V000165, V032031, V007559, V008544, V007696, V001813, V008545, V047053

"""
* ∏, Product, F!, RisingFactorial, ↑, FallingFactorial, ↓, MultiFactorial
* V000407, V124320, V265609, V000142, V081125, V001147, V000165, V032031, V007559, V008544, V007696, V001813, V008545, V047053
"""
const ModuleProducts = ""

"""
If ``a ≤ b`` then return the product of ``i`` in ``a:b`` else return ``1``.
"""
function ∏(a, b)
    n = b - a
    if n < 24
        p = ZZ(1)
        for k in a:b
            p *= k
        end
        return ZZ(p)
    end
    m = div(a + b, 2)
    ∏(a, m) * ∏(m + 1, b)
end

"""
If ``a ≤ b`` then return the product of ``i`` in ``a:b`` else return ``1``.
"""
Product(a, b) = ∏(a, b)

"""
Return the accumulated product of an array.
"""
function ∏(A)
    function prod(a, b)
        n = b - a
        if n < 24
            p = ZZ(1)
            for k in a:b
                p *= A[k]
            end
            return ZZ(p)
        end
        m = div(a + b, 2)
        prod(a, m) * prod(m + 1, b)
    end
    A == [] && return 1
    prod(1, length(A))
end

"""
Return the accumulated product of an array.
"""
Product(A) = ∏(A)

"""
Return frac``{n!} {⌊n/2⌋!}``.
"""
V081125(n::Int) = ∏(div(n, 2) + 1, n)

"""
Return the rising factorial which is the product of ``i`` in ``n:(n + k - 1)``.
"""
RisingFactorial(n::Int, k::Int) = ∏(n, n + k - 1)

"""
Return the rising factorial which is the product of ``i`` in ``n:(n + k - 1)``. A convenient infix syntax for the rising factorial is n ↑ k.
"""
↑(n, k) = RisingFactorial(n, k)

"""
Return the rising factorial i.e. the product of ``i`` in ``n:(n + k - 1)``.
"""
V265609(n::Int, k::Int) = RisingFactorial(n, k)

# *** deprecated, use n ↑ k instead ***
#"""
#Return 'Pochhammer(n, k)', which is ambiguous in the literature, as the
#RisingFactorial(n,k).
#"""
#Pochhammer(n::Int, k::Int) = ∏(n, n + k - 1)
# *** deprecated ***

"""
Return the falling factorial which is the product of ``i`` in ``(n - k + 1):n``.
"""
FallingFactorial(n::Int, k::Int) = ∏(n - k + 1, n)

"""
Return the falling factorial which is the product of ``i`` in ``(n - k + 1):n``. A convenient infix syntax for the falling factorial is n ↓ k.
"""
↓(n, k) = FallingFactorial(n, k)

"""
Return the number of permutations of n letters, ``n! = ∏(1, n)``, the factorial of ``n``. (The notation is a shortcut breaking Julia conventions.)
"""
F!(n::Int) = Nemo.fac(n)

"""
Return the factorial numbers.
"""
V000142(n::Int) = Nemo.fac(n)

"""
Return the central rising factorial ``(n+1) ↑ (n+1) = (2n+1)! / n!``.
"""
V000407(n::Int) = (n + 1) ↑ (n + 1)
# V000407(n::Int) = ∏(n + 1, 2n + 1)

"""
Return the restricted rising factorial which is zero for ``n < 0`` or ``k > n``.
"""
V124320(n::Int, k::Int) = (n < 0 || k > n) ? 0 : ∏(n, n + k - 1)

"""
Return the multi-factorial which is the function ``n → ∏(a + b, a(n-1) + b)``
"""
MultiFactorial(a::Int, b::Int) = n -> ∏([a * k + b for k in 0:(n - 1)])

"""
Return the double factorial of odd numbers, ``1×3×5×...×(2n-1) = (2n-1)!!``.
"""
V001147(n::Int) = MultiFactorial(2, 1)(n)

"""
Return the double factorial of even numbers: ``2^n n! = (2n)!!``.
"""
V000165(n::Int) = MultiFactorial(2, 2)(n)

"""
Return the triple factorial numbers with shift 1, ``3^n n! = (3n)!!!``.
"""
V007559(n::Int) = MultiFactorial(3, 1)(n)

"""
Return the triple factorial numbers with shift 2.
"""
V008544(n::Int) = MultiFactorial(3, 2)(n)

"""
Return the triple factorial numbers with shift 3.
"""
V032031(n::Int) = MultiFactorial(3, 3)(n)

"""
Return the quadruple factorial numbers with shift 1.
"""
V007696(n::Int) = MultiFactorial(4, 1)(n)

"""
Return the quadruple factorial numbers with shift 2, ``(2n)!/n!``.
"""
V001813(n::Int) = MultiFactorial(4, 2)(n) # = ∏(n + 1, 2n)

"""
Return the quadruple factorial numbers with shift 3.
"""
V008545(n::Int) = MultiFactorial(4, 3)(n)

"""
Return the quadruple factorial numbers ``4^n n!``.
"""
V047053(n::Int) = MultiFactorial(4, 4)(n)

# RisingFactorial(n, k)
# n\k [0  1   2    3     4      5        6         7          8]
# --------------------------------------------------------------
# [0] [1, 0,  0,   0,    0,     0,       0,        0,         0]
# [1] [1, 1,  2,   6,   24,   120,     720,     5040,     40320]
# [2] [1, 2,  6,  24,  120,   720,    5040,    40320,    362880]
# [3] [1, 3, 12,  60,  360,  2520,   20160,   181440,   1814400]
# [4] [1, 4, 20, 120,  840,  6720,   60480,   604800,   6652800]
# [5] [1, 5, 30, 210, 1680, 15120,  151200,  1663200,  19958400]
# [6] [1, 6, 42, 336, 3024, 30240,  332640,  3991680,  51891840]
# [7] [1, 7, 56, 504, 5040, 55440,  665280,  8648640, 121080960]
# [8] [1, 8, 72, 720, 7920, 95040, 1235520, 17297280, 259459200]

#START-TEST-########################################################

using Test, SeqTests

function test()
    @testset "FallingFact" begin
        @test FallingFactorial(100, 100) == factorial(BigInt(100))
        @test (100 ↓ 100) == factorial(BigInt(100))
        @test FallingFactorial(333, 333) == factorial(BigInt(333))
        @test FallingFactorial(111, 0) == 1
    end
    @testset "RisingFact" begin
        @test RisingFactorial(11, 11) == 14079294028800
        @test (11 ↑ 11) == 14079294028800
        @test RisingFactorial(33, 33) == 31344295059422473624824839739793024055460338073600000000
        @test RisingFactorial(111, 0) == 1
    end
    @testset "MultiFact" begin
        a = [MultiFactorial(2, 1)(n) for n in 0:6]
        b = [1, 1, 3, 15, 105, 945, 10395]
        @test all(a .== b)
    end

    if is_oeis_installed()
        V = [V000142, V000165, V007696, V001813, V047053, V001147, V008545,
            V081125, V000407, V032031, V007559, V008544]

        @testset "Products" begin
            for v in V SeqTest(v, 'V') end
        end
    end
end

function demo()
    for n in 0:6
        println([RisingFactorial(n, k) for k in 0:7])
    end

    for n in 0:6
        println([FallingFactorial(n, k) for k in 0:7])
    end

    println(∏([FallingFactorial(n, n) for n in 0:12]))
    println(Product([FallingFactorial(n, n) for n in 0:12]))

    for n in 0:4, k in 0:4 println(n, k, " → ", n ↑ k, " ", n ↓ k) end
    println()
end

"""
for n in 1:10000 F!(n) end
    1.480517 seconds (10.00 k allocations: 156.250 KiB)
for n in 1:1000 A000407(n) end
    0.177942 seconds (997.77 k allocations: 15.225 MiB)
for n in 1:200, k in 1:200 Pochhammer(n, k) end
    1.784024 seconds (4.43 M allocations: 67.596 MiB, 33.35% gc time)
"""
function perf()
    GC.gc()
    @time (for n in 1:10000 F!(n) end)
    GC.gc()
    @time (for n in 1:1000 V000407(n) end)
    GC.gc()
    @time (for n in 1:200, k in 1:200 RisingFactorial(n, k) end)
end

function main()
    test()
    demo()
    perf()
end

main()

end # module

#=

Test Summary: | Pass  Total
FallingFact   |    4      4
Test Summary: | Pass  Total
RisingFact    |    4      4
Test Summary: | Pass  Total
MultiFact     |    1      1

Nemo.fmpz[1, 0, 0, 0, 0, 0, 0, 0]
Nemo.fmpz[1, 1, 2, 6, 24, 120, 720, 5040]
Nemo.fmpz[1, 2, 6, 24, 120, 720, 5040, 40320]
Nemo.fmpz[1, 3, 12, 60, 360, 2520, 20160, 181440]
Nemo.fmpz[1, 4, 20, 120, 840, 6720, 60480, 604800]
Nemo.fmpz[1, 5, 30, 210, 1680, 15120, 151200, 1663200]
Nemo.fmpz[1, 6, 42, 336, 3024, 30240, 332640, 3991680]
Nemo.fmpz[1, 0, 0, 0, 0, 0, 0, 0]
Nemo.fmpz[1, 1, 0, 0, 0, 0, 0, 0]
Nemo.fmpz[1, 2, 2, 0, 0, 0, 0, 0]
Nemo.fmpz[1, 3, 6, 6, 0, 0, 0, 0]
Nemo.fmpz[1, 4, 12, 24, 24, 0, 0, 0]
Nemo.fmpz[1, 5, 20, 60, 120, 120, 0, 0]
Nemo.fmpz[1, 6, 30, 120, 360, 720, 720, 0]

127313963299399416749559771247411200000000000
127313963299399416749559771247411200000000000

00 → 1 1
01 → 0 0
02 → 0 0
03 → 0 0
04 → 0 0ü
10 → 1 1
11 → 1 1
12 → 2 0
13 → 6 0
14 → 24 0
20 → 1 1
21 → 2 2
22 → 6 2
23 → 24 0
24 → 120 0
30 → 1 1
31 → 3 3
32 → 12 6
33 → 60 6
34 → 360 0
40 → 1 1
41 → 4 4
42 → 20 12
43 → 120 24
44 → 840 24

  1.469480 seconds (10.00 k allocations: 156.250 KiB)
  0.183021 seconds (997.77 k allocations: 15.225 MiB)
  1.953392 seconds (4.43 M allocations: 67.596 MiB, 31.24% gc time)

=#
