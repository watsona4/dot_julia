# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module GaussFactorials

using Nemo, IterTools
using RecordSearch, NumberTheory, Products

export ModuleGaussFactorials, GaussFactorial
export V216919, V001783, V055634, V232980, V232981, V232982, V124441, V124442, V066570
export I193338, F193338, L193338, V193338
export I193339, F193339, L193339, V193339

"""
The Gauß factorial is ``∏_{1 ≤ j ≤ N, j ⊥ n} j``, the product of the positive integers which are ``≤ N`` and are prime to ``n``.

* GaussFactorial, I193338, F193338, L193338, V193338, I193339, F193339, L193339, V193339, V216919, V001783, V055634, V232980, V232981, V232982, V124441, V124442, V066570
"""
const ModuleGaussFactorials = ""

"""
Return ``∏_{1 ≤ j ≤ N, j ⊥ n} j``, the product of the positive integers which are ``≤ N`` and are prime to ``n``.
"""
GaussFactorial(N, n) = ∏([j for j in 1:Int(N) if ⊥(j, n)])

"""
Return ``∏_{1 ≤ j ≤ n, j ⊥ n} j``, the product of the positive integers which are ``≤ n`` and are prime to ``n``.
"""
GaussFactorial(n) = GaussFactorial(n, n)

# V000142(n) = n! = GaussFactorial(n, 1).
# V001147(n) = GaussFactorial(2*n, 2), double factorial of odd numbers.

"""
Return GaussFactorial(N, n).
"""
V216919(N, n) = GaussFactorial(N, n)

"""
Return ``∏_{1 ≤ j ≤ n, j ⊥ n} j``, the product of the positive integers which are ``≤ N`` and are prime to ``n``, a.k.a. the phi-torial of n.
"""
V001783(n) = GaussFactorial(n, n)

""" 
Return the 2-adic factorial of n.
"""
V055634(n) = GaussFactorial(n, 2)*(-1)^n

""" 
Return GaussFactorial(n, 3).
"""
V232980(n) = GaussFactorial(n, 3)

""" 
Return GaussFactorial(n, 5).
"""
V232981(n) = GaussFactorial(n, 5)

""" 
Return GaussFactorial(n, 6).
"""
V232982(n) = GaussFactorial(n, 6)

"""
Return GaussFactorial(div(n, 2), n).
"""
V124441(n) = GaussFactorial(div(n, 2), n)

"""
Return GaussFactorial(n, n)/GaussFactorial(div(n, 2), n).
"""
V124442(n) = div(GaussFactorial(n, n), GaussFactorial(div(n, 2), n))

"""
Return GaussFactorial(n, 1)/GaussFactorial(n, n).
"""
V066570(n) = div(GaussFactorial(n, 1), GaussFactorial(n, n))

# -----------------------------------------------------------------
# Indices!

"""
Iterate over the indices of the first ``n`` record values of the Gauß factorial.
"""
I193339(n) = Records(GaussFactorial, n, true, true)

"""
Iterate over indices of the record values of the Gauß factorial which do not exceed ``n`` (``1 ≤ i ≤ n``).
"""
F193339(n) = Records(GaussFactorial, n, false, true)

"""
Return the indices of the first ``n`` record values of the Gauß factorial as an array.
"""
L193339(n) = collect(I193339(n))

"""
Return the index of the ``n``-th record value of the Gauß factorial.
"""
V193339(n) = nth(I193339(n), n)

# -----------------------------------------------------------------
# Values!

"""
Iterate over the first ``n`` record values of the Gauß factorial (``1 ≤ r``).
"""
I193338(n) = Records(GaussFactorial, n, true, false)

"""
Iterate over the record values of the Gauß factorial which do not exceed ``n`` (``1 ≤ i ≤ n``).
"""
F193338(n) = Records(GaussFactorial, n, false, false)

"""
Return the first ``n`` record values of the Gauß factorial as an array.
"""
L193338(n) = collect(I193338(n))

"""
Return the (value of the) ``n``-th record of the Gauß factorial.
"""
V193338(n) = nth(I193338(n), n)

#START-TEST-########################################################

using Test, SeqTests

function test()

    @testset "GaussFactorial" begin

        #@test 
        if is_oeis_installed()

            V = [V001783, V124441, V124442, V066570]
            for v in V SeqTest(v, 'V', 1) end
            
            W = [V055634, V232980, V232981, V232982]
            for w in W SeqTest(w, 'V', 0) end
        end
    end
end

function demo()
    println("\n Iterate over the indices of the first 10 record values of the Gauß factorial.")
    for r in I193339(10) print(r, ", ") end; println("...")

    println("\n Iterate over indices of the record values of the Gauß factorial which do not exceed 10.")
    for r in F193339(10) print(r, ", ") end; println("...")

    println("\n Return the indices of the first 10 record values of the Gauß factorial as an array.")
    println(L193339(10))

    println("\n Return the index of the 9-th record value of the Gauß factorial.")
    println("9 -> ", V193339(9))

    println("\n Iterate over the first 10 record values of the Gauß factorial.")
    for r in I193338(10) print(r, ", ") end; println("...")

    println("\n Iterate over the record values of Gauß factorial which do not exceed 10.")
    for r in F193338(10) print(r, ", ") end; println("...")

    println("\n Return the first 10 record values of the Gauß factorial as an array.")
    println(L193338(10))

    println("\n Return the (value of the) 9-th record of the Gauß factorial.")
    println("9 -> ", V193338(9))
end

function perf()
end

function main()
    test()
    demo()
    perf()
end

main()

end # module

#=
Iterate over the indices of the first 10 record values ofthe Gauß factorial.
1, 3, 4, 5, 7, 9, 11, 13, 17, ...

Iterate over indices of the record values of the Gauß factorial which do not exceed 10.
1, 3, 4, 5, 7, 9, ...

Return the indices of the first 10 record values of the Gauß factorial as an array.
Nemo.fmpz[1, 3, 4, 5, 7, 9, 11, 13, 17]

Return the index of the 9-th record value of the Gauß factorial.
9 -> 13

Iterate over the first 10 record values of the Gauß factorial.
1, 2, 3, 24, 720, 2240, 3628800, 479001600, 20922789888000, ...

Iterate over the record values of Gauß factorial which do
not exceed 10.
1, 2, 3, 24, 720, 2240, ...

Return the first 10 record values of the Gauß factorial as an array.
Nemo.fmpz[1, 2, 3, 24, 720, 2240, 3628800, 479001600, 20922789888000]

Return the (value of the) 9-th record of the Gauß factorial.
9 -> 479001600
=#
