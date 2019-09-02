# This file includes portions from JuliaMath/Combinatorics.jl in modified form.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module CombinationsIterator

using IterTools

export ModuleCombinationsIterator
export Combinations

"""
* Combinations
"""
const ModuleCombinationsIterator = ""

#The combinations iterator
struct combinations
    n::Int
    t::Int
end

function Base.iterate(c::combinations, s=[min(c.t - 1, i) for i in 1:c.t])
    if c.t == 0 # special case to generate 1 result for t==0
        isempty(s) && return (s, [1])
        return
    end
    for i in c.t:-1:1
        s[i] += 1
        if s[i] > (c.n - (c.t - i))
            continue
        end
        for j in i + 1:c.t
            s[j] = s[j - 1] + 1
        end
        break
    end
    s[1] > c.n - c.t + 1 && return
    (s, s)
end

Base.length(c::combinations) = binomial(c.n, c.t)
Base.eltype(::Type{combinations}) = Vector{Int}

"""
Generate all Combinations of ``n`` elements from an indexable object ``a``. Because the number of Combinations can be very large, this function returns an iterator object.
 Use collect(Combinations(a, n)) to get an array of all Combinations.
"""
function Combinations(a, t::Integer)
    if t < 0
        # generate 0 Combinations for negative argument
        t = length(a) + 1
    end
    reorder(c) = [a[ci] for ci in c]
    (reorder(c) for c in combinations(length(a), t))
end

"""
Generate Combinations of the elements of ``a`` of all orders. Chaining of order iterators is eager, but the sequence at each order is lazy.
"""
Combinations(a) = Iterators.flatten([Combinations(a, k) for k = 1:length(a)])

#START-TEST-########################################################

using Test, SeqUtils

function test()
    C = collect(Combinations([2, 3, 5]))
    @testset "Combinations" begin
        @test C == [[2], [3], [5], [2, 3], [2, 5], [3, 5], [2, 3, 5]]
    end
end

function demo()
    Println([Combinations("abcd", 3)...])

    D = [2, 3, 4, 5]
    for c in Combinations(D)
        println(c)
    end

    println()
    C = collect(Combinations([2, 3, 5]))
    Println(C)
end

function perf() end

function main()
    test()
    demo()
    perf()
end

main()

end # module

#=

Array{Char,1}[['a', 'b', 'c'], ['a', 'b', 'd'], ['a', 'c', 'd'], ['b', 'c', 'd']]

[2][3]
[4]
[5]
[2, 3]
[2, 4]
[2, 5]
[3, 4]
[3, 5]
[4, 5]
[2, 3, 4]
[2, 3, 5]
[2, 4, 5]
[3, 4, 5]
[2, 3, 4, 5]

=#
