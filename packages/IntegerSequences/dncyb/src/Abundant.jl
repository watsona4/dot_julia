# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module Abundant
using NumberTheory, IterTools, Counts

export ModuleAbundant
export isAbundant, is005101, I005101, F005101, L005101, V005101

"""
``n`` is an abundant number if ``σ(n) > 2n``. An abundant number is a number for which the sum of its proper divisors is greater than the number itself.

* isAbundant, is005101, I005101, F005101, L005101, V005101.
"""
const ModuleAbundant = ""

"""
Is ``n`` an abundant number, i.e. is ``σ(n) > 2n`` ?
"""
isAbundant(n) = σ(n) > 2n

"""
Is ``n`` a term of sequence A005101?
"""
is005101(n) = isAbundant(n)

"""
Iterate over the first ``n`` abundant numbers.
"""
I005101(n) = takeFirst(isAbundant, n)

"""
Iterate over the abundant numbers which do not exceed ``n (1 ≤ i ≤ n)``.
"""
F005101(n) = Iterators.filter(isAbundant, 1:n)

"""
Return a list of the  first ``n`` abundant numbers.
"""
L005101(n) = collect(I005101(n))

"""
Return the value of the ``n``-th abundant number.
"""
V005101(n) = nth(I005101(n), n)

#START-TEST-########################################################

using Test, SeqTests, SeqUtils

function test()
    @testset "Abundant" begin
        @test isAbundant(100800) == true
        @test isAbundant(2402400) == true
        @test isAbundant(49008960) == true

        if is_oeis_installed()
            SeqTest([L005101], 'L')
        end
    end
end

function demo()
    println(V005101(15))
    println(L005101(15))

    for a in I005101(15) print(a, ", ") end; println("...")
    for a in F005101(40) print(a, ", ") end; println("...")

    for n in 40:50 println(n, " ↦ ", isAbundant(n)) end
    for n in 1:6   println(n, " ↦ ", L005101(n)) end

    for a in I005101(1000)
        isodd(a) && print(a, " ")
    end
    println()
end

"""
L005101(5000)
    0.018731 seconds (40.38 k allocations: 759.328 KiB)
"""
function perf()
    GC.gc()
    @time L005101(5000)
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
Abundant      |    3      3

72

[12, 18, 20, 24, 30, 36, 40, 42, 48, 54, 56, 60, 66, 70, 72]
12, 18, 20, 24, 30, 36, 40, 42, 48, 54, 56, 60, 66, 70, 72, ...
12, 18, 20, 24, 30, 36, 40, ...

40 ↦ true
41 ↦ false
42 ↦ true
43 ↦ false
44 ↦ false
45 ↦ false
46 ↦ false
47 ↦ false
48 ↦ true
49 ↦ false
50 ↦ false

1 ↦ [12]
2 ↦ [12, 18]
3 ↦ [12, 18, 20]
4 ↦ [12, 18, 20, 24]
5 ↦ [12, 18, 20, 24, 30]
6 ↦ [12, 18, 20, 24, 30, 36]

945 1575 2205 2835 3465

0.018731 seconds (40.38 k allocations: 759.328 KiB)
=#
