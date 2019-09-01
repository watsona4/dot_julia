#!/usr/bin/env julia
using Test
import Granular

# Check the grid interpolation and sorting functions
verbose = false

if Granular.hasNetCDF
    ocean = Granular.readOceanNetCDF("Baltic/00010101.ocean_month.nc",
                                   "Baltic/ocean_hgrid.nc")

    @info "Testing coordinate retrieval functions"
    sw, se, ne, nw = Granular.getCellCornerCoordinates(ocean.xq, ocean.yq, 1, 1)
    @test sw ≈ [6., 53.]
    @test se ≈ [7., 53.]
    @test ne ≈ [7., 54.]
    @test nw ≈ [6., 54.]
    @test Granular.getCellCenterCoordinates(ocean.xh, ocean.yh, 1, 1) ≈ [6.5, 53.5]

    @info "Testing area-determination methods"
    @test Granular.areaOfTriangle([0., 0.], [1., 0.], [0., 1.]) ≈ .5
    @test Granular.areaOfTriangle([1., 0.], [0., 1.], [0., 0.]) ≈ .5
    @test Granular.areaOfQuadrilateral([1., 0.], [0., 1.], [0., 0.], [1., 1.]) ≈ 1.

    @info "Testing area-based cell content determination"
    @test Granular.isPointInCell(ocean, 1, 1, [6.5, 53.5], sw, se, ne, nw) == true
    @test Granular.isPointInCell(ocean, 1, 1, [6.5, 53.5]) == true
    @test Granular.getNonDimensionalCellCoordinates(ocean, 1, 1, [6.5, 53.5]) ≈
        [.5, .5]
    @test Granular.isPointInCell(ocean, 1, 1, [6.1, 53.5], sw, se, ne, nw) == true
    @test Granular.getNonDimensionalCellCoordinates(ocean, 1, 1, [6.1, 53.5]) ≈
        [.1, .5]
    @test Granular.isPointInCell(ocean, 1, 1, [6.0, 53.5], sw, se, ne, nw) == true
    @test Granular.getNonDimensionalCellCoordinates(ocean, 1, 1, [6.0, 53.5]) ≈
        [.0, .5]
    @test Granular.isPointInCell(ocean, 1, 1, [6.1, 53.7], sw, se, ne, nw) == true
    @test Granular.isPointInCell(ocean, 1, 1, [6.1, 53.9], sw, se, ne, nw) == true
    @test Granular.isPointInCell(ocean, 1, 1, [6.1, 53.99999], sw, se, ne, nw) == true
    @test Granular.getNonDimensionalCellCoordinates(ocean, 1, 1, [6.1, 53.99999]) ≈
        [.1, .99999]
    @test Granular.isPointInCell(ocean, 1, 1, [7.5, 53.5], sw, se, ne, nw) == false
    @test Granular.isPointInCell(ocean, 1, 1, [0.0, 53.5], sw, se, ne, nw) == false
    x_tilde, _ = Granular.getNonDimensionalCellCoordinates(ocean, 1, 1, [0., 53.5])
    @test x_tilde < 0.

    @info "Testing conformal mapping methods"
    @test Granular.conformalQuadrilateralCoordinates([0., 0.],
                                                   [5., 0.],
                                                   [5., 3.],
                                                   [0., 3.],
                                                   [2.5, 1.5]) ≈ [0.5, 0.5]
    @test Granular.conformalQuadrilateralCoordinates([0., 0.],
                                                   [5., 0.],
                                                   [5., 3.],
                                                   [0., 3.],
                                                   [7.5, 1.5]) ≈ [1.5, 0.5]
    @test Granular.conformalQuadrilateralCoordinates([0., 0.],
                                                   [5., 0.],
                                                   [5., 3.],
                                                   [0., 3.],
                                                   [7.5,-1.5]) ≈ [1.5,-0.5]
    @test_throws ErrorException Granular.conformalQuadrilateralCoordinates([0., 0.],
                                                                         [5., 3.],
                                                                         [0., 3.],
                                                                         [5., 0.],
                                                                         [7.5,-1.5])

    @info "Checking cell content using conformal mapping methods"
    @test Granular.isPointInCell(ocean, 1, 1, [6.4, 53.4], sw, se, ne, nw, 
                               method="Conformal") == true
    @test Granular.isPointInCell(ocean, 1, 1, [6.1, 53.5], sw, se, ne, nw, 
                               method="Conformal") == true
    @test Granular.isPointInCell(ocean, 1, 1, [6.0, 53.5], sw, se, ne, nw, 
                               method="Conformal") == true
    @test Granular.isPointInCell(ocean, 1, 1, [6.1, 53.7], sw, se, ne, nw, 
                               method="Conformal") == true
    @test Granular.isPointInCell(ocean, 1, 1, [6.1, 53.9], sw, se, ne, nw, 
                               method="Conformal") == true
    @test Granular.isPointInCell(ocean, 1, 1, [6.1, 53.99999], sw, se, ne, nw,
                               method="Conformal") == true
    @test Granular.isPointInCell(ocean, 1, 1, [7.5, 53.5], sw, se, ne, nw,
                               method="Conformal") == false
    @test Granular.isPointInCell(ocean, 1, 1, [0.0, 53.5], sw, se, ne, nw,
                               method="Conformal") == false

    @info "Testing bilinear interpolation scheme on conformal mapping"
    ocean.u[1, 1, 1, 1] = 1.0
    ocean.u[2, 1, 1, 1] = 1.0
    ocean.u[2, 2, 1, 1] = 0.0
    ocean.u[1, 2, 1, 1] = 0.0
    val = [NaN, NaN]
    Granular.bilinearInterpolation!(val, ocean.u[:,:,1,1], ocean.u[:,:,1,1],
                                  .5, .5, 1, 1)
    @time Granular.bilinearInterpolation!(val, ocean.u[:,:,1,1], ocean.u[:,:,1,1], .5, 
                                  .5, 1, 1)
    @test val[1] ≈ .5
    @test val[2] ≈ .5
    Granular.bilinearInterpolation!(val, ocean.u[:,:,1,1], ocean.u[:,:,1,1], 1., 1., 
    1, 1)
    @test val[1] ≈ .0
    @test val[2] ≈ .0
    Granular.bilinearInterpolation!(val, ocean.u[:,:,1,1], ocean.u[:,:,1,1], 0., 0., 
    1, 1)
    @test val[1] ≈ 1.
    @test val[2] ≈ 1.
    Granular.bilinearInterpolation!(val, ocean.u[:,:,1,1], ocean.u[:,:,1,1], .25, .25, 
    1, 1)
    @test val[1] ≈ .75
    @test val[2] ≈ .75
    Granular.bilinearInterpolation!(val, ocean.u[:,:,1,1], ocean.u[:,:,1,1], .75, .75, 
    1, 1)
    @test val[1] ≈ .25
    @test val[2] ≈ .25

    @info "Testing cell binning - Area-based approach"
    @test Granular.findCellContainingPoint(ocean, [6.2,53.4], method="Area") == (1, 1)
    @test Granular.findCellContainingPoint(ocean, [7.2,53.4], method="Area") == (2, 1)
    @test Granular.findCellContainingPoint(ocean, [0.2,53.4], method="Area") == (0, 0)

    @info "Testing cell binning - Conformal mapping"
    @test Granular.findCellContainingPoint(ocean, [6.2,53.4], method="Conformal") == 
        (1, 1)
    @test Granular.findCellContainingPoint(ocean, [7.2,53.4], method="Conformal") == 
        (2, 1)
    @test Granular.findCellContainingPoint(ocean, [0.2, 53.4], method="Conformal") ==
        (0, 0)

    sim = Granular.createSimulation()
    sim.ocean = Granular.readOceanNetCDF("Baltic/00010101.ocean_month.nc",
                                       "Baltic/ocean_hgrid.nc")
    Granular.addGrainCylindrical!(sim, [6.5, 53.5], 10., 1., verbose=verbose)
    Granular.addGrainCylindrical!(sim, [6.6, 53.5], 10., 1., verbose=verbose)
    Granular.addGrainCylindrical!(sim, [7.5, 53.5], 10., 1., verbose=verbose)
    Granular.sortGrainsInGrid!(sim, sim.ocean, verbose=verbose)
    @test sim.grains[1].ocean_grid_pos == [1, 1]
    @test sim.grains[2].ocean_grid_pos == [1, 1]
    @test sim.grains[3].ocean_grid_pos == [2, 1]
    @test sim.ocean.grain_list[1, 1] == [1, 2]
    @test sim.ocean.grain_list[2, 1] == [3]
end

@info "Testing ocean drag"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([4, 4, 2], [4., 4., 2.])
sim.ocean.u[:,:,1,1] .= 5.
Granular.addGrainCylindrical!(sim, [2.5, 3.5], 1., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [2.6, 2.5], 1., 1., verbose=verbose)
Granular.sortGrainsInGrid!(sim, sim.ocean, verbose=verbose)
if !Granular.hasNetCDF
    ocean = sim.ocean
end
sim.time = ocean.time[1]
Granular.addOceanDrag!(sim)
@test sim.grains[1].force[1] > 0.
@test sim.grains[1].force[2] ≈ 0.
@test sim.grains[2].force[1] > 0.
@test sim.grains[2].force[2] ≈ 0.
sim.ocean.u[:,:,1,1] .= -5.
sim.ocean.v[:,:,1,1] .= 5.
Granular.addGrainCylindrical!(sim, [2.5, 3.5], 1., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [2.6, 2.5], 1., 1., verbose=verbose)
Granular.sortGrainsInGrid!(sim, sim.ocean, verbose=verbose)
sim.time = ocean.time[1]
Granular.addOceanDrag!(sim)
@test sim.grains[1].force[1] < 0.
@test sim.grains[1].force[2] > 0.
@test sim.grains[2].force[1] < 0.
@test sim.grains[2].force[2] > 0.

