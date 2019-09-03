using Struve
using Test

# using Table 2 and 3 from
# https://doi.org/10.1016/S0377-0427(01)00580-5
const h0_zeros = [
     4.3332378204,
     6.7810276399,
    10.4692052391,
    13.1404947133,
    16.6967131984,
    19.4599412437,
    22.9490276305,
    25.7653652428,
    29.2120126148,
    32.0639726967,
    # skipping 9 zeros here
    63.5189617208
]

@testset "H0 zeros" begin
    for z in h0_zeros
        @test abs(Struve.H0(z)) < 1e-10
    end
    @test !(abs(Struve.H0( 2.0)) < 1e-10)
    @test !(abs(Struve.H0(22.0)) < 1e-10)
    for z in h0_zeros
        @test abs(Struve.H(0, z)) < 1e-10
    end
    @test !(abs(Struve.H(0,  2.0)) < 1e-10)
    @test !(abs(Struve.H(0, 22.0)) < 1e-10)
    for z in h0_zeros
        @test abs(Struve.H0(z + 0im)) < 1e-10
    end
    @test !(abs(Struve.H0( 2.0 + 0im)) < 1e-10)
    @test !(abs(Struve.H0(22.0 + 0im)) < 1e-10)
    for z in h0_zeros
        @test_broken abs(Struve.H(0, z + 0im)) < 1e-10
    end
    @test !(abs(Struve.H(0,  2.0 + 0im)) < 1e-10)
    @test !(abs(Struve.H(0, 22.0 + 0im)) < 1e-10)
end
