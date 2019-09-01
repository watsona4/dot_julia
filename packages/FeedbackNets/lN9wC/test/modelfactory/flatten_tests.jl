@testset "flatten" begin
    # a 2D array should stay the same
    arr2D = rand(5, 10)
    @test flatten(arr2D) == arr2D
    # a 4D array should be reshaped to 2D
    arr4D = rand(3, 4, 5, 2)
    flat = flatten(arr4D)
    @test ndims(flat) == 2
    @test length(flat) == length(arr4D)
    @test flat[:, 1] == vec(arr4D[:, :, :, 1])
    @test flat[:, 2] == vec(arr4D[:, :, :, 2])
end # @testset "flatten"
