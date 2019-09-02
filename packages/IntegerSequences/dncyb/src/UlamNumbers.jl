# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module UlamNumbers

export ModuleUlamNumbers
export L002858, UlamList, isUlam

"""
An Ulam number u(n) is the least number > u(n-1) which is a unique sum of two distinct earlier terms; u(1) = 1 and u(2) = 2.

* UlamList, isUlam, L002858
"""
const ModuleUlamNumbers = ""

"""
Is ``n`` an Ulam number?
"""
function isUlam(u, n, h, i, r)
    ur = u[r]; ui = u[i]
    ur <= ui && return h
    if ur + ui > n
        r -= 1
    elseif ur + ui < n
        i += 1
    else
        h && return false
        h = true; i += 1; r -= 1
    end
    isUlam(u, n, h, i, r)
end

"""
Return a list of Ulam numbers. An Ulam number u(n) is the least number > u(n-1) which is a unique sum of two distinct earlier terms; u(1) = 1 and u(2) = 2.
"""
function UlamList(len)
    u = Array{Int, 1}(undef, len)
    u[1] = 1; u[2] = 2
    i = 2; n = 2

    while i < len
        n += 1
        if isUlam(u, n, false, 1, i)
            i += 1
            u[i] = n
        end
    end

    return u
end

"""
Return a list of Ulam numbers.
"""
L002858(len) = UlamList(len)

#START-TEST-########################################################

using Test

function test(oeis_isinstalled=false)
    @testset "UlamNumbers" begin
    @test UlamList(6)[end] == 8
    end
end

# 1, 2, 3, 4, 6, 8, 11, 13, 16, 18, 26, 28, 36, 38, 47, 48, 53,
# 57, 62, 69, 72, 77, 82, 87, 97, 99, 102, 106, 114, 126, 131,
# 138, 145, 148, 155, 175, 177, 180, 182, 189, 197, 206, 209,
# 219, 221, 236, 238, 241, 243, 253, 258, 260, 273, 282, 309,
# 316, 319, 324, 339
function demo()
    UlamList(59) |> println
end

"""
0.000061 seconds (1 allocation: 624 bytes)
0.000296 seconds (1 allocation: 1.141 KiB)
0.001216 seconds (1 allocation: 2.125 KiB)
0.005786 seconds (1 allocation: 4.125 KiB)
0.018729 seconds (1 allocation: 8.125 KiB)
"""
function perf()
    GC.gc()
    for n in 6:10
        @time UlamList(2^n)
    end
end

function main()
    test()
    demo()
    perf()
end

main()

end # module
