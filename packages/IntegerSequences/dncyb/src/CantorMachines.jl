# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module CantorMachines

export ModuleCantorMachines
export CantorMachine, CantorEnumeration, CantorPairing
export CantorBoustrophedonicMachine, CantorBoustrophedonicEnumeration, CantorBoustrophedonicPairing
export RosenbergStrongBoustrophedonicMachine, RosenbergStrongBoustrophedonicEnumeration, RosenbergStrongBoustrophedonicPairing
export V319514, L319514

"""
[Cantor's enumeration of N X N revisited](https://luschny.wordpress.com/2018/09/24/cantors-enumeration-of-n2-revisited/).

* Cantor-Machine, Cantor-Enumeration, Cantor-Pairing, Cantor-BoustrophedonicMachine, Cantor-BoustrophedonicEnumeration, Cantor-BoustrophedonicPairing, RosenbergStrong-BoustrophedonicMachine, RosenbergStrong-BoustrophedonicEnumeration, RosenbergStrong-BoustrophedonicPairing
"""
const ModuleCantorMachines = ""

# https://luschny.wordpress.com/2018/09/24/cantors-enumeration-of-n2-revisited/
# https://luschny.wordpress.com/2018/09/25/the-cantor-jump-machine/
# https://oeis.org/search?q=A319514&go=Search

"""
The Cantor enumeration implemented as a state machine to avoid the evaluation of the square root function.
"""
function CantorMachine(x, y, state)
    x == 0 && !state && return x, y + 1, !state
    y == 0 &&  state && return x + 1, y, !state
    state && return x + 1, y - 1, state
    return x - 1, y + 1, state
end

"""
The  Cantor enumeration of N X N where N = {0, 1, 2, ...}. If (x, y) and (x', y') are adjacent points on the trajectory of the map then max(|x - x'|, |y - y'|) can become arbitrarily large. In this sense Cantor's enumeration is not continous.
"""
function CantorEnumeration(len)
    x, y, state = 0, 0, false
    for n in 0:len
        #println("$n -> ($x, $y)")
        print("$x, $y, ")
        x, y, state = CantorMachine(x, y, state)
    end
end

"""
The inverse function of the Cantor enumeration (the pairing function), computes n for given (x, y) and returns (x + y)*(x + y + 1)/2 + p where p = x if x - y is odd and y otherwise.
"""
function CantorPairing(x, y)
    p = isodd(x - y) ? x : y
    div((x + y) * (x + y + 1), 2) + p
end

# -----------------------------------------------

"""
The boustrophedonic Cantor enumeration implemented as a state machine to avoid the evaluation of the square root function.
"""
function CantorBoustrophedonicMachine(x, y)
    x == 0 && return y >> 1 + 1, y - y >> 1
    x > y && return y, x
    return y + 1, x - 1
end

"""
# The boustrophedonic Cantor enumeration of N X N where N = {0, 1, 2, ...}. If (x, y) and (x', y') are adjacent points on the trajectory of the map then max(|x - x'|, |y - y'|) is always 1 whereas for the Cantor enumeration this quantity can become arbitrarily large. In this sense the boustrophedonic variant is continuous whereas Cantor's realization is not.
"""
function CantorBoustrophedonicEnumeration(len)
    x, y = 0, 0
    for n in 0:len
        # println("$n -> ($x, $y)")
        print("$x, $y, ")
        x, y = CantorBoustrophedonicMachine(x, y)
    end
end

"""
The inverse function of the boustrophedonic Cantor enumeration (the pairing function), computes n for given (x, y) and returns (x + y)*(x + y + 1)/2 + m where m = abs(x - y) - (x > y ? 1 : 0).
"""
function CantorBoustrophedonicPairing(x, y)
    m = abs(x - y) - (x > y ? 1 : 0)
    div((x + y) * (x + y + 1), 2) + m
end

# -----------------------------------------------

"""
The boustrophedonic Rosenberg-Strong enumeration as considered by Pigeon implemented as a state machine to avoid the evaluation of the square root function.
"""
function RosenbergStrongBoustrophedonicMachine(x, y, state)
    x == 0 && state == 0 && return x, y + 1, 1
    y == 0 && state == 2 && return x + 1, y, 3
    x == y && state == 1 && return x, y - 1, 2
    x == y && return x - 1, y, 0
    state == 0 && return x - 1, y, 0
    state == 1 && return x + 1, y, 1
    state == 2 && return x, y - 1, 2
    return x, y + 1, 3
end

"""
The boustrophedonic Rosenberg-Strong enumeration of N X N where N = {0, 1, 2, ...}. If (x, y) and (x', y') are adjacent points on the trajectory of the map then max(|x - x'|, |y - y'|) is always 1 whereas the Rosenberg-Strong realization is not.
"""
function RosenbergStrongBoustrophedonicEnumeration(len)
    x, y, state = 0, 0, 0
    for n in 0:len
        #println("$n -> ($x, $y)")
        print("$x, $y, ")
        x, y, state = RosenbergStrongBoustrophedonicMachine(x, y, state)
    end
end

"""
The inverse function of the boustrophedonic Rosenberg-Strong enumeration (the pairing function), computes n for given (x, y).
"""
function RosenbergStrongBoustrophedonicPairing(x::Int, y::Int)
    m = max(x, y)
    d = isodd(m) ? x - y : y - x
    m * (m + 1) + d
end

"""
Return the pair (x, y) for given n as given by the boustrophedonic Rosenberg-Strong enumeration.
"""
function V319514(n)
    k, r = divrem(n, 2)
    m = x = isqrt(k)
    y = k - x^2
    x <= y && ((x, y) = (2x - y, x))
    isodd(m) ? (y, x)[r + 1] : (x, y)[r + 1]
end

"""
Return a list of pairs (x, y) given by the boustrophedonic Rosenberg-Strong enumeration.
"""
L319514(len) = [V319514(n) for n in 0:len-1]


#START-TEST-########################################################

using Test

function test()

    @testset "CantorMachines" begin

        len = 64

        # CantorTest

        println(); println("CantorMachine")

        x, y, state = 0, 0, false
        for n in 0:len
            p = CantorPairing(x, y)
            #println("$n -> ($x, $y) -> $p")
            @test n == p
            x, y, state = CantorMachine(x, y, state)
        end

        # CantorBoustrophedonicTest

        println(); println("CantorBoustrophedonicMachine")

        x, y = 0, 0
        for n in 0:len
            p = CantorBoustrophedonicPairing(x, y)
            println("$n -> ($x, $y) -> $p")
            @test n == p
            x, y = CantorBoustrophedonicMachine(x, y)
        end

        # RosenbergStrongBoustrophedonicTest

        println(); println("RosenbergStrongBoustrophedonicMachine")

        x, y, state = 0, 0, 0
        for n in 0:len
            p = RosenbergStrongBoustrophedonicPairing(x, y)
            #println("$n -> ($x, $y) -> $p")
            @test n == p
            x, y, state = RosenbergStrongBoustrophedonicMachine(x, y, state)
        end

        println()
    end
end

function demo()

    println();
    println("CantorEnumeration")
    CantorEnumeration(20)

    println(); println();
    println("CantorBoustrophedonicEnumeration")
    CantorBoustrophedonicEnumeration(20)

    println(); println();
    println("RosenbergStrongBoustrophedonicEnumeration")
    RosenbergStrongBoustrophedonicEnumeration(20)

    println(); println();
    println("L319514")
    L319514(42) |> println
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
