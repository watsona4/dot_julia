using Test
using MotifSequenceGenerator

@testset "possiblesums" begin
    a = [1,1,3,4]
    mina = minimum(a); maxa = maximum(a)
    for n in 1:3
        allsum = all_possible_sums(a, n)
        m = length(a)
        for i in 1:binomial(m + n - 1, n)
            @test mina*n ≤ allsum[i][1] ≤ maxa*n
        end
    end
end

include("integer_length_tests.jl")
include("float_length_tests.jl")