@info "Testing curl function"
ocean.u[1, 1, 1, 1] = 1.0
ocean.u[2, 1, 1, 1] = 1.0
ocean.u[2, 2, 1, 1] = 0.0
ocean.u[1, 2, 1, 1] = 0.0
ocean.v[:, :, 1, 1] .= 0.0
sw = zeros(2)
se = zeros(2)
ne = zeros(2)
nw = zeros(2)
@test Granular.curl(ocean, .5, .5, 1, 1, 1, 1, sw, se, ne, nw) > 0.

ocean.u[1, 1, 1, 1] = 0.0
ocean.u[2, 1, 1, 1] = 0.0
ocean.u[2, 2, 1, 1] = 1.0
ocean.u[1, 2, 1, 1] = 1.0
ocean.v[:, :, 1, 1] .= 0.0
@test Granular.curl(ocean, .5, .5, 1, 1, 1, 1, sw, se, ne, nw) < 0.

@info "Testing atmosphere drag"
sim = Granular.createSimulation()
sim.atmosphere = Granular.createRegularAtmosphereGrid([4, 4, 2], [4., 4., 2.])
atmosphere = Granular.createRegularAtmosphereGrid([4, 4, 2], [4., 4., 2.])
sim.atmosphere.u[:,:,1,1] .= 5.
Granular.addGrainCylindrical!(sim, [2.5, 3.5], 1., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [2.6, 2.5], 1., 1., verbose=verbose)
Granular.sortGrainsInGrid!(sim, sim.atmosphere, verbose=verbose)
sim.time = ocean.time[1]
Granular.addAtmosphereDrag!(sim)
@test sim.grains[1].force[1] > 0.
@test sim.grains[1].force[2] ≈ 0.
@test sim.grains[2].force[1] > 0.
@test sim.grains[2].force[2] ≈ 0.
sim.atmosphere.u[:,:,1,1] .= -5.
sim.atmosphere.v[:,:,1,1] .= 5.
Granular.addGrainCylindrical!(sim, [2.5, 3.5], 1., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [2.6, 2.5], 1., 1., verbose=verbose)
Granular.sortGrainsInGrid!(sim, sim.atmosphere, verbose=verbose)
sim.time = ocean.time[1]
Granular.addAtmosphereDrag!(sim)
@test sim.grains[1].force[1] < 0.
@test sim.grains[1].force[2] > 0.
@test sim.grains[2].force[1] < 0.
@test sim.grains[2].force[2] > 0.

