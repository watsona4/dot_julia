#!/usr/bin/env julia

# Check the basic dynamic wall functionality

@info "# Test wall initialization"
@info "Testing argument value checks"
sim = Granular.createSimulation()
Granular.addGrainCylindrical!(sim, [ 0., 0.], 10., 2., verbose=false)
@test_throws ErrorException Granular.addWallLinearFrictionless!(sim,
                                                                [.1, .1, .1, .1],
                                                                1.)
@test_throws ErrorException Granular.addWallLinearFrictionless!(sim,
                                                                [1., 1.],
                                                                1.)
@test_throws ErrorException Granular.addWallLinearFrictionless!(sim,
                                                                [.1, .1, .1],
                                                                1.)
@test_throws ErrorException Granular.addWallLinearFrictionless!(sim,
                                                                [0., 1., 1.], 1.,
                                                                bc="asdf")
sim = Granular.createSimulation()
@test_throws ErrorException Granular.addWallLinearFrictionless!(sim, [1., 0.],
                                                                1.)


@info "Check that wall mass equals total grain mass and max. thickness"
sim = Granular.createSimulation()
@test length(sim.walls) == 0
Granular.addGrainCylindrical!(sim, [ 0., 0.], 10., 2., verbose=false)
sim.grains[1].mass = 1.0
Granular.addWallLinearFrictionless!(sim, [1., 0.], 1., verbose=true)
@test length(sim.walls) == 1
@test sim.walls[1].mass ≈ 1.0
@test sim.walls[1].thickness ≈ 2.0

@info "Test wall surface area and defined normal stress"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 0., 0.], 10., 2., verbose=false)
sim.grains[1].mass = 1.0
Granular.addWallLinearFrictionless!(sim, [1., 0.], 1., verbose=false)
Granular.addWallLinearFrictionless!(sim, [0., 1.], 1., verbose=false)
@test length(sim.walls) == 2
@test sim.walls[1].mass ≈ 1.0
@test sim.walls[1].thickness ≈ 2.0
@test sim.walls[2].mass ≈ 1.0
@test sim.walls[2].thickness ≈ 2.0
@test Granular.getWallSurfaceArea(sim, 1) ≈ 20.0*2.0
@test Granular.getWallSurfaceArea(sim, 2) ≈ 10.0*2.0

sim.walls[1].normal_stress = 1.0
@test Granular.getWallNormalStress(sim, wall_index=1, stress_type="defined") ≈ 1.0
sim.walls[1].force = 1.0
@test Granular.getWallNormalStress(sim, wall_index=1, stress_type="effective") ≈ 1.0/(20.0*2.0)
@test_throws ErrorException Granular.getWallNormalStress(sim, wall_index=1, stress_type="nonexistent")

sim.walls[1].normal = [1.0, 1.0, 1.0]
@test_throws ErrorException Granular.getWallSurfaceArea(sim, 1)
@test_throws ErrorException Granular.getWallSurfaceArea(sim, [1.,1.], 0.5)

@info "# Test wall-grain interaction: elastic"

@info "Wall present but no contact"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 0., 0.], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [1., 0.], -1.01, verbose=false)
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
@test sim.walls[1].force ≈ 0.
@test sim.grains[1].force[1] ≈ 0.
@test sim.grains[1].force[2] ≈ 0.

@info "Wall present but no contact"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 0., 0.], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [1., 0.], +2.01, verbose=false)
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
@test sim.walls[1].force ≈ 0.
@test sim.grains[1].force[1] ≈ 0.
@test sim.grains[1].force[2] ≈ 0.

@info "Wall at -x"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 0., 0.], 1., 2., youngs_modulus=0.,
                              verbose=false)
Granular.addWallLinearFrictionless!(sim, [1., 0.], -1. + .01, verbose=false)
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
@test sim.walls[1].force < 0.
@test sim.grains[1].force[1] > 0.
@test sim.grains[1].force[2] ≈ 0.

