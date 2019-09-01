#!/usr/bin/env julia

# Check for conservation of kinetic energy (=momentum) during a normal collision 
# between two ice cylindrical grains 

verbose=false

@info "# One ice floe fixed"
sim = Granular.createSimulation(id="test")
Granular.addGrainCylindrical!(sim, [0., 0.], 10., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [20.05, 0.], 10., 1., verbose=verbose)
sim.grains[1].lin_vel[1] = 0.1
sim.grains[2].fixed = true

E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)

# With decreasing timestep (epsilon towards 0), the explicit integration scheme 
# should become more correct

Granular.setTotalTime!(sim, 10.0)
sim_init = deepcopy(sim)

@info "Testing kinetic energy conservation with Two-term Taylor scheme"
Granular.setTimeStep!(sim, epsilon=0.07)
tol = 0.2
@info "Relative tolerance: $(tol*100.)% with time step: $(sim.time_step)"
Granular.run!(sim, temporal_integration_method="Two-term Taylor", verbose=verbose)

E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init ≈ E_kin_lin_final atol=E_kin_lin_init*tol
@test E_kin_rot_init ≈ E_kin_rot_final


@info "Testing kinetic energy conservation with Two-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.007)
tol = 0.02
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


@info "# Ice floes free to move"

sim = Granular.createSimulation(id="test")
Granular.addGrainCylindrical!(sim, [0., 0.], 10., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [20.05, 0.], 10., 1., verbose=verbose)
sim.grains[1].lin_vel[1] = 0.1

E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)

# With decreasing timestep (epsilon towards 0), the explicit integration scheme 
# should become more correct

Granular.setTotalTime!(sim, 10.0)
sim_init = deepcopy(sim)

@info "Testing kinetic energy conservation with Two-term Taylor scheme"
Granular.setTimeStep!(sim, epsilon=0.07)
tol = 0.2
@info "Relative tolerance: $(tol*100.)% with time step: $(sim.time_step)"
Granular.run!(sim, temporal_integration_method="Two-term Taylor", verbose=verbose)

E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init ≈ E_kin_lin_final atol=E_kin_lin_init*tol
@test E_kin_rot_init ≈ E_kin_rot_final


@info "Testing kinetic energy conservation with Two-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.007)
tol = 0.02
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


@info "# Adding contact-normal viscosity"
@info "# One ice floe fixed"
sim = Granular.createSimulation(id="test")
Granular.addGrainCylindrical!(sim, [0., 0.], 10., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [20.05, 0.], 10., 1., verbose=verbose)
sim.grains[1].lin_vel[1] = 0.1
sim.grains[1].contact_viscosity_normal = 1e4
sim.grains[2].contact_viscosity_normal = 1e4
sim.grains[2].fixed = true

E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)

# With decreasing timestep (epsilon towards 0), the explicit integration scheme 
# should become more correct

Granular.setTotalTime!(sim, 10.0)
sim_init = deepcopy(sim)


@info "Testing kinetic energy conservation with Two-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.007)
tol = 0.02
@info "Relative tolerance: $(tol*100.)%"
Granular.run!(sim, temporal_integration_method="Two-term Taylor", verbose=verbose)

E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init > E_kin_lin_final
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
@test E_kin_lin_init > E_kin_lin_final
@test E_kin_rot_init ≈ E_kin_rot_final


@info "# Ice floes free to move"

sim = Granular.createSimulation(id="test")
Granular.addGrainCylindrical!(sim, [0., 0.], 10., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [20.05, 0.], 10., 1., verbose=verbose)
sim.grains[1].lin_vel[1] = 0.1
sim.grains[1].contact_viscosity_normal = 1e4
sim.grains[2].contact_viscosity_normal = 1e4

E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)

# With decreasing timestep (epsilon towards 0), the explicit integration scheme 
# should become more correct

Granular.setTotalTime!(sim, 10.0)
sim_init = deepcopy(sim)

@info "Testing kinetic energy conservation with Two-term Taylor scheme"
sim = deepcopy(sim_init)
Granular.setTimeStep!(sim, epsilon=0.007)
tol = 0.02
@info "Relative tolerance: $(tol*100.)%"
Granular.run!(sim, temporal_integration_method="Two-term Taylor", verbose=verbose)

E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init > E_kin_lin_final
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
@test E_kin_lin_init > E_kin_lin_final
@test E_kin_rot_init ≈ E_kin_rot_final


@info "# Testing allow_*_acc for fixed grains"
sim = Granular.createSimulation(id="test")
Granular.addGrainCylindrical!(sim, [0., 0.], 10., 1., verbose=verbose)
Granular.addGrainCylindrical!(sim, [20.05, 0.], 10., 1., verbose=verbose)
sim.grains[1].lin_vel[1] = 0.1
sim.grains[2].fixed = true

