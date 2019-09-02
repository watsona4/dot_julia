# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module CarmichaelNumbers

using Nemo, NumberTheory, Counts

export ModuleCarmichaelNumbers
export isCarmichael, I002997, F002997, L002997
export isweakCarmichael, I225498, F225498, L225498

"""
* isCarmichael, I002997, F002997, L002997
* isweakCarmichael, I225498, F225498, L225498
"""
const ModuleCarmichaelNumbers = ""

"""
Is ``n`` a Carmichael/Šimerka number?
"""
function isCarmichael(n)
    (n == 1 || isEven(n) || isPrime(n)) && return false
    for f in Factors(n)
        (f[2] > 1 || (n - 1) % (f[1] - 1) != 0) && return false
    end
    return true
end

"""
Iterate over the first n Carmichael/Šimerka numbers.
"""
I002997(n) = takeFirst(isCarmichael, n)

"""
Iterate over the Carmichael/Šimerka numbers which do not exceed n.
"""
F002997(n) = filter(isCarmichael, 1:n)

"""
Return the first n Carmichael/Šimerka numbers in an array.
"""
L002997(n) = collect(I002997(n))

"""
Is ``n`` a weak Carmichael number?
"""
function isweakCarmichael(n)
    (n == 1 || isEven(n) || isPrime(n)) && return false
    for f in Factors(n)
        (n - 1) % (f[1] - 1) != 0 && return false
    end
    return true
end

"""
Iterate over the first n weak Carmichael numbers.
"""
I225498(n) = takeFirst(isweakCarmichael, n)

"""
Iterate over the weak Carmichael numbers which do not exceed n.
"""
F225498(n) = filter(isweakCarmichael, 1:n)

"""
Return the first n weak Carmichael numbers in an array.
"""
L225498(n) = collect(I225498(n))

#START-TEST-########################################################

using Test, SeqTests

function test()
    @testset "Carmichael" begin
        @test ! isCarmichael(560)
        @test isCarmichael(561)
        @test ! isCarmichael(563)
        @test isweakCarmichael(561)
        @test !isweakCarmichael(563)
        @test isweakCarmichael(625)

        if is_oeis_installed()
            L = [L002997, L225498]
            SeqTest(L, 'L')
        end

    end
end

function demo()
    for n in 1:30000
        isCarmichael(n) && println(n)
    end

    println()
    for v in I225498(10)
        println(v)
    end
end

"""
@time L = L002997(30)
0.967192 seconds (4.01 M allocations: 248.863 MiB, 28.97% gc time)
"""
function perf()
    @time L = L002997(30)
end

function main()
    test()
    demo()
    perf()
end

main()

end # module
