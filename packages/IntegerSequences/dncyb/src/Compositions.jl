# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module Compositions

using Nemo, IterTools, Triangles

export ModuleCompositions
export I097805, L097805, V097805, M097805

"""
* I097805, L097805, V097805, M097805
"""
const ModuleCompositions = ""

"""
Recurrence for `A097805`, the compositions of ``n`` with ``k`` parts.
"""
function R097805(n, k, prevrow::Function)
    k == 0 && return ZZ(k^n)
    prevrow(k - 1) + prevrow(k)
end

"""
Iterates over the first ``n`` rows of A097805.
"""
I097805(n) = RecTriangle(n, R097805)

"""
Lists the first ``n`` rows of A097805 by concatinating. This is the format for submissions to the OEIS.
"""
L097805(n) = vcat(I097805(n)...)

"""
Return the triangular array as a square matrix.
"""
M097805(dim) = fromΔ(L097805(dim))

"""
Return row ``n`` of A097805 based on the iteration I097805(n).
"""
V097805(n) = nth(I097805(n+1), n+1)


#START-TEST-########################################################

# Return row n of A097805 based on a closed formula.
VN097805(n) = n == 0 ? fmpz[1]   : [Nemo.binom(n-1, k-1)       for k in 0:n]
VJ097805(n) = n == 0 ? BigInt[1] : [binomial(BigInt(n-1), k-1) for k in 0:n]

function test()
end

function demo()
    println("\nIterates over the first n rows of A097805.")
    for r in I097805(9) println(r) end

    println("\nLists the first 9 rows of L097805 by concatinating.")
    println(L097805(9))

    #ShowAsMatrix(L097805(9))
    #println(M097805(9))

    println("\nReturns row 8 of A097805 based on the iteration I097805(8).")
    println(V097805(8))

    println("\nReturns row 8 of A097805 based on a closed formula.")
    println(VN097805(8))

    println("\nReturns row n of A097805 based on the iteration I097805(n).")
    for n in 0:8 println(n, ": ", V097805(n)) end

    println("\nBenchmark the construction of the first 500 rows of A097805 based on Iteration.")
    #  0.111066 seconds (253.51 k allocations: 7.795 MiB)
    GC.gc()
    @time L097805(500)

    println("\nBenchmark the construction of the first 500 rows of A097805 based on closed formula.")
    # Result: 0.479466 seconds (1.72 M allocations: 21.592 MiB)
    FList(n) = vcat([VN097805(k) for k in 0:n-1]...)
    GC.gc()
    @time FList(500)

    println("\nBenchmark the construction of the first 500 rows of A097805 based on closed formula.")
    # 0.476226 seconds (1.72 M allocations: 21.592 MiB)
    FList(n) = vcat([VJ097805(k) for k in 0:n-1]...)
    GC.gc()
    @time FList(500)

    println("\nResume: Construction based on Iteration is about 4 times faster")
    println("than based on the closed formula and uses much less memory.")
end

"""
L097805(500) :: 0.111066 seconds (253.51 k allocations: 7.795 MiB)
"""
function perf()
    GC.gc()
    @time L097805(500)
end

function main()
    test()
    demo()
    perf()
end

main()

end # module
