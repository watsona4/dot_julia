#!/usr/bin/env julia
using Test
import Granular

verbose = false
plot = false
plot_packings=false

@info "Testing regular packing generation (power law GSD)"
sim = Granular.createSimulation()
Granular.regularPacking!(sim, [2, 2], 1., 1., size_distribution="powerlaw")
@test 4 == length(sim.grains)
for grain in sim.grains
    @test grain.contact_radius ≈ 1.
end

sim = Granular.createSimulation()
Granular.regularPacking!(sim, [10, 10], 1., 10., size_distribution="powerlaw")
@test 100 == length(sim.grains)
for grain in sim.grains
    @test grain.contact_radius >= 1.
    @test grain.contact_radius <= 10.
end
plot && Granular.plotGrains(sim, filetype="regular-powerlaw.png", show_figure=false)

@info "Testing regular packing generation (uniform GSD)"
sim = Granular.createSimulation()
Granular.regularPacking!(sim, [2, 2], 1., 1., size_distribution="uniform")
@test 4 == length(sim.grains)
for grain in sim.grains
    @test grain.contact_radius ≈ 1.
end

sim = Granular.createSimulation()
Granular.regularPacking!(sim, [10, 10], 1., 10., size_distribution="uniform")
@test 100 == length(sim.grains)
for grain in sim.grains
    @test grain.contact_radius >= 1.
    @test grain.contact_radius <= 10.
end
plot && Granular.plotGrains(sim, filetype="regular-uniform.png", show_figure=false)


@info "Testing irregular (Poisson-disk) packing generation (monodisperse size)"
sim = Granular.createSimulation("poisson1-monodisperse-nopadding")
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [1., 1., 1.])
Granular.irregularPacking!(sim,
                           radius_max=.1,
                           radius_min=.1,
                           padding_factor=0.,
                           plot_during_packing=plot_packings,
                           verbose=verbose)
@test length(sim.grains) > 23

@info "Testing irregular (Poisson-disk) packing generation (wide PSD)"
sim = Granular.createSimulation("poisson2-wide-nopadding")
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [1., 1., 1.])
Granular.irregularPacking!(sim,
                           radius_max=.1,
                           radius_min=.005,
                           padding_factor=0.,
                           plot_during_packing=plot_packings,
                           verbose=verbose)
@test length(sim.grains) > 280
sim = Granular.createSimulation("poisson3-wide-padding")
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [1., 1., 1.])
Granular.irregularPacking!(sim,
                           radius_max=.1,
                           radius_min=.005,
                           padding_factor=2.,
                           plot_during_packing=plot_packings,
                           verbose=verbose)
@test length(sim.grains) > 280

sim = Granular.createSimulation("poisson4-binary-search")
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [1., 1., 1.])
Granular.irregularPacking!(sim,
                           radius_max=.1,
                           radius_min=.005,
                           binary_radius_search=true,
                           plot_during_packing=plot_packings,
                           verbose=verbose)
@test length(sim.grains) > 280

@info "Testing irregular packing with inactive boundaries"
sim = Granular.createSimulation("poisson-inactive")
sim.ocean = Granular.createRegularOceanGrid([5, 5, 1], [1., 1., 1.])
Granular.setGridBoundaryConditions!(sim.ocean, "inactive", verbose=verbose)
Granular.irregularPacking!(sim,
                           radius_max=.05,
                           radius_min=.1,
                           padding_factor=0.,
                           plot_during_packing=plot_packings,
                           verbose=verbose)
Granular.findContacts!(sim, method="ocean grid")
plot && Granular.plotGrains(sim, filetype="poisson-inactive.png", show_figure=false)
for grain in sim.grains
    @test grain.n_contacts == 0
end

@info "Testing irregular packing with periodic boundaries"
sim = Granular.createSimulation("poisson-periodic")
sim.ocean = Granular.createRegularOceanGrid([5, 5, 1], [1., 1., 1.])
Granular.setGridBoundaryConditions!(sim.ocean, "periodic", verbose=verbose)
Granular.irregularPacking!(sim,
                           radius_max=.05,
                           radius_min=.1,
                           padding_factor=0.,
                           plot_during_packing=plot_packings,
                           verbose=verbose)
