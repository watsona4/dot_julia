# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module BinaryInteger

export ModuleBinaryInteger
export V001855, V003314, V033156, V054248, V061168, V083652, V097383, V123753
export V295513, BinaryIntegerLength, Bil

"""
For positive n, BinaryIntegerLength is ``⌊ log[2](n) ⌋ + 1``, BinaryIntegerLength(0) = 0.

* BinaryIntegerLength, Bil, V001855, V003314, V033156, V054248, V061168, V083652, V097383, V123753, V295513
"""
const ModuleBinaryInteger = ""

"""
Return the length of the binary extension of an integer ``n``, which is defined as ``0`` if ``n = 0`` and for ``n > 0`` as ``⌊ log[2](n) ⌋ + 1``.
"""
BinaryIntegerLength(n) = n == 0 ? 0 : floor(Int, log2(n)) + 1

"""
Alias for the function BinaryIntegerLength.
"""
Bil(n) = BinaryIntegerLength(n)

"""
Return ``n`` Bil``(n) - 2^{\\text{Bil}(n)}`` where Bil``(n)`` is the binary integer length of ``n``.
"""
V295513(n) = n*Bil(n) - 2^Bil(n)

"""
Maximal number of comparisons for sorting ``n`` elements by binary insertion.
"""
V001855(n) = V295513(n) + 1

"""
Return the sum of lengths of binary expansions of ``0`` through ``n``.
"""
V083652(n) = V295513(n+1) + 2

"""
Recurrence ``a(n) = a(n-1) + ⌊ a(n-1)/(n-1) ⌋ + 2`` for ``m ≥ 2`` and ``a(1) = 1``.
"""
V033156(n) = V295513(n) + 2n

"""
Binary entropy function: ``a(n) = n + `` min ``( a(k) + a(n-k) : 1 ≤ k ≤ n-1 )`` for ``n > 1,`` and ``a(1) = 0``.
"""
V003314(n) = V295513(n) + n

"""
Binary entropy: ``a(n) = n +`` min ``{ a(k) + a(n-k) : 1 ≤ k ≤ n-1 }.``
"""
V054248(n) = V295513(n) + n + rem(n, 2)

"""
Minimum total number of comparisons to find each of the values ``1`` through ``n`` using a binary search with ``3``-way comparisons.
"""
V097383(n) = V295513(n+1) - div(n-1, 2)

"""
Partial sums of the sequence ``⌊ log[2](n) ⌋``.
"""
V061168(n) = V295513(n+1) - n + 1

"""
Partial sums of the sequence of length of the binary expansion of ``2n+1``.
"""
V123753(n) = V295513(n+1) + n + 2

#START-TEST-########################################################

using Test, SeqTests

function test()
    @testset "BinaryInteger" begin

        @test V295513(0) == -1
        @test V295513(1) == -1
        @test V295513(2) == 0
        @test V295513(3) == 2

        if is_oeis_installed()
            V = [V001855, V003314, V033156, V054248, V061168, V097383]
            for v in V SeqTest(v , 'V', 1) end

            V = [V083652, V123753]
            for v in V SeqTest(v , 'V', 0) end
        end
    end
end

function demo()
    println([V295513(n) for n in 0:12])
    println([V123753(n) for n in 0:12])
    println([V001855(n) for n in 1:12])
    println([V083652(n) for n in 1:12])
    println([V033156(n) for n in 1:12])
    println([V003314(n) for n in 1:12])
    println([V054248(n) for n in 1:12])
    println([V097383(n) for n in 1:12])
    println([V061168(n) for n in 1:12])
end

"""
[V295513(k) for k in 0:100000]
    0.014412 seconds (2 allocations: 781.391 KiB)
"""
function perf()
    @time [V295513(k) for k in 0:100000]
end

function main()
    test()
    demo()
    perf()
end

main()

end # module