@info "Testing curl function"
atmosphere.u[1, 1, 1, 1] = 1.0
atmosphere.u[2, 1, 1, 1] = 1.0
atmosphere.u[2, 2, 1, 1] = 0.0
atmosphere.u[1, 2, 1, 1] = 0.0
atmosphere.v[:, :, 1, 1] .= 0.0
@test Granular.curl(atmosphere, .5, .5, 1, 1, 1, 1) > 0.
@test Granular.curl(atmosphere, .5, .5, 1, 1, 1, 1, sw, se, ne, nw) > 0.

atmosphere.u[1, 1, 1, 1] = 0.0
atmosphere.u[2, 1, 1, 1] = 0.0
atmosphere.u[2, 2, 1, 1] = 1.0
atmosphere.u[1, 2, 1, 1] = 1.0
atmosphere.v[:, :, 1, 1] .= 0.0
@test Granular.curl(atmosphere, .5, .5, 1, 1, 1, 1) < 0.
@test Granular.curl(atmosphere, .5, .5, 1, 1, 1, 1, sw, se, ne, nw) < 0.


@info "Testing findEmptyPositionInGridCell"
@info "# Insert into empty cell"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([4, 4, 2], [4., 4., 2.])
Granular.sortGrainsInGrid!(sim, sim.ocean, verbose=verbose)
pos = Granular.findEmptyPositionInGridCell(sim, sim.ocean, 1, 1, 0.5, 
                                         verbose=true)
@test pos != false
@test Granular.isPointInCell(sim.ocean, 1, 1, pos) == true

@info "# Insert into cell with one other ice floe"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([4, 4, 2], [4., 4., 2.])
Granular.addGrainCylindrical!(sim, [.25, .25], .25, 1., verbose=verbose)
Granular.sortGrainsInGrid!(sim, sim.ocean, verbose=verbose)
pos = Granular.findEmptyPositionInGridCell(sim, sim.ocean, 1, 1, .25, 
                                         verbose=true)
@test pos != false
@test Granular.isPointInCell(sim.ocean, 1, 1, pos) == true

@info "# Insert into cell with two other grains"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([4, 4, 2], [4., 4., 2.])
Granular.addGrainCylindrical!(sim, [.25, .25], .25, 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [.75, .75], .25, 1., verbose=verbose)
Granular.sortGrainsInGrid!(sim, sim.ocean, verbose=verbose)
pos = Granular.findEmptyPositionInGridCell(sim, sim.ocean, 1, 1, .25, n_iter=30,
                                           verbose=true)
@test pos != false
@test Granular.isPointInCell(sim.ocean, 1, 1, pos) == true

@info "# Insert into full cell"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([4, 4, 2], [4., 4., 2.])
Granular.addGrainCylindrical!(sim, [.25, .25], 1., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [.75, .25], 1., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [.25, .75], 1., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [.75, .75], 1., 1., verbose=verbose)
Granular.sortGrainsInGrid!(sim, sim.ocean, verbose=verbose)
pos = Granular.findEmptyPositionInGridCell(sim, sim.ocean, 1, 1, 0.5,
                                         verbose=false)
@test pos == false

@info "# Insert into empty cell"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([4, 4, 2], [4., 4., 2.])
Granular.sortGrainsInGrid!(sim, sim.ocean, verbose=verbose)
pos = Granular.findEmptyPositionInGridCell(sim, sim.ocean, 2, 2, 0.5, 
                                         verbose=true)
