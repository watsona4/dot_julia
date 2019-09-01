using DeepDish
using Test

data = load_deepdish("test.h5")

@testset begin
    # Simple data types
    @test data["bool"] == false
    @test data["int"] == 1

    # Arrays
    @test all(data["arr"] .== reshape(0:3, 2, 2))

    # Nesting
    @test data["nested"][1]["inside"] == "nested"

    # DataFrames
    @test all(data["df"][:a] .== collect(0:3))
end