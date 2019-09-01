#!/usr/bin/env julia

# Check for conservation of kinetic energy (=momentum) during a normal collision 
# between two ice cylindrical grains 

verbose=false

@info "## Contact-normal elasticity only"
@info "# One ice floe fixed"
sim = Granular.createSimulation(id="test")
Granular.addGrainCylindrical!(sim, [0., 10.], 10., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [19., 0.], 10., 1., verbose=verbose)
sim.grains[1].lin_vel[1] = 0.1
sim.grains[1].contact_dynamic_friction = 0.
sim.grains[2].contact_dynamic_friction = 0.
sim.grains[2].fixed = true

E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)

# With decreasing timestep (epsilon towards 0), the explicit integration scheme 
# should become more correct

Granular.setTotalTime!(sim, 30.0)
#sim.file_time_step = 1.
sim_init = deepcopy(sim)

@info "Testing kinetic energy conservation with Two-term Taylor scheme"
Granular.setTimeStep!(sim, epsilon=0.07)
tol = 0.1
@info "Relative tolerance: $(tol*100.)% with time step: $(sim.time_step)"
Granular.run!(sim, temporal_integration_method="Two-term Taylor", verbose=verbose)

E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
E_thermal_final = Granular.totalGrainThermalEnergy(sim)
@test E_kin_lin_init ≈ E_kin_lin_final+E_thermal_final atol=E_kin_lin_init*tol
@test E_kin_rot_init ≈ E_kin_rot_final


@info "Testing kinetic energy conservation with Two-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.007)
tol = 0.01
@info "Relative tolerance: $(tol*100.)%"
Granular.run!(sim, temporal_integration_method="Two-term Taylor", verbose=verbose)

E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
E_thermal_final = Granular.totalGrainThermalEnergy(sim)
@test E_kin_lin_init ≈ E_kin_lin_final+E_thermal_final atol=E_kin_lin_init*tol
@test E_kin_rot_init ≈ E_kin_rot_final


@info "Testing kinetic energy conservation with Three-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.07)
tol = 0.01
@info "Relative tolerance: $(tol*100.)% with time step: $(sim.time_step)"
Granular.run!(sim, temporal_integration_method="Three-term Taylor", verbose=verbose)

E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
E_thermal_final = Granular.totalGrainThermalEnergy(sim)
@test E_kin_lin_init ≈ E_kin_lin_final+E_thermal_final atol=E_kin_lin_init*tol
@test E_kin_rot_init ≈ E_kin_rot_final

@info "# Ice floes free to move"

sim = Granular.createSimulation(id="test")
Granular.addGrainCylindrical!(sim, [0., 10.], 10., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [19.0, 0.], 10., 1., verbose=verbose)
sim.grains[1].lin_vel[1] = 0.1
sim.grains[1].contact_dynamic_friction = 0.
sim.grains[2].contact_dynamic_friction = 0.

E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)

# With decreasing timestep (epsilon towards 0), the explicit integration scheme 
# should become more correct

Granular.setTotalTime!(sim, 30.0)
sim_init = deepcopy(sim)

@info "Testing kinetic energy conservation with Two-term Taylor scheme"
Granular.setTimeStep!(sim, epsilon=0.07)
tol = 0.1
@info "Relative tolerance: $(tol*100.)% with time step: $(sim.time_step)"
Granular.run!(sim, temporal_integration_method="Two-term Taylor", verbose=verbose)

E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init ≈ E_kin_lin_final atol=E_kin_lin_init*tol
@test E_kin_rot_init ≈ E_kin_rot_final


@info "Testing kinetic energy conservation with Two-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.007)
tol = 0.01
@info "Relative tolerance: $(tol*100.)%"
Granular.run!(sim, temporal_integration_method="Two-term Taylor", verbose=verbose)

E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init ≈ E_kin_lin_final atol=E_kin_lin_init*tol
@test E_kin_rot_init ≈ E_kin_rot_final


