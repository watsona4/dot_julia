# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module AndreNumbers
using Nemo

export ModuleAndreNumbers
export André, C000111, V000111, V178963, V178964, V181936, V250283

"""
Generalized André numbers count the ``m``-alternating permutations of length ``n``, cf. A181937.

```
[  SEQ  ] n|k [0][1][2][3][4] [5] [6]  [7]   [8]   [9]  [10]
[V000012] [1]  1, 1, 1, 1, 1,  1,  1,   1,    1,    1,     1
[V000111] [2]  1, 1, 1, 2, 5, 16, 61, 272, 1385, 7936, 50521
[V178963] [3]  1, 1, 1, 1, 3,  9, 19,  99,  477, 1513, 11259
[V178964] [4]  1, 1, 1, 1, 1,  4, 14,  34,   69,  496,  2896
[V181936] [5]  1, 1, 1, 1, 1,  1,  5,  20,   55,  125,   251
[V250283] [6]  1, 1, 1, 1, 1,  1,  1,   6,   27,   83,   209
```

* André, C000111, V000111, V178963, V178964, V181936, V250283.
"""
const ModuleAndreNumbers = ""

"""
Return the generalized André numbers which are the ``m``-alternating permutations of length ``n``, cf. A181937.
"""
function André(m::Int, n::Int)
    haskey(CacheAndré, (m, n)) && return CacheAndré[(m, n)]
    n ≤ 0 && return fmpz(1)
    r = range(0, step=m, stop=n-1)
    S = sum(binom(n, k) * André(m, k) for k in r)
    V = n % m == 0 ? -S : S
    CacheAndré[(m, n)] = V
    return V
end

const CacheAndré = Dict{Tuple{Int, Int}, fmpz}()

"""
Return the generalized André numbers which are the ``m``-alternating permutations of length ``n``.
"""
V181937(m::Int, n::Int) = abs(André(m, n))

"""
Return the up-down numbers (2-alternating permutations).
"""
V000111(n::Int) = abs(André(2, n))

"""
Return the number of 3-alternating permutations.
"""
V178963(n::Int) = abs(André(3, n))

"""
Return the number of 4-alternating permutations.
"""
V178964(n::Int) = abs(André(4, n))

"""
Return the number of 5-alternating permutations.
"""
V181936(n::Int) = abs(André(5, n))

"""
Return the number of 6-alternating permutations.
"""
V250283(n::Int) = abs(André(6, n))

"""
Generate the André numbers (a.k.a. Euler-up-down numbers A000111). Don't confuse with the Euler numbers A122045.
"""
C000111() = Channel(csize=2) do c
    D = Dict{Int,fmpz}(0 => 1, -1 => 0)
    i = k = 0
    s = 1

    while true
        A = 0; D[k + s] = 0; s = -s
        for j in 0:i
            A += D[k]; D[k] = A; k += s
        end
        put!(c, A)
        i += 1
    end
end

#START-TEST-########################################################

using Test, SeqTests, SeqUtils

function test()
    @testset "André" begin

        @test isa(André(2, 10), Nemo.fmpz)

        @test André(2, 10) == ZZ(-50521)
        @test André(2, 50) == ZZ(-6053285248188621896314383785111649088103498225146815121)
        @test V178963(30)  == ZZ(2716778010767155313771539)
        @test V178964(40)  == ZZ(11289082167259099068433198467575829)

        if is_oeis_installed()
            V = [V000111, V178963, V178964, V181936, V250283]
            for v in V SeqTest(v, 'V') end
        end

        V = [1, 1, 1, 2, 5, 16, 61, 272, 1385, 7936, 50521]
        generator = C000111()
        for n in 1:10
            v = take!(generator)
            @test V[n]  == v
        end

        v = take!(generator)
        close(generator)

        @test isa(v, fmpz)
    end
end

function demo()
    for m in 1:8
        Println([André(m, n) for n in 0:11])
    end

    println()
    generator = C000111()
    for n in 0:10
        v = take!(generator)
        println(n, " ↦ ", v)
    end
    close(generator)
end

"""
for m in 1:20, n in 0:100 André(m,n) end
    0.012252 seconds (66.73 k allocations: 1.341 MiB)
"""
function perf()
    GC.gc()
    @time (for m in 1:20, n in 0:100 André(m, n) end)
end

function main()
    test()
    demo()
    perf()
end

main()

for n in 0:32
    println(André(3, n))
end

end # module