E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)
grain2_pos_init = sim.grains[2].lin_pos

Granular.setTotalTime!(sim, 10.0)
Granular.setTimeStep!(sim, epsilon=0.07)
sim_init = deepcopy(sim)
sim.grains[2].allow_y_acc = true  # should not influence result

@info "Two-term Taylor scheme: allow_y_acc"
sim = deepcopy(sim_init)
sim.grains[2].allow_y_acc = true  # should not influence result
tol = 0.2
Granular.run!(sim, temporal_integration_method="Two-term Taylor", verbose=verbose)

E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init ≈ E_kin_lin_final atol=E_kin_lin_init*tol
@test E_kin_rot_init ≈ E_kin_rot_final
@test sim.grains[2].lin_pos ≈ grain2_pos_init

@info "Two-term Taylor scheme: allow_x_acc"
sim = deepcopy(sim_init)
sim.grains[2].allow_x_acc = true  # should influence result
tol = 0.2
Granular.run!(sim, temporal_integration_method="Two-term Taylor", verbose=verbose)

E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init ≈ E_kin_lin_final atol=E_kin_lin_init*tol
@test E_kin_rot_init ≈ E_kin_rot_final
@test sim.grains[2].lin_pos[1] > grain2_pos_init[1]

@info "Three-term Taylor scheme: allow_y_acc"
sim = deepcopy(sim_init)
tol = 0.02
sim.grains[2].allow_y_acc = true  # should influence result
Granular.run!(sim, temporal_integration_method="Three-term Taylor", verbose=verbose)

E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init ≈ E_kin_lin_final atol=E_kin_lin_init*tol
@test E_kin_rot_init ≈ E_kin_rot_final
@test sim.grains[2].lin_pos ≈ grain2_pos_init

@info "Three-term Taylor scheme: allow_x_acc"
sim = deepcopy(sim_init)
tol = 0.02
sim.grains[2].allow_x_acc = true  # should influence result
Granular.run!(sim, temporal_integration_method="Three-term Taylor", verbose=verbose)

E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
@test E_kin_lin_init ≈ E_kin_lin_final atol=E_kin_lin_init*tol
@test E_kin_rot_init ≈ E_kin_rot_final
@test sim.grains[2].lin_pos[1] > grain2_pos_init[1]

#=
@info "# Test stability under collision with fixed particles different allow_*_acc"
r = 10.
i = 1
for tensile_strength in [0.0, 200e3]
    for angle in range(0, 2π, 7)
        for allow_x_acc in [false, true]
            for allow_y_acc in [false, true]
                @info "Test $i"
                @info "Contact angle: $angle rad"
                @info "allow_x_acc = $allow_x_acc"
                @info "allow_y_acc = $allow_y_acc"
                @info "tensile_strength = $tensile_strength Pa"

                sim = Granular.createSimulation()
                sim.id = "test-$i-$allow_x_acc-$allow_y_acc-C=$tensile_strength"
                Granular.addGrainCylindrical!(sim, [0., 0.], r, 1., verbose=verbose)
                Granular.addGrainCylindrical!(sim, [2.0*r*cos(angle), 2.0*r*sin(angle)],
                                              r, 1., verbose=verbose)
                sim.grains[1].lin_vel = r/10.0 .* [cos(angle), sin(angle)]

                E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
                E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)
                grain1_pos_init = sim.grains[1].lin_pos
                grain2_pos_init = sim.grains[2].lin_pos

                sim.grains[1].fixed = true
                sim.grains[2].fixed = true

                sim.grains[1].allow_x_acc = allow_x_acc
                sim.grains[2].allow_x_acc = allow_x_acc
                sim.grains[1].allow_y_acc = allow_y_acc
                sim.grains[2].allow_y_acc = allow_y_acc

                sim.grains[1].tensile_strength = tensile_strength
                sim.grains[2].tensile_strength = tensile_strength

                Granular.setTotalTime!(sim, 20.0)
                Granular.setTimeStep!(sim, epsilon=0.07)
                sim_init = deepcopy(sim)

                @info "TY3"
                sim = deepcopy(sim_init)
                tol = 0.02
                Granular.setOutputFileInterval!(sim, 1.0)
                Granular.run!(sim, temporal_integration_method="Three-term Taylor",
                              verbose=verbose)
                Granular.render(sim)
                E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
                E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
                @test E_kin_lin_init ≈ E_kin_lin_final atol=E_kin_lin_init*tol

                i += 1
            end
        end
    end
end
=#