@info "Testing kinetic energy conservation with Three-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.07)
tol = 0.01
@info "Relative tolerance: $(tol*100.)% with time step: $(sim.time_step)"
Granular.run!(sim, temporal_integration_method="Three-term Taylor",
    verbose=verbose)

E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init ≈ E_kin_lin_final atol=E_kin_lin_init*tol
@test E_kin_rot_init ≈ E_kin_rot_final


@info "## Contact-normal elasticity and tangential viscosity and friction"
Granular.setTotalTime!(sim, 30.0)
sim_init.grains[1].contact_viscosity_tangential = 1e6
sim_init.grains[2].contact_viscosity_tangential = 1e6
sim_init.grains[1].contact_dynamic_friction = 1e2  # no Coulomb sliding
sim_init.grains[2].contact_dynamic_friction = 1e2  # no Coulomb sliding
sim_init.grains[2].fixed = true
sim = deepcopy(sim_init)


@info "Testing kinetic energy conservation with Two-term Taylor scheme"
Granular.setTimeStep!(sim, epsilon=0.07)
tol = 0.1
@info "Relative tolerance: $(tol*100.)% with time step: $(sim.time_step)"
Granular.setOutputFileInterval!(sim, 1.0)
Granular.run!(sim, temporal_integration_method="Two-term Taylor",
            verbose=verbose)

@test sim.grains[1].ang_pos[3] < 0.
@test sim.grains[1].ang_vel[3] < 0.
@test sim.grains[2].ang_pos[3] ≈ 0.
@test sim.grains[2].ang_vel[3] ≈ 0.
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
println(E_kin_lin_init)
println(E_kin_lin_final)
println(E_kin_rot_init)
println(E_kin_rot_final)
@test E_kin_lin_init+E_kin_rot_init ≈ E_kin_lin_final+E_kin_rot_final atol=E_kin_lin_init*tol

@info "mu_d = 0."
sim = deepcopy(sim_init)
sim.grains[1].contact_dynamic_friction = 0.
Granular.setTimeStep!(sim, epsilon=0.07)
tol = 0.01
@info "Relative tolerance: $(tol*100.)% with time step: $(sim.time_step)"
E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)
Granular.run!(sim, temporal_integration_method="Three-term Taylor",
            verbose=verbose)

@test sim.grains[1].ang_pos[3] ≈ 0.
@test sim.grains[1].ang_vel[3] ≈ 0.
@test sim.grains[2].ang_pos[3] ≈ 0.
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init ≈ E_kin_lin_final atol=E_kin_lin_init*tol
@test E_kin_rot_init ≈ E_kin_rot_final

@info "Testing kinetic energy conservation with Two-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.007)
tol = 0.1
@info "Relative tolerance: $(tol*100.)%"
Granular.run!(sim, temporal_integration_method="Two-term Taylor",
            verbose=verbose)

@test sim.grains[1].ang_pos[3] < 0.
@test sim.grains[1].ang_vel[3] < 0.
@test sim.grains[2].ang_pos[3] ≈ 0.
@test sim.grains[2].ang_vel[3] ≈ 0.
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init+E_kin_rot_init ≈ E_kin_lin_final+E_kin_rot_final atol=E_kin_lin_init*tol


@info "Testing kinetic energy conservation with Three-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.07)
tol = 0.09
@info "Relative tolerance: $(tol*100.)% with time step: $(sim.time_step)"
Granular.run!(sim, temporal_integration_method="Three-term Taylor",
            verbose=verbose)

@test sim.grains[1].ang_pos[3] < 0.
@test sim.grains[1].ang_vel[3] < 0.
@test sim.grains[2].ang_pos[3] ≈ 0.
@test sim.grains[2].ang_vel[3] ≈ 0.
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init+E_kin_rot_init ≈ E_kin_lin_final+E_kin_rot_final atol=E_kin_lin_init*tol

@info "# Ice floes free to move"

