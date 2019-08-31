using ConsistencyResampling, Bootstrap
using Random

using ConsistencyResampling: bootstrap_direct, bootstrap_alias

Random.seed!(1234)

@testset "Simple example" begin
    predictions = reshape([1, 0], 2, 1)
    labels = [2]

    for f in (bootstrap, bootstrap_direct, bootstrap_alias)
        b = bootstrap(last, (predictions, labels), ConsistentSampling(20))

        @test data(b) == (predictions, labels)
        @test original(b) == (2,)
        @test straps(b) == (ones(Int, 20),)
    end
end
