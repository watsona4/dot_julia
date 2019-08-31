using AdjacentFloats
using Test

@testset "AdjacentFloats" begin

    for (f, g) in ( (prev_float, prevfloat),
                    (next_float, nextfloat) )

        @testset "Tests for $f" begin

            for x in (1.0, 3.0, sqrt(2.0), sqrt(0.25),
                      1e-10, 1e10, 1e300, 1e-300, Inf)

                @test f(x) == g(x)
                @test f(-x) == g(-x)
            end
        end
    end

    @testset "NaN" begin
        @test isnan(prev_float(NaN))
        @test isnan(next_float(NaN))
    end
end