@test pos != false
@test Granular.isPointInCell(sim.ocean, 2, 2, pos) == true

@info "# Insert into full cell"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([4, 4, 2], [4., 4., 2.])
Granular.addGrainCylindrical!(sim, [1.5, 1.5], 1., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [1.75, 1.5], 1., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [1.5, 1.75], 1., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [1.75, 1.75], 1., 1., verbose=verbose)
Granular.sortGrainsInGrid!(sim, sim.ocean, verbose=verbose)
pos = Granular.findEmptyPositionInGridCell(sim, sim.ocean, 2, 2, 0.5,
                                         verbose=false)
@test pos == false

@info "Test default sorting with ocean/atmosphere grids"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([4, 4, 2], [4., 4., 2.])
sim.atmosphere = Granular.createRegularAtmosphereGrid([4, 4, 2], [4., 4.000001, 2.])
Granular.addGrainCylindrical!(sim, [0.5, 0.5], .1, 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [0.7, 0.7], .1, 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [2.6, 2.5], .1, 1., verbose=verbose)
Granular.sortGrainsInGrid!(sim, sim.ocean, verbose=verbose)
Granular.setTimeStep!(sim)
Granular.setTotalTime!(sim, 1.0)
Granular.run!(sim, single_step=true, verbose=verbose)
@test sim.atmosphere.collocated_with_ocean_grid == false
@test sim.grains[1].ocean_grid_pos == [1, 1]
@test sim.grains[2].ocean_grid_pos == [1, 1]
@test sim.grains[3].ocean_grid_pos == [3, 3]
@test sim.ocean.grain_list[1, 1] == [1, 2]
@test sim.ocean.grain_list[2, 2] == []
@test sim.ocean.grain_list[3, 3] == [3]
@test sim.grains[1].atmosphere_grid_pos == [1, 1]
@test sim.grains[2].atmosphere_grid_pos == [1, 1]
@test sim.grains[3].atmosphere_grid_pos == [3, 3]
@test sim.atmosphere.grain_list[1, 1] == [1, 2]
@test sim.atmosphere.grain_list[2, 2] == []
@test sim.atmosphere.grain_list[3, 3] == [3]

@info "Test optimization when ocean/atmosphere grids are collocated"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([4, 4, 2], [4., 4., 2.])
sim.atmosphere = Granular.createRegularAtmosphereGrid([4, 4, 2], [4., 4., 2.])
Granular.addGrainCylindrical!(sim, [0.5, 0.5], .1, 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [0.7, 0.7], .1, 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [2.6, 2.5], .1, 1., verbose=verbose)
Granular.sortGrainsInGrid!(sim, sim.ocean, verbose=verbose)
Granular.setTimeStep!(sim)
Granular.setTotalTime!(sim, 1.0)
Granular.run!(sim, single_step=true, verbose=false)
@test sim.atmosphere.collocated_with_ocean_grid == true
@test sim.grains[1].ocean_grid_pos == [1, 1]
@test sim.grains[2].ocean_grid_pos == [1, 1]
@test sim.grains[3].ocean_grid_pos == [3, 3]
@test sim.ocean.grain_list[1, 1] == [1, 2]
@test sim.ocean.grain_list[2, 2] == []
@test sim.ocean.grain_list[3, 3] == [3]
@test sim.grains[1].atmosphere_grid_pos == [1, 1]
@test sim.grains[2].atmosphere_grid_pos == [1, 1]
@test sim.grains[3].atmosphere_grid_pos == [3, 3]
@test sim.atmosphere.grain_list[1, 1] == [1, 2]
@test sim.atmosphere.grain_list[2, 2] == []
@test sim.atmosphere.grain_list[3, 3] == [3]