@info "Wall at -x"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 0., 0.], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [1., 0.], -1. + .01, verbose=false)
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
@test sim.walls[1].force < 0.
@test sim.grains[1].force[1] > 0.
@test sim.grains[1].force[2] ≈ 0.

@info "Wall at +x"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 0., 0.], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [1., 0.], +1. - .01, verbose=false)
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
@test sim.walls[1].force > 0.
@test sim.grains[1].force[1] < 0.
@test sim.grains[1].force[2] ≈ 0.

@info "Wall at -y"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 0., 0.], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [0., 1.], -1. + .01, verbose=false)
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
@test sim.walls[1].force < 0.
@test sim.grains[1].force[1] ≈ 0.
@test sim.grains[1].force[2] > 0.

@info "Wall at +y"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 0., 0.], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [0., 1.], +1. - .01, verbose=false)
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
@test sim.walls[1].force > 0.
@test sim.grains[1].force[1] ≈ 0.
@test sim.grains[1].force[2] < 0.

@info "# Test wall-grain interaction: elastic-viscous"

@info "Wall present but no contact"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 0., 0.], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [1., 0.], -1.01, verbose=false)
sim.walls[1].contact_viscosity_normal = 1e3
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
@test sim.walls[1].force ≈ 0.
@test sim.grains[1].force[1] ≈ 0.
@test sim.grains[1].force[2] ≈ 0.

@info "Wall present but no contact"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 0., 0.], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [1., 0.], +2.01, verbose=false)
sim.walls[1].contact_viscosity_normal = 1e3
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
@test sim.walls[1].force ≈ 0.
@test sim.grains[1].force[1] ≈ 0.
@test sim.grains[1].force[2] ≈ 0.

@info "Wall at -x"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 0., 0.], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [1., 0.], -1. + .01, verbose=false)
sim.walls[1].contact_viscosity_normal = 1e3
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
@test sim.walls[1].force < 0.
@test sim.grains[1].force[1] > 0.
@test sim.grains[1].force[2] ≈ 0.

@info "Wall at +x"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 0., 0.], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [1., 0.], +1. - .01, verbose=false)
sim.walls[1].contact_viscosity_normal = 1e3
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
@test sim.walls[1].force > 0.
@test sim.grains[1].force[1] < 0.
@test sim.grains[1].force[2] ≈ 0.

@info "Wall at -y"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 0., 0.], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [0., 1.], -1. + .01, verbose=false)
sim.walls[1].contact_viscosity_normal = 1e3
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
@test sim.walls[1].force < 0.
@test sim.grains[1].force[1] ≈ 0.
@test sim.grains[1].force[2] > 0.

@info "Wall at +y"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 0., 0.], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [0., 1.], +1. - .01, verbose=false)
sim.walls[1].contact_viscosity_normal = 1e3
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
@test sim.walls[1].force > 0.
@test sim.grains[1].force[1] ≈ 0.
@test sim.grains[1].force[2] < 0.

@info "Full collision with wall"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [1.2, 0.5], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [1., 0.], 0., verbose=false)
sim.walls[1].contact_viscosity_normal = 1e3
sim.grains[1].lin_vel[1] = -0.2
Granular.setTimeStep!(sim, verbose=false)
Granular.setTotalTime!(sim, 5.)
lin_vel0 = sim.grains[1].lin_vel
Granular.run!(sim)
@test sim.grains[1].lin_vel[1] < abs(lin_vel0[1])
@test sim.grains[1].lin_vel[2] ≈ 0.
lin_vel1 = sim.grains[1].lin_vel

sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [1.2, 0.5], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [1., 0.], 0., verbose=false)
sim.walls[1].contact_viscosity_normal = 1e4
sim.grains[1].lin_vel[1] = -0.2
Granular.setTimeStep!(sim, verbose=false)
Granular.setTotalTime!(sim, 5.)
lin_vel0 = sim.grains[1].lin_vel
Granular.run!(sim)
@test sim.grains[1].lin_vel[1] < abs(lin_vel0[1])
@test sim.grains[1].lin_vel[1] < lin_vel1[1]
@test sim.grains[1].lin_vel[2] ≈ 0.


@info "# Testing wall dynamics"

@info "Wall present, no contact, fixed (default)"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 1., 1.], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [1., 0.], -0.01, verbose=false)
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
Granular.updateWallKinematics!(sim)
@test sim.walls[1].force ≈ 0.
@test sim.walls[1].acc ≈ 0.
@test sim.walls[1].vel ≈ 0.
@test sim.walls[1].pos ≈ -0.01
@test sim.grains[1].force[1] ≈ 0.
@test sim.grains[1].force[2] ≈ 0.

@info "Wall present, no contact, fixed (TY2)"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 1., 1.], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [1., 0.], -0.01, verbose=false)
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
Granular.updateWallKinematics!(sim, method="Two-term Taylor")
@test sim.walls[1].force ≈ 0.
@test sim.walls[1].acc ≈ 0.
@test sim.walls[1].vel ≈ 0.
@test sim.walls[1].pos ≈ -0.01
@test sim.grains[1].force[1] ≈ 0.
@test sim.grains[1].force[2] ≈ 0.

@info "Wall present, no contact, fixed (TY3)"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 1., 1.], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [1., 0.], -0.01, verbose=false)
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
@test_throws ErrorException Granular.updateWallKinematics!(sim, method="asdf")
Granular.updateWallKinematics!(sim, method="Three-term Taylor")
@test sim.walls[1].force ≈ 0.
@test sim.walls[1].acc ≈ 0.
@test sim.walls[1].vel ≈ 0.
@test sim.walls[1].pos ≈ -0.01
@test sim.grains[1].force[1] ≈ 0.
@test sim.grains[1].force[2] ≈ 0.

@info "Wall present, contact, fixed"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 1., 1.], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [1., 0.], -0.01, verbose=false)
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
Granular.updateWallKinematics!(sim)
@test sim.walls[1].acc ≈ 0.
@test sim.walls[1].vel ≈ 0.
@test sim.walls[1].pos ≈ -0.01

@info "Wall present, no contact, velocity BC"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 1., 1.], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [1., 0.], -0.01,
                                    bc="velocity", vel=1.0,
                                    verbose=false)
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
Granular.updateWallKinematics!(sim)
@test sim.walls[1].force ≈ 0.
@test sim.walls[1].acc ≈ 0.
@test sim.walls[1].vel ≈ 1.
@test sim.walls[1].pos > -0.01
@test sim.grains[1].force[1] ≈ 0.
@test sim.grains[1].force[2] ≈ 0.

@info "Wall present, no contact, velocity BC (TY2)"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 1., 1.], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [1., 0.], -0.01,
                                    bc="velocity", vel=1.0,
                                    verbose=false)
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
Granular.updateWallKinematics!(sim, method="Two-term Taylor")
@test sim.walls[1].force ≈ 0.
@test sim.walls[1].acc ≈ 0.
@test sim.walls[1].vel ≈ 1.
@test sim.walls[1].pos > -0.01
@test sim.grains[1].force[1] ≈ 0.
@test sim.grains[1].force[2] ≈ 0.

@info "Wall present, no contact, velocity BC (TY3)"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 1., 1.], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [1., 0.], -0.01,
                                    bc="velocity", vel=1.0,
                                    verbose=false)
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
@test_throws ErrorException Granular.updateWallKinematics!(sim, method="asdf")
Granular.updateWallKinematics!(sim, method="Three-term Taylor")
@test sim.walls[1].force ≈ 0.
@test sim.walls[1].acc ≈ 0.
@test sim.walls[1].vel ≈ 1.
@test sim.walls[1].pos > -0.01
@test sim.grains[1].force[1] ≈ 0.
@test sim.grains[1].force[2] ≈ 0.

