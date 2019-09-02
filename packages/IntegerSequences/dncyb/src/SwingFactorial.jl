# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module SwingFactorial

using Nemo

export ModuleSwingFactorial
export Sfactorial

"""
Basic implementation of the swing algorithm using no primes. Claims to be the most efficient simple algorithm to compute the factorial. An advanced version based on prime-factorization is available as the prime-swing factorial factorialPS.

* Sfactorial
"""
const ModuleSwingFactorial = ""

"""
Return the factorial of ``n``. Basic implementation of the swing algorithm using no primes. An advanced version based on prime-factorization is available as the prime-swing factorial factorialPS.
"""
function Sfactorial(n::Int)::fmpz

    smallOddFactorial =           fmpz[0x0000000000000000000000000000001,
    0x0000000000000000000000000000001, 0x0000000000000000000000000000001,
    0x0000000000000000000000000000003, 0x0000000000000000000000000000003,
    0x000000000000000000000000000000f, 0x000000000000000000000000000002d,
    0x000000000000000000000000000013b, 0x000000000000000000000000000013b,
    0x0000000000000000000000000000b13, 0x000000000000000000000000000375f,
    0x0000000000000000000000000026115, 0x000000000000000000000000007233f,
    0x00000000000000000000000005cca33, 0x0000000000000000000000002898765,
    0x00000000000000000000000260eeeeb, 0x00000000000000000000000260eeeeb,
    0x0000000000000000000000286fddd9b, 0x00000000000000000000016beecca73,
    0x000000000000000000001b02b930689, 0x00000000000000000000870d9df20ad,
    0x0000000000000000000b141df4dae31, 0x00000000000000000079dd498567c1b,
    0x00000000000000000af2e19afc5266d, 0x000000000000000020d8a4d0f4f7347,
    0x000000000000000335281867ec241ef, 0x0000000000000029b3093d46fdd5923,
    0x0000000000000465e1f9767cc5866b1, 0x0000000000001ec92dd23d6966aced7,
    0x0000000000037cca30d0f4f0a196e5b, 0x0000000000344fd8dc3e5a1977d7755,
    0x000000000655ab42ab8ce915831734b, 0x000000000655ab42ab8ce915831734b,
    0x00000000d10b13981d2a0bc5e5fdcab, 0x0000000de1bc4d19efcac82445da75b,
    0x000001e5dcbe8a8bc8b95cf58cde171, 0x00001114c2b2deea0e8444a1f3cecf9,
    0x0002780023da37d4191deb683ce3ffd, 0x002ee802a93224bddd3878bc84ebfc7,
    0x07255867c6a398ecb39a64b83ff3751, 0x23baba06e131fc9f8203f7993fc1495]

    function oddProduct(m::Int, len::Int)
        if len < 24
            p = fmpz(m)
            for k in 2:2:2(len-1)
                p *= (m - k)
            end
            return p
        end
        hlen = len >> 1
        oddProduct(m - 2 * hlen, len - hlen) * oddProduct(m, hlen)
    end

    function oddFactorial(n)
        if n < 41
            oddFact = smallOddFactorial[1+n]
            sqrOddFact = smallOddFactorial[1+div(n, 2)]
        else
            sqrOddFact, oldOddFact = oddFactorial(div(n, 2))
            len = div(n - 1, 4)
            (n % 4) != 2 && (len += 1)
            high = n - ((n + 1) & 1)
            oddSwing = div(oddProduct(high, len), oldOddFact)
            oddFact = sqrOddFact^2 * oddSwing
        end
        (oddFact, sqrOddFact)
    end

    n < 0 && ArgumentError("n must be ≥ 0")
    if n == 0 return fmpz(1) end
    sh = n - count_ones(n)
    oddFactorial(n)[1] << sh
end

#START-TEST-########################################################

using Test

function test()
    @testset "SwingFactorial" begin
        for n in 0:999
            S = Sfactorial(n)
            B = Base.factorial(BigInt(n))
            @test S == B
        end
    end
end

function demo()
end

function perf()
    # n = 10^6
    # 0.372059 seconds     (   911 allocations:  48.628 MiB,  1.12% gc time)
    # 1.033867 seconds     (2.57 M allocations: 153.290 MiB, 13.31% gc time)

    # n = 7250000
    # 3.759344 seconds (8.86 k allocations: 483.946 MiB, 7.25% gc time)
    # 9.922223 seconds (22.30 M allocations: 1.316 GiB, 10.44% gc time)


    # n = 10^7
    #  6.256117 seconds   (11.34 k allocations: 682.953 MiB,  3.32% gc time)
    # 15.678733 seconds   (25.56 M allocations:   2.081 GiB, 10.72% gc time)

    # n = 10^8
    #  96.296497 seconds (381.72 k allocations:   9.686 GiB, 1.76% gc time)
    # 237.375884 seconds (258.40 M allocations:  28.133 GiB, 6.73% gc time)

    GC.gc()
    n = 1000000
    @time Base.factorial(BigInt(n))
    @time Sfactorial(n)
    println("n = $n")
end

function main()
    test()
    demo()
    perf()
end

main()

end # module
