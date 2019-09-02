module MangalTestDataset
    using Mangal
    using Test
    include("setup.jl")

    # Datasets with no arguments
    @test typeof(datasets()) <: Vector{MangalDataset}

    # Datasets with count
    count_2 = datasets(Pair("count", 2))
    @test typeof(count_2) <: Vector{MangalDataset}
    @test length(count_2) == 2

    # Dataset by id
    @test typeof(dataset(1)) <: MangalDataset

    # Dataset by name
    @test typeof(dataset("roberson_1929")) <: MangalDataset

end
