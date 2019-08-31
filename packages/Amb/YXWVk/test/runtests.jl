using Amb
using Test

@testset "Pythagorean triples" begin
    intbetween(lo, hi) = (require(lo <= hi); @amb lo intbetween(lo+1, hi))

    function triple(lo, hi)
        i = intbetween(lo, hi)
        j = intbetween(i, hi)
        k = intbetween(j, hi)
        require(i*i + j*j == k*k)
        (i, j, k)
    end
    @test collect(ambiter(()->triple(1,20))) == [(3, 4, 5), (5, 12, 13),
                                                 (6, 8, 10), (8, 15, 17),
                                                 (9, 12, 15), (12, 16, 20)]
end