@info "Wall present, contact, velocity BC (TY2)"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 1., 1.], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [1., 0.], 0.1,
                                    bc="velocity", vel=1.0,
                                    verbose=false)
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
Granular.updateWallKinematics!(sim, method="Two-term Taylor")
@test sim.walls[1].bc == "velocity"
@test sim.walls[1].acc ≈ 0.
@test sim.walls[1].vel ≈ 1.
@test sim.walls[1].pos > -0.9

@info "Wall present, contact, velocity BC (TY2)"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [10., 20., 1.0])
Granular.addGrainCylindrical!(sim, [ 1., 1.], 1., 2., verbose=false)
Granular.addWallLinearFrictionless!(sim, [1., 0.], 0.1,
                                    bc="velocity", vel=1.0,
                                    verbose=false)
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
Granular.updateWallKinematics!(sim, method="Two-term Taylor")
@test sim.walls[1].acc ≈ 0.
@test sim.walls[1].vel ≈ 1.
@test sim.walls[1].pos > -0.9

@info "Wall present, contact, normal stress BC"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [2., 2., 1.])
Granular.addGrainCylindrical!(sim, [ 1., 1.], 1., 1., verbose=false)
Granular.addWallLinearFrictionless!(sim, [1., 0.], 2.,
                                    bc="normal stress",
                                    normal_stress=0.,
                                    verbose=false)
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
Granular.updateWallKinematics!(sim)
@test sim.walls[1].force ≈ 0.
@test sim.walls[1].acc ≈ 0.
@test sim.walls[1].vel ≈ 0.
@test sim.grains[1].force[1] ≈ 0.
@test sim.grains[1].force[2] ≈ 0.

@info "Wall present, contact, normal stress BC"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [2., 2., 1.])
Granular.addGrainCylindrical!(sim, [ 1., 1.], 1., 1., verbose=false)
sim.grains[1].fixed = true
Granular.addWallLinearFrictionless!(sim, [1., 0.], 2.,
                                    bc="normal stress",
                                    normal_stress=-1e4,
                                    verbose=false)
Granular.setTimeStep!(sim, verbose=false)
Granular.interactWalls!(sim)
Granular.updateWallKinematics!(sim)
@test sim.walls[1].force ≈ 0.
@test sim.walls[1].acc < 0.
@test sim.walls[1].vel < 0.
@test sim.grains[1].force[1] ≈ 0.
@test sim.grains[1].force[2] ≈ 0.
for i=1:5
    Granular.interactWalls!(sim)
    Granular.updateWallKinematics!(sim)
    @test sim.walls[1].force > 0.
    @test sim.walls[1].acc < 0.
    @test sim.walls[1].vel < 0.
    @test sim.walls[1].pos < 2.
    @test sim.grains[1].force[1] < 0.
    @test sim.grains[1].force[2] ≈ 0.
end

@info "Granular packing, wall present, normal stress BC"
sim = Granular.createSimulation()
Granular.regularPacking!(sim, [5, 5], 1.0, 2.0)
Granular.fitGridToGrains!(sim, sim.ocean)
Granular.setGridBoundaryConditions!(sim.ocean, "impermeable")
global y_max_init = 0.
for grain in sim.grains
    if y_max_init < grain.lin_pos[2] + grain.contact_radius
        global y_max_init = grain.lin_pos[2] + grain.contact_radius
    end
end
Granular.addWallLinearFrictionless!(sim, [0., 1.], y_max_init,
                                    bc="normal stress", normal_stress=-100e3)
Granular.setTimeStep!(sim)
Granular.setTotalTime!(sim, 1.)
Granular.run!(sim)
Granular.removeSimulationFiles(sim)
@test sim.walls[1].pos < y_max_init