plot && Granular.plotGrains(sim, filetype="poisson-periodic.png", show_figure=false)
Granular.findContacts!(sim, method="ocean grid")
for grain in sim.grains
    @test grain.n_contacts == 0
end


@info "Testing raster-based mapping algorithm"
sim = Granular.createSimulation("raster-packing1")
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [1., 1., 1.])
Granular.addGrainCylindrical!(sim, [0.5, 0.5], 0.4, 1.0)
occupied = Granular.rasterMap(sim, 0.08)
occupied_ans = Array{Bool}([
0 0 0 0 0 0 0 0 0 0 0 0;
0 0 0 1 1 1 1 1 1 0 0 0;
0 0 1 1 1 1 1 1 1 1 1 0;
0 1 1 1 1 1 1 1 1 1 1 0;
0 1 1 1 1 1 1 1 1 1 1 1;
0 1 1 1 1 1 1 1 1 1 1 1;
0 1 1 1 1 1 1 1 1 1 1 1;
0 1 1 1 1 1 1 1 1 1 1 1;
0 1 1 1 1 1 1 1 1 1 1 0;
0 0 1 1 1 1 1 1 1 1 1 0;
0 0 1 1 1 1 1 1 1 1 0 0;
0 0 0 0 1 1 1 1 0 0 0 0])
@test occupied == occupied_ans
Granular.addGrainCylindrical!(sim, [0.03, 0.03], 0.02, 1.0)
occupied = Granular.rasterMap(sim, 0.08)
occupied_ans = Array{Bool}([
1 0 0 0 0 0 0 0 0 0 0 0;
0 0 0 1 1 1 1 1 1 0 0 0;
0 0 1 1 1 1 1 1 1 1 1 0;
0 1 1 1 1 1 1 1 1 1 1 0;
0 1 1 1 1 1 1 1 1 1 1 1;
0 1 1 1 1 1 1 1 1 1 1 1;
0 1 1 1 1 1 1 1 1 1 1 1;
0 1 1 1 1 1 1 1 1 1 1 1;
0 1 1 1 1 1 1 1 1 1 1 0;
0 0 1 1 1 1 1 1 1 1 1 0;
0 0 1 1 1 1 1 1 1 1 0 0;
0 0 0 0 1 1 1 1 0 0 0 0])
@test occupied == occupied_ans
sim_init = deepcopy(sim)
plot && Granular.plotGrains(sim, filetype="rastermap.png", show_figure=false)

@info "Testing raster-based mapping algorithm (power law GSD)"
sim = deepcopy(sim_init)
np_init = length(sim.grains)
Granular.rasterPacking!(sim, 0.02, 0.04, verbose=verbose)
@test np_init < length(sim.grains)
plot && Granular.plotGrains(sim, filetype="powerlaw.png", show_figure=false)

@info "Testing raster-based mapping algorithm (uniform GSD)"
sim = deepcopy(sim_init)
np_init = length(sim.grains)
Granular.rasterPacking!(sim, 0.02, 0.04, size_distribution="uniform",
                        verbose=verbose)
@test np_init < length(sim.grains)
plot && Granular.plotGrains(sim, filetype="uniform.png", show_figure=false)

@info "Tesing square packing"
sim = Granular.createSimulation()
Granular.regularPacking!(sim, [5,6], 1.0, 1.0, tiling="square",
                        padding_factor=0.0)
@test length(sim.grains) == 5*6
plot && Granular.plotGrains(sim, filetype="square.png", show_figure=false)

@info "Tesing triangular packing"
sim = Granular.createSimulation()
Granular.regularPacking!(sim, [6,6], 1.0, 1.0, tiling="triangular",
                        padding_factor=0.0)
@test length(sim.grains) == 6*6
plot && Granular.plotGrains(sim, filetype="triangular.png", show_figure=false)