sim = Granular.createSimulation(id="test")
Granular.addGrainCylindrical!(sim, [0., 10.], 10., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [19.0, 0.], 10., 1., verbose=verbose)
sim.grains[1].lin_vel[1] = 0.1
sim.grains[1].contact_viscosity_tangential = 1e4
sim.grains[2].contact_viscosity_tangential = 1e4

E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)

# With decreasing timestep (epsilon towards 0), the explicit integration scheme 
# should become more correct

Granular.setTotalTime!(sim, 30.0)
sim_init = deepcopy(sim)

@info "Testing kinetic energy conservation with Two-term Taylor scheme"
Granular.setTimeStep!(sim, epsilon=0.07)
tol = 0.1
@info "Relative tolerance: $(tol*100.)% with time step: $(sim.time_step)"
Granular.run!(sim, temporal_integration_method="Two-term Taylor",
            verbose=verbose)

@test sim.grains[1].ang_pos[3] < 0.
@test sim.grains[1].ang_vel[3] < 0.
@test sim.grains[2].ang_pos[3] < 0.
@test sim.grains[2].ang_vel[3] < 0.
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init+E_kin_rot_init ≈ E_kin_lin_final+E_kin_rot_final atol=E_kin_lin_init*tol 

@info "Testing kinetic energy conservation with Two-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.007)
tol = 0.04
@info "Relative tolerance: $(tol*100.)%"
Granular.run!(sim, temporal_integration_method="Two-term Taylor",
            verbose=verbose)

E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init+E_kin_rot_init ≈ E_kin_lin_final+E_kin_rot_final atol=E_kin_lin_init*tol 


@info "Testing kinetic energy conservation with Three-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.07)
tol = 0.04
@info "Relative tolerance: $(tol*100.)% with time step: $(sim.time_step)"
Granular.run!(sim, temporal_integration_method="Three-term Taylor",
            verbose=verbose)

@test sim.grains[1].ang_pos[3] < 0.
@test sim.grains[1].ang_vel[3] < 0.
@test sim.grains[2].ang_pos[3] < 0.
@test sim.grains[2].ang_vel[3] < 0.
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init+E_kin_rot_init ≈ E_kin_lin_final+E_kin_rot_final atol=E_kin_lin_init*tol 


@info "# Ice floes free to move, mirrored"

sim = Granular.createSimulation(id="test")
Granular.addGrainCylindrical!(sim, [0., 0.], 10., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [19.0, 10.], 10., 1., verbose=verbose)
sim.grains[2].lin_vel[1] = -0.1
sim.grains[1].contact_viscosity_tangential = 1e4
sim.grains[2].contact_viscosity_tangential = 1e4

E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)

# With decreasing timestep (epsilon towards 0), the explicit integration scheme 
# should become more correct

Granular.setTotalTime!(sim, 30.0)
sim_init = deepcopy(sim)

@info "Testing kinetic energy conservation with Two-term Taylor scheme"
Granular.setTimeStep!(sim, epsilon=0.07)
tol = 0.1
@info "Relative tolerance: $(tol*100.)% with time step: $(sim.time_step)"
Granular.run!(sim, temporal_integration_method="Two-term Taylor",
            verbose=verbose)

@test sim.grains[1].ang_pos[3] > 0.
@test sim.grains[1].ang_vel[3] > 0.
@test sim.grains[2].ang_pos[3] > 0.
@test sim.grains[2].ang_vel[3] > 0.
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init+E_kin_rot_init ≈ E_kin_lin_final+E_kin_rot_final atol=E_kin_lin_init*tol 

@info "Testing kinetic energy conservation with Two-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.007)
tol = 0.04
@info "Relative tolerance: $(tol*100.)%"
Granular.run!(sim, temporal_integration_method="Two-term Taylor",
            verbose=verbose)

E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init+E_kin_rot_init ≈ E_kin_lin_final+E_kin_rot_final atol=E_kin_lin_init*tol 


