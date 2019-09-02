module MangalTestNetwork
    using Mangal
    using Test
    include("setup.jl")

    # Nodes of a network
    N1 = network(19)
    nN1 = nodes(N1)
    @test typeof(nN1) <: Vector{MangalNode}

    # Datasets with no arguments
    @test typeof(networks()) <: Vector{MangalNetwork}

    # Networks by id
    @test typeof(network(19)) <: MangalNetwork

    # Network by name
    @test typeof(network("howking_1968_19680601_12")) <: MangalNetwork

    # Networks by dataset
    ds = dataset(62) # Olesen
    n_ds = networks(ds)
    @test typeof(n_ds) <: Vector{MangalNetwork}
    n_ds_q = networks(ds, Pair("count", 2))
    @test typeof(n_ds_q) <: Vector{MangalNetwork}
    @test length(n_ds_q) == 2

    # Wrap multiple calls
    this_page = 1
    networks_ponisio = networks(dataset("ponisio_2017"), Pair("count", 10), Pair("page", this_page))
    keep_querying = true
    while keep_querying
        global this_page += 1
        response = networks(dataset("ponisio_2017"), Pair("count", 10), Pair("page", this_page))
        append!(networks_ponisio, response)
        global keep_querying = length(response) > 0
    end
    @test length(networks_ponisio) == 131

end
