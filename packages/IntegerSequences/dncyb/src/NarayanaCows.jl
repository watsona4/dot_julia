# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

# Another demo for Julia's iteration protokoll.
# Also demonstrates the layout of an IntegerSequences module.

module NarayanaCows
using IterTools
export ModuleNarayanaCows, NarayanasCows, L214551

"""
* NarayanasCows, L214551

For background information see
* J.-P. Allouche, T. Johnson, [Narayana's Cows and Delayed Morphisms](http://recherche.ircam.fr/equipes/repmus/jim96/actes/Allouche.ps).
* C.M. Wilmott, [From Fibonacci to the mathematics of cows and quantum circuitry](https://iopscience.iop.org/article/10.1088/1742-6596/574/1/012097/pdf).
"""
const ModuleNarayanaCows = ""

"""
The type object to construct a new instance of the modified Narayanas cows sequence with given length.
"""
struct NarayanasCows
    length
end

"""
Return the first term of the modified Narayanas cows sequence.
"""
function Base.iterate(I::NarayanasCows)
    I.length == 0 && return nothing
    state = (1, (0, 0, 1, 1))
end

"""
Return the next term of the modified Narayanas cows sequence.
"""
function Base.iterate(I::NarayanasCows, (x, y, z, c))
    c >= I.length && return nothing
    x = div(z + x, gcd(z, x))
    (x, (y, z, x, c + 1))
end

Base.length(f::NarayanasCows) = f.length
Base.eltype(f::NarayanasCows) = Int

"""
Return a list of the first n terms of the modified Narayanas cows sequence.
"""
L214551(n) = collect(NarayanasCows(n))

#START-TEST-########################################################

using Test, SeqUtils

function test()
    @testset "Narayana" begin
        @test IterTools.nth(NarayanasCows(12), 12) == 5
    end
end

function demo()
    for cow in NarayanasCows(20)
        print(cow, ", ")
    end
    println()

    L214551(20) |> println
    println()

    SeqShow(L214551(20))
end

function perf()
    @time (for cow in NarayanasCows(10000) end)
end

function main()
    test()
    demo()
    perf()
end

main()

end # module
