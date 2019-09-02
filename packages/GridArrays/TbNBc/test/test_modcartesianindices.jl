using GridArrays, Test
using GridArrays: ModCartesianIndices

@testset "ModCartesianIndices" begin
    modcart = ModCartesianIndices((30,40,50),10:20,10:30,10:40);
    cart = modcart.iter
    t1 = @timed(for i in cart
        i ∈ modcart
    end)[3]
    t2 = @timed(for i in cart
        i ∈ cart
    end)[3]

    t1 = @timed(for i in cart
        i ∈ modcart
    end)[3]
    t2 = @timed(for i in cart
        i ∈ cart
    end)[3]

    @test t1 == t2

    for i in modcart
        @test i ∈ cart
    end


    modcart = ModCartesianIndices((30,40,50),CartesianIndex(1,1,1),CartesianIndex(30,40,50));
    cart = modcart.iter

    @test modcart == cart
end

@testset "ModUnitRange" begin
    modcart = GridArrays.ModCartesianIndicesBase.ModUnitRange(20,-3:3)
    cart = modcart.iter
    t1 = @timed(for i in cart
        i ∈ modcart
    end)[3]
    t2 = @timed(for i in cart
        i ∈ cart
    end)[3]

    t1 = @timed(for i in cart
        i ∈ modcart
    end)[3]
    t2 = @timed(for i in cart
        i ∈ cart
    end)[3]

    @test t1 == t2

    for i in cart
        @test i ∈ modcart
    end

    j = 0
    for i in modcart
        j+= 1
    end
    @test j==length(modcart)

    @test first(modcart) == 17
    @test last(modcart) == 3
end

@testset "boundary" begin
    g = PeriodicEquispacedGrid(11,-2,2)^2
    d = UnitDisk()
    b = GridArrays.boundary(g,d)
    for bi in b
        @test approx_in(bi, UnitCircle(),1e-10)
    end

    g = PeriodicEquispacedGrid(11,-2,2)^2
    d = UnitDisk()
    b = GridArrays.boundary_grid(g,d)
    @test subindices(b) == CartesianIndex{2}[CartesianIndex(6, 4), CartesianIndex(7, 4), CartesianIndex(5, 5),
    CartesianIndex(6, 5), CartesianIndex(7, 5), CartesianIndex(8, 5), CartesianIndex(4, 6),
    CartesianIndex(5, 6), CartesianIndex(8, 6), CartesianIndex(9, 6), CartesianIndex(4, 7),
    CartesianIndex(5, 7), CartesianIndex(8, 7), CartesianIndex(9, 7), CartesianIndex(5, 8),
    CartesianIndex(6, 8), CartesianIndex(7, 8), CartesianIndex(8, 8), CartesianIndex(6, 9),
    CartesianIndex(7, 9)]
end