@info "Testing automatic grid-size adjustment"
# ocean grid
sim = Granular.createSimulation()
@test_throws ErrorException Granular.fitGridToGrains!(sim, sim.ocean)
sim = Granular.createSimulation()
Granular.addGrainCylindrical!(sim, [0.0, 1.5], .5, 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [2.5, 5.5], 1., 1., verbose=verbose)
Granular.fitGridToGrains!(sim, sim.ocean, verbose=true)
@test sim.ocean.xq[1,1] ≈ -.5
@test sim.ocean.yq[1,1] ≈ 1.0
@test sim.ocean.xq[end,end] ≈ 3.5
@test sim.ocean.yq[end,end] ≈ 6.5

sim = Granular.createSimulation()
Granular.addGrainCylindrical!(sim, [0.5, 1.5], .5, 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [2.5, 4.5], .5, 1., verbose=verbose)
Granular.fitGridToGrains!(sim, sim.ocean, verbose=true)
@test sim.ocean.xq[1,1] ≈ 0.
@test sim.ocean.yq[1,1] ≈ 1.
@test sim.ocean.xq[end,end] ≈ 3.
@test sim.ocean.yq[end,end] ≈ 5.

sim = Granular.createSimulation()
Granular.addGrainCylindrical!(sim, [0.5, 0.0], .5, 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [2.0, 4.0], 1., 1., verbose=verbose)
Granular.fitGridToGrains!(sim, sim.ocean, padding=.5, verbose=true)
@test sim.ocean.xq[1,1] ≈ -.5
@test sim.ocean.yq[1,1] ≈ -1.
@test sim.ocean.xq[end,end] ≈ 3.5
@test sim.ocean.yq[end,end] ≈ 5.5

# atmosphere grid
sim = Granular.createSimulation()
@test_throws ErrorException Granular.fitGridToGrains!(sim, sim.atmosphere)
sim = Granular.createSimulation()
Granular.addGrainCylindrical!(sim, [0.0, 1.5], .5, 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [2.5, 5.5], 1., 1., verbose=verbose)
Granular.fitGridToGrains!(sim, sim.atmosphere, verbose=true)
@test sim.atmosphere.xq[1,1] ≈ -.5
@test sim.atmosphere.yq[1,1] ≈ 1.0
@test sim.atmosphere.xq[end,end] ≈ 3.5
@test sim.atmosphere.yq[end,end] ≈ 6.5

sim = Granular.createSimulation()
Granular.addGrainCylindrical!(sim, [0.5, 1.5], .5, 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [2.5, 4.5], .5, 1., verbose=verbose)
Granular.fitGridToGrains!(sim, sim.atmosphere, verbose=true)
@test sim.atmosphere.xq[1,1] ≈ 0.
@test sim.atmosphere.yq[1,1] ≈ 1.
@test sim.atmosphere.xq[end,end] ≈ 3.
@test sim.atmosphere.yq[end,end] ≈ 5.

sim = Granular.createSimulation()
Granular.addGrainCylindrical!(sim, [0.5, 0.0], .5, 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [2.0, 4.0], 1., 1., verbose=verbose)
Granular.fitGridToGrains!(sim, sim.atmosphere, padding=.5, verbose=true)
@test sim.atmosphere.xq[1,1] ≈ -.5
@test sim.atmosphere.yq[1,1] ≈ -1.
@test sim.atmosphere.xq[end,end] ≈ 3.5
@test sim.atmosphere.yq[end,end] ≈ 5.5

@info "Testing porosity estimation"
sim = Granular.createSimulation()
dx = 1.0; dy = 1.0
nx = 3; ny = 3
sim.ocean = Granular.createRegularOceanGrid([nx, ny, 1], [nx*dx, ny*dy, 1.])
Granular.addGrainCylindrical!(sim, [1.5, 1.5], 0.5*dx, 1.0)
A_particle = π*(0.5*dx)^2
A_cell = dx^2
Granular.findPorosity!(sim, sim.ocean)
@test sim.ocean.porosity ≈ [1. 1. 1.;
                            1. (A_cell - A_particle)/A_cell 1.;
                            1. 1. 1]
