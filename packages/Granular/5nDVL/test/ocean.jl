#!/usr/bin/env julia

# Check if ocean-specific functions and grid operations are functioning 
# correctly

@info "Testing regular grid generation"
sim = Granular.createSimulation()
sim.ocean = Granular.createRegularOceanGrid([6, 6, 6], [1., 1., 1.])
@test size(sim.ocean.xq) == (7, 7)
@test size(sim.ocean.yq) == (7, 7)
@test size(sim.ocean.xh) == (6, 6)
@test size(sim.ocean.yh) == (6, 6)
@test sim.ocean.xq[1, :, 1] ≈ zeros(7)
@test sim.ocean.xq[4, :, 1] ≈ .5 * ones(7)
@test sim.ocean.xq[end, :, 1] ≈ 1. * ones(7)
@test sim.ocean.yq[:, 1, 1] ≈ zeros(7)
@test sim.ocean.yq[:, 4, 1] ≈ .5 * ones(7)
@test sim.ocean.yq[:, end, 1] ≈ 1. * ones(7)
@test size(sim.ocean.u) == (7, 7, 6, 1)
@test size(sim.ocean.v) == (7, 7, 6, 1)
@test size(sim.ocean.h) == (7, 7, 6, 1)
@test size(sim.ocean.e) == (7, 7, 6, 1)
@test sim.ocean.u ≈ zeros(7, 7, 6, 1)
@test sim.ocean.v ≈ zeros(7, 7, 6, 1)
@test sim.ocean.h ≈ zeros(7, 7, 6, 1)
@test sim.ocean.e ≈ zeros(7, 7, 6, 1)

@info "Testing velocity drag interaction (static ocean)"
Granular.addGrainCylindrical!(sim, [.5, .5], .25, .1)
Granular.setTotalTime!(sim, 5.)
Granular.setTimeStep!(sim)
sim_init = deepcopy(sim)
sim.grains[1].lin_vel[1] = 0.1
E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)
Granular.run!(sim, verbose=false)
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_rot_init ≈ E_kin_rot_final  # no rotation before or after
@test E_kin_lin_init > E_kin_lin_final  # linear velocity lost due to ocean drag
@test sim.grains[1].ocean_stress[1] < 0.
@test sim.grains[1].ocean_stress[2] ≈ 0.

@info "Testing velocity drag interaction (static ice floe)"
sim = deepcopy(sim_init)
sim.ocean.v[:, :, 1, 1] .= 0.1
E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)
Granular.run!(sim, verbose=false)
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_rot_init ≈ E_kin_rot_final  # no rotation before or after
@test E_kin_lin_init < E_kin_lin_final  # linear vel. gained due to ocean drag
@test sim.grains[1].ocean_stress[1] ≈ 0.
@test sim.grains[1].ocean_stress[2] > 0.

@info "Testing vortex interaction (static ocean)"
sim = deepcopy(sim_init)
sim.grains[1].ang_vel[3] = 0.1
E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)
Granular.run!(sim, verbose=false)
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_rot_init > E_kin_rot_final  # energy lost to ocean
@test sim.grains[1].ang_vel[3] > 0.     # check angular velocity orientation
@test sim.grains[1].ang_pos[3] > 0.     # check angular position orientation
@test E_kin_lin_init ≈ E_kin_lin_final  # no linear velocity gained

@info "Testing vortex interaction (static ice floe)"
sim = deepcopy(sim_init)
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [1., 1., 1.])
sim.grains[1].lin_pos[1] = 0.5
sim.grains[1].lin_pos[2] = 0.5
sim.ocean.v[1, :, 1, 1] .= -0.1
sim.ocean.v[2, :, 1, 1] .= 0.1
E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)
Granular.run!(sim, verbose=false)
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test sim.grains[1].ang_vel[3] > 0.     # check angular velocity orientation
@test sim.grains[1].ang_pos[3] > 0.     # check angular position orientation
@test E_kin_rot_init < E_kin_rot_final  # rotation after due to ocean vortex
@test E_kin_lin_init ≈ E_kin_lin_final  # no linear velocity gained

sim = deepcopy(sim_init)
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [1., 1., 1.])
sim.grains[1].lin_pos[1] = 0.5
sim.grains[1].lin_pos[2] = 0.5
sim.ocean.v[1, :, 1, 1] .= 0.1
sim.ocean.v[2, :, 1, 1] .= -0.1
E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)
Granular.run!(sim, verbose=false)
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test sim.grains[1].ang_vel[3] < 0.     # check angular velocity orientation
@test sim.grains[1].ang_pos[3] < 0.     # check angular position orientation
@test E_kin_rot_init < E_kin_rot_final  # rotation after due to ocean vortex
@test E_kin_lin_init ≈ E_kin_lin_final  # no linear velocity gained

sim = deepcopy(sim_init)
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [1., 1., 1.])
sim.grains[1].lin_pos[1] = 0.5
sim.grains[1].lin_pos[2] = 0.5
sim.ocean.u[:, 1, 1, 1] .= -0.1
sim.ocean.u[:, 2, 1, 1] .= 0.1
E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)
Granular.run!(sim, verbose=false)
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test sim.grains[1].ang_vel[3] < 0.     # check angular velocity orientation
@test sim.grains[1].ang_pos[3] < 0.     # check angular position orientation
@test E_kin_rot_init < E_kin_rot_final  # rotation after due to ocean vortex
@test E_kin_lin_init ≈ E_kin_lin_final  # no linear velocity gained

sim = deepcopy(sim_init)
sim.ocean = Granular.createRegularOceanGrid([1, 1, 1], [1., 1., 1.])
sim.grains[1].lin_pos[1] = 0.5
sim.grains[1].lin_pos[2] = 0.5
sim.ocean.u[:, 1, 1, 1] .= 0.1
sim.ocean.u[:, 2, 1, 1] .= -0.1
E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)
Granular.run!(sim, verbose=false)
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test sim.grains[1].ang_vel[3] > 0.     # check angular velocity orientation
@test sim.grains[1].ang_pos[3] > 0.     # check angular position orientation
@test E_kin_rot_init < E_kin_rot_final  # rotation after due to ocean vortex
@test E_kin_lin_init ≈ E_kin_lin_final  # no linear velocity gained