@info "Testing kinetic energy conservation with Three-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.07)
tol = 0.04
@info "Relative tolerance: $(tol*100.)% with time step: $(sim.time_step)"
Granular.run!(sim, temporal_integration_method="Three-term Taylor",
            verbose=verbose)

@test sim.grains[1].ang_pos[3] > 0.
@test sim.grains[1].ang_vel[3] > 0.
@test sim.grains[2].ang_pos[3] > 0.
@test sim.grains[2].ang_vel[3] > 0.
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init+E_kin_rot_init ≈ E_kin_lin_final+E_kin_rot_final atol=E_kin_lin_init*tol 


@info "# Ice floes free to move, mirrored #2"

sim = Granular.createSimulation(id="test")
Granular.addGrainCylindrical!(sim, [0., 0.], 10., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [19.0, -10.], 10., 1., verbose=verbose)
sim.grains[2].lin_vel[1] = -0.1

E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)

# With decreasing timestep (epsilon towards 0), the explicit integration scheme 
# should become more correct

Granular.setTotalTime!(sim, 30.0)
sim_init = deepcopy(sim)

@info "Testing kinetic energy conservation with Two-term Taylor scheme"
Granular.setTimeStep!(sim, epsilon=0.07)
tol = 0.1
@info "Relative tolerance: $(tol*100.)% with time step: $(sim.time_step)"
Granular.run!(sim, temporal_integration_method="Two-term Taylor",
            verbose=verbose)

@test sim.grains[1].ang_pos[3] < 0.
@test sim.grains[1].ang_vel[3] < 0.
@test sim.grains[2].ang_pos[3] < 0.
@test sim.grains[2].ang_vel[3] < 0.
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init+E_kin_rot_init ≈ E_kin_lin_final+E_kin_rot_final atol=E_kin_lin_init*tol 

@info "Testing kinetic energy conservation with Two-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.007)
tol = 0.04
@info "Relative tolerance: $(tol*100.)%"
Granular.run!(sim, temporal_integration_method="Two-term Taylor",
            verbose=verbose)

E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init+E_kin_rot_init ≈ E_kin_lin_final+E_kin_rot_final atol=E_kin_lin_init*tol 


@info "Testing kinetic energy conservation with Three-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.07)
tol = 0.04
@info "Relative tolerance: $(tol*100.)% with time step: $(sim.time_step)"
Granular.run!(sim, temporal_integration_method="Three-term Taylor",
            verbose=verbose)

@test sim.grains[1].ang_pos[3] < 0.
@test sim.grains[1].ang_vel[3] < 0.
@test sim.grains[2].ang_pos[3] < 0.
@test sim.grains[2].ang_vel[3] < 0.
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init+E_kin_rot_init ≈ E_kin_lin_final+E_kin_rot_final atol=E_kin_lin_init*tol 


@info "# Tangential elasticity, no tangential viscosity, no Coulomb slip"

sim = Granular.createSimulation(id="test")
Granular.addGrainCylindrical!(sim, [0., 0.], 10., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [19.0, -10.], 10., 1., verbose=verbose)
sim.grains[2].lin_vel[1] = -0.1
sim.grains[1].contact_dynamic_friction = 1e3  # disable Coulomb slip
sim.grains[2].contact_dynamic_friction = 1e3  # disable Coulomb slip
sim.grains[1].contact_viscosity_tangential = 0.  # disable tan. viscosity
sim.grains[2].contact_viscosity_tangential = 0.  # disable tan. viscosity
sim.grains[1].contact_stiffness_tangential = 
    sim.grains[1].contact_stiffness_normal  # enable tangential elasticity
sim.grains[2].contact_stiffness_tangential = 
    sim.grains[2].contact_stiffness_normal  # enable tangential elasticity

E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)

# With decreasing timestep (epsilon towards 0), the explicit integration scheme 
# should become more correct

Granular.setTotalTime!(sim, 30.0)
sim_init = deepcopy(sim)

