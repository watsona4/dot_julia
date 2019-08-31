using OceanGrids, Test, Unitful

@testset "Small grid tests" begin
    nlat, nlon, ndepth = 2, 3, 4
    grid = OceanGrid(nlat, nlon, ndepth)
    @test grid isa OceanRectilinearGrid
    @test grid isa OceanGrid
    @test size(grid) == (nlat, nlon, ndepth)
    @test length(grid) == *(nlat, nlon, ndepth)
    @testset "OceanGridBox" for box in grid
        @test box isa OceanGridBox
        show(box)
        @test OceanGrids.area(box) isa Quantity
        @test unit(OceanGrids.area(box)) == u"km^2"
        @test unit(OceanGrids.volume(box)) == u"m^3"
    end
end

@testset "edges to grid" begin
    elat = -90:90:90
    elats = [-90:90:90,
             -90.0:90.0:90.0,
             [-90,0,90],
             [-90.0,0.0,90.0],
             (-90.0:90.0:90.0) * u"°",
             [-90.0,0.0,90.0] * u"°",
             (-90:90:90) * u"°",
             [-90,0,90] * u"°",]
    elons = [-180:90:180,
             [-180,-90,0,90,180],
             (-180:90:180) * u"°",
             [-180,-90,0,90,180] * u"°"]
    edepths = [[0, 100, 200, 500, 1000, 3000] * u"m",
               [0.0, 100.0, 200.0, 500.0, 1000.0, 3000.0] * u"m",
               [0.0, 100.0, 200.0, 500.0, 1000.0, 3000.0],
               [0, 100, 200, 500, 1000, 3000],
               [0, 0.1, 0.2, 0.5, 1, 3] * u"km"]
    base_grid = OceanGrid(elats[1], elons[1], edepths[1])
    @testset "types of edges" for elat in elats, elon in elons, edepth in edepths
        grid = OceanGrid(elat,elon,edepth)
        @test grid isa OceanRectilinearGrid
        @test grid isa OceanGrid
        @test grid == base_grid
        show(grid)
        @testset "OceanGridBox" for box in grid
            @test box isa OceanGridBox
        end
    end
end
