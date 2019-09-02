# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module ClausenNumbers
using  Nemo, PrimesIterator, Products, NumberTheory

export ModuleClausenNumbers
export ClausenNumber, ClausenNumberList
export V002445, L002445, V027642

"""
* ClausenNumber, ClausenNumberList, V002445, L002445, V027642
"""
const ModuleClausenNumbers = ""

"""
Return the Clausen number ``C_n`` which is the denominator of the Bernoulli number ``B_{2n}``.
"""
function ClausenNumber(n::Int)
    n == 0 && return ZZ(1)
    m = [d + 1 for d in Divisors(2n)]
    ∏([q for q in m if isPrime(q)])
end

"""
Return the list of length len of Clausen numbers which are the denominators of the Bernoulli numbers ``B_{2n}``.
"""
function ClausenNumberList(len::Int)
    len ≤ 0 && return fmpz[]

    A = fill(ZZ(2), len);  A[1] = 1
    m = len - 1
    m == 0 && return A

    for p in Primes(3, 2m + 1)
        r = div(p - 1, 2)
        for k in range(r, step=r, length=div(m, r))
            A[k+1] *= p
        end
    end
    A
end

"""
Return the Clausen number ``C(n)`` which is the denominator of the Bernoulli number ``B_{2n}``.
"""
V002445(n::Int) = ClausenNumber(n)

"""
Return the list of length len of Clausen numbers which are the denominators of the Bernoulli numbers ``B_{2n}``.
"""
L002445(len::Int) = ClausenNumberList(len)

"""
Return the denominator of Bernoulli number ``B_n``.
"""
function V027642(n::Int)
    isEven(n) && return ClausenNumber(div(n, 2))
    n == 1 && return ZZ(2)
    return ZZ(1)
end

#START-TEST-########################################################

using Test, SeqUtils, SeqTests

function test()

    @testset "Clausen" begin
        C = ClausenNumberList(800)
        @test C[125] == 30
        @test C[781] == 32695402455500348373810
        @test C[794] == 6

        @test isa(C[781], Nemo.fmpz)
        @test isa(ClausenNumber(10), Nemo.fmpz)
    end

    if is_oeis_installed()
        SeqTest([L002445], 'L')
        SeqTest(V002445, 'V', 0)
        SeqTest(V027642, 'V', 0)
    end
end

function demo()
    println("\nReturn the Clausen number C(n) which is the denominator of the Bernoulli number B(2n).")
    for n in 0:10
        println(n, " ↦ ", V002445(n))
    end

    println("\nReturn the denominator of Bernoulli number B_n.")
    for n in 0:10
        println(n, " ↦ ", V027642(n))
    end

    println()
    for n in 0:6
        print(n, " ↦ ")
        Println(ClausenNumberList(n))
    end

    println()
    Println(ClausenNumberList(9))
    println()
end

"""
# ClausenNumberList is ~ 16 times faster than a list of ClausenNumbers!
ClausenNumberList(10000) ::
    0.016498 seconds (141.08 k allocations: 2.252 MiB)
for n in 0:10000 ClausenNumber(n) end ::
    0.737140 seconds (2.40 M allocations: 66.330 MiB, 53.08% gc time)
"""
function perf()
    GC.gc()
    @time ClausenNumberList(10000)
    @time (for n in 0:10000 ClausenNumber(n) end)
end

function main()
    test()
    demo()
    perf()
end

main()

end # module

#=

0 ↦ Nemo.fmpz[]
1 ↦ Nemo.fmpz[3]
2 ↦ Nemo.fmpz[3, 30]
3 ↦ Nemo.fmpz[3, 30, 42]
4 ↦ Nemo.fmpz[3, 30, 42, 30]
5 ↦ Nemo.fmpz[3, 30, 42, 30, 66]
6 ↦ Nemo.fmpz[3, 30, 42, 30, 66, 2730]

0 ↦ 1
1 ↦ 2
2 ↦ 6
3 ↦ 1
4 ↦ 30
5 ↦ 1
6 ↦ 42
7 ↦ 1
8 ↦ 30
9 ↦ 1
10 ↦ 66

  0.009131 seconds (141.08 k allocations: 2.252 MiB)
  0.633522 seconds (2.40 M allocations: 66.330 MiB, 57.26% gc time)
=#