@info "Testing kinetic energy conservation with Two-term Taylor scheme"
Granular.setTimeStep!(sim, epsilon=0.07)
tol = 0.1
@info "Relative tolerance: $(tol*100.)% with time step: $(sim.time_step)"
Granular.run!(sim, temporal_integration_method="Two-term Taylor",
            verbose=verbose)

@test sim.grains[1].ang_pos[3] < 0.
@test sim.grains[1].ang_vel[3] < 0.
@test sim.grains[2].ang_pos[3] < 0.
@test sim.grains[2].ang_vel[3] < 0.
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init+E_kin_rot_init ≈ E_kin_lin_final+E_kin_rot_final atol=E_kin_lin_init*tol 

@info "Testing kinetic energy conservation with Two-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.007)
tol = 0.04
@info "Relative tolerance: $(tol*100.)%"
Granular.run!(sim, temporal_integration_method="Two-term Taylor",
            verbose=verbose)

E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init+E_kin_rot_init ≈ E_kin_lin_final+E_kin_rot_final atol=E_kin_lin_init*tol 


@info "Testing kinetic energy conservation with Three-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.07)
tol = 0.04
@info "Relative tolerance: $(tol*100.)% with time step: $(sim.time_step)"
Granular.run!(sim, temporal_integration_method="Three-term Taylor",
            verbose=verbose)

@test sim.grains[1].ang_pos[3] < 0.
@test sim.grains[1].ang_vel[3] < 0.
@test sim.grains[2].ang_pos[3] < 0.
@test sim.grains[2].ang_vel[3] < 0.
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init+E_kin_rot_init ≈ E_kin_lin_final+E_kin_rot_final atol=E_kin_lin_init*tol 


@info "# Tangential elasticity, no tangential viscosity, Coulomb slip"

sim = Granular.createSimulation(id="test")
Granular.addGrainCylindrical!(sim, [0., 0.], 10., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [19.0, -10.], 10., 1., verbose=verbose)
sim.grains[2].lin_vel[1] = -0.1
sim.grains[1].contact_dynamic_friction = 0.1  # enable Coulomb slip
sim.grains[2].contact_dynamic_friction = 0.1  # enable Coulomb slip
sim.grains[1].contact_viscosity_tangential = 0.  # disable tan. viscosity
sim.grains[2].contact_viscosity_tangential = 0.  # disable tan. viscosity
sim.grains[1].contact_stiffness_tangential = 
    sim.grains[1].contact_stiffness_normal  # enable tangential elasticity
sim.grains[2].contact_stiffness_tangential = 
    sim.grains[2].contact_stiffness_normal  # enable tangential elasticity

E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)

# With decreasing timestep (epsilon towards 0), the explicit integration scheme 
# should become more correct

Granular.setTotalTime!(sim, 30.0)
sim_init = deepcopy(sim)

@info "Testing kinetic energy conservation with Two-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.007)
tol = 0.02
@info "Relative tolerance: $(tol*100.)%"
Granular.run!(sim, temporal_integration_method="Two-term Taylor",
            verbose=verbose)

E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init+E_kin_rot_init > E_kin_lin_final+E_kin_rot_final

@info "Testing kinetic energy conservation with Three-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.07)
tol = 0.03
@info "Relative tolerance: $(tol*100.)% with time step: $(sim.time_step)"
Granular.run!(sim, temporal_integration_method="Three-term Taylor",
            verbose=verbose)

@test sim.grains[1].ang_pos[3] < 0.
@test sim.grains[1].ang_vel[3] < 0.
@test sim.grains[2].ang_pos[3] < 0.
@test sim.grains[2].ang_vel[3] < 0.
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init+E_kin_rot_init > E_kin_lin_final+E_kin_rot_final


@info "# Tangential elasticity, tangential viscosity, no Coulomb slip"

