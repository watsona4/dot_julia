# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module Kolakoski

using Nemo

export ModuleKolakoski
export KolakoskiList, C000002, I000002, L000002

"""
* KolakoskiList, C000002, I000002, L000002
"""
const ModuleKolakoski = ""

"""
Generate the Kolakoski sequence which is the unique sequence over the alphabet ``{1, 2}`` starting with ``1`` and having the sequence of run lengths identical with itself.
"""
C000002() = Channel(csize = 10) do c
    x = y = Int(-1)

    while true
        put!(c, [2, 1][(x & 1) + 1])
        f = y & ~(y + 1)
        x = xor(x, f)
        y = (y + 1) | (f & (x >> 1))
    end
end

struct KolakoskiSeq
    count::Int
    ch::Channel
    KolakoskiSeq(count) = new(count, C000002())
end

function Base.iterate(I::KolakoskiSeq)
    if I.count == 0
        close(I.ch)
        return nothing
    end
    (take!(I.ch), (0))
end

function Base.iterate(I::KolakoskiSeq, S)
    j = S[1] + 1
    if I.count == j
        close(I.ch)
        return nothing
    end
    (take!(I.ch), (j))
end

Base.length(I::KolakoskiSeq) = I.count
Base.eltype(I::KolakoskiSeq) = Int

"""
Iterate over the first ``n`` Kolakoski numbers.
"""
I000002(n::Int) = KolakoskiSeq(n)

"""
Return the list of the first ``n`` terms of the Kolakoski sequence.
"""
function KolakoskiList(len::Int)
    len ≤ 0 && return []
    generator = C000002()
    L = [take!(generator) for _ in 1:len]
    close(generator)
    return L
end

"""
Return the list of the first ``n`` terms of the Kolakoski sequence.
"""
L000002(n::Int) = KolakoskiList(n)

#START-TEST-########################################################

using Test

function test()

    @testset "Kolakoski" begin
        K = KolakoskiList(100)
        @test K[1]  == 1
        @test K[33] == 2
        @test K[72] == 2

        generator = C000002()
        for n in [1, 33, 72]
            k = take!(generator)
            @test K[n] == k
        end
        close(generator)
    end
end

function demo()
    println(KolakoskiList(20))

    generator = C000002()
    o = e = 0
    for n in 1:80
        take!(generator) == 1 ? o += 1 : e += 1
        print(o - e, " ")
    end
    println()
    close(generator)

    for f in I000002(20) print(f, ", ") end; println()
    print(L000002(20)); println()
end

"""
I000002(100000) ::
    0.000035 seconds (31 allocations: 2.969 KiB)
KolakoskiList(10000) ::
    0.086202 seconds (120.03 k allocations: 10.226 MiB, 17.61% gc time)
"""
function perf()
    @time I000002(100000)
    @time KolakoskiList(100000)
end

function main()
    test()
    demo()
    perf()
end

main()

end # module

#=

[1, 2, 2, 1, 1, 2, 1, 2, 2, 1, 2, 2, 1, 1, 2, 1, 1, 2, 2, 1]

1 0 -1 0 1 0 1 0 -1 0 -1 -2 -1 0 -1 0 1 0 -1 0 -1 0 1 0 1 0 -1 0
1 0 1 2 1 2 1 0 1 0-1 0 1 0 1 0 -1 0 -1 0 1 0 1 2 1 0 1 0 -1 0 1
0 1 0 -1 0 -1 -2 -1 0 -1 0 1 0 1 0 -1 0 -1 0 1 0

1, 2, 2, 1, 1, 2, 1, 2, 2, 1, 2, 2, 1, 1, 2, 1, 1, 2, 2, 1,

[1, 2, 2, 1, 1, 2, 1, 2, 2, 1, 2, 2, 1, 1, 2, 1, 1, 2, 2, 1]

  0.000035 seconds (31 allocations: 2.969 KiB)
  0.086202 seconds (120.03 k allocations: 10.226 MiB, 17.61% gc time)

=#
