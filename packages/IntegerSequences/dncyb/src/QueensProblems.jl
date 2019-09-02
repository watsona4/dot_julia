# This file is part of IntegerSequences.
# Copyright Peter Luschny. License is MIT.

(@__DIR__) ∉ LOAD_PATH && push!(LOAD_PATH, (@__DIR__))

module QueensProblems

export ModuleQueensProblems
export L319284, Queens

"""
For some background see: [Backtracking with profiles](https://wp.me/paipV7-E).

* Queens, L319284
"""
const ModuleQueensProblems = ""

function solve!(profile, level, size, start, cols, diag4, diag1)

    if level > 0
        for i in start:size
            save = cols & (1 << i) +
            diag1 & (1 << (i + level)) +
            diag4 & (1 << (32 + i - level))

            if save == 0

                cols  = xor(cols,  1 << i)
                diag1 = xor(diag1, 1 << (i + level))
                diag4 = xor(diag4, 1 << (32 + i - level))

                solve!(profile, level - 1, size, 0, cols, diag4, diag1)

                cols  = xor(cols,  1 << i)
                diag1 = xor(diag1, 1 << (i + level))
                diag4 = xor(diag4, 1 << (32 + i - level))

                profile[level + 1] += 1
            end
        end
    else
        for i in 0:size
            save = cols & (1<<i) + diag1 & (1<<i) + diag4 & (1<<(32+i))
            save == 0 && (profile[1] += 1)
        end
    end
end

function search(n::Int)
    profile = zeros(Int, n + 1)
    cols = diag4 = diag1 = Int(0)
    solve!(profile, n - 1, n - 1, 0, cols, diag4, diag1)
    return profile
end

"""
Returns the profile of the backtrack tree for the n queens problem (see `A319284`).
"""
function Queens(n::Int)
    n == 0 && return [1]
    profile = search(n)
    profile[n+1] = 1  # add the root
    [profile[n-i+1] for i = 0:n]
end

"""
Returns the profile of the backtrack tree for the n queens problem.
"""
L319284(n) = Queens(n)

#START-TEST-########################################################

using Test

function test()
    @testset "QueensProblem" begin
        levels = [1, 10, 72, 364, 1400, 3916, 7552, 9632, 7828, 4040, 724]
        @test all(L319284(10) .== levels)
    end
end

function demo()

    up_to = 10
    for n in 0:up_to
        print("elapsed: ")
        @time profile = Queens(n)
        println("size:      ", n)
        println("profile:   ", profile)
        println("nodes:     ", sum(profile))
        println("solutions: ", profile[n+1])
        println()
    end
end

"""
L319284(15)
    18.731622 seconds (4 allocations: 480 bytes)
"""
function perf()
    @time L319284(15)
end

function main()
    test()
    demo()
    #perf()
end

main()

end # module