sim = Granular.createSimulation(id="test")
Granular.addGrainCylindrical!(sim, [0., 0.], 10., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [19.0, -10.], 10., 1., verbose=verbose)
sim.grains[2].lin_vel[1] = -0.1
sim.grains[1].contact_dynamic_friction = 1e3  # disable Coulomb slip
sim.grains[2].contact_dynamic_friction = 1e3  # disable Coulomb slip
sim.grains[1].contact_viscosity_tangential = 1e4  # enable tan. viscosity
sim.grains[2].contact_viscosity_tangential = 1e4  # enable tan. viscosity
sim.grains[1].contact_stiffness_tangential = 
    sim.grains[1].contact_stiffness_normal  # enable tangential elasticity
sim.grains[2].contact_stiffness_tangential = 
    sim.grains[2].contact_stiffness_normal  # enable tangential elasticity

E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)

# With decreasing timestep (epsilon towards 0), the explicit integration scheme 
# should become more correct

Granular.setTotalTime!(sim, 30.0)
sim_init = deepcopy(sim)

@info "Testing kinetic energy conservation with Two-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.007)
tol = 0.02
@info "Relative tolerance: $(tol*100.)%"
Granular.run!(sim, temporal_integration_method="Two-term Taylor",
            verbose=verbose)

E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init+E_kin_rot_init > E_kin_lin_final+E_kin_rot_final

@info "Testing kinetic energy conservation with Three-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.07)
tol = 0.03
@info "Relative tolerance: $(tol*100.)% with time step: $(sim.time_step)"
Granular.run!(sim, temporal_integration_method="Three-term Taylor",
            verbose=verbose)

@test sim.grains[1].ang_pos[3] < 0.
@test sim.grains[1].ang_vel[3] < 0.
@test sim.grains[2].ang_pos[3] < 0.
@test sim.grains[2].ang_vel[3] < 0.
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init+E_kin_rot_init > E_kin_lin_final+E_kin_rot_final


@info "# Tangential elasticity, tangential viscosity, Coulomb slip"

sim = Granular.createSimulation(id="test")
Granular.addGrainCylindrical!(sim, [0., 0.], 10., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [19.0, -10.], 10., 1., verbose=verbose)
sim.grains[2].lin_vel[1] = -0.1
sim.grains[1].contact_dynamic_friction = 0.1  # enable Coulomb slip
sim.grains[2].contact_dynamic_friction = 0.1  # enable Coulomb slip
sim.grains[1].contact_viscosity_tangential = 1e4  # enable tan. viscosity
sim.grains[2].contact_viscosity_tangential = 1e4  # enable tan. viscosity
sim.grains[1].contact_stiffness_tangential = 
    sim.grains[1].contact_stiffness_normal  # enable tangential elasticity
sim.grains[2].contact_stiffness_tangential = 
    sim.grains[2].contact_stiffness_normal  # enable tangential elasticity

E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)

# With decreasing timestep (epsilon towards 0), the explicit integration scheme 
# should become more correct

Granular.setTotalTime!(sim, 30.0)
sim_init = deepcopy(sim)

@info "Testing kinetic energy conservation with Two-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.007)
tol = 0.02
@info "Relative tolerance: $(tol*100.)%"
Granular.run!(sim, temporal_integration_method="Two-term Taylor",
            verbose=verbose)

E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init+E_kin_rot_init > E_kin_lin_final+E_kin_rot_final

@info "Testing kinetic energy conservation with Three-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.07)
tol = 0.03
@info "Relative tolerance: $(tol*100.)% with time step: $(sim.time_step)"
Granular.run!(sim, temporal_integration_method="Three-term Taylor",
            verbose=verbose)

@test sim.grains[1].ang_pos[3] < 0.
@test sim.grains[1].ang_vel[3] < 0.
@test sim.grains[2].ang_pos[3] < 0.
@test sim.grains[2].ang_vel[3] < 0.
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init+E_kin_rot_init > E_kin_lin_final+E_kin_rot_final
