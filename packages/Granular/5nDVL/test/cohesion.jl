#!/usr/bin/env julia
using Test
import Granular

# Check for conservation of kinetic energy (=momentum) during a normal collision 
# between two ice cylindrical grains 

verbose=false

sim_init = Granular.createSimulation()
Granular.addGrainCylindrical!(sim_init, [0., 0.], 10., 1.)
Granular.addGrainCylindrical!(sim_init, [18., 0.], 10., 1.)
sim_init.grains[1].youngs_modulus = 1e-5  # repulsion is negligible
sim_init.grains[2].youngs_modulus = 1e-5  # repulsion is negligible
Granular.setTimeStep!(sim_init, verbose=verbose)

@info "# Check contact age scheme"
sim = deepcopy(sim_init)
Granular.setTotalTime!(sim, 10.)
sim.time_step = 1.
Granular.run!(sim, verbose=verbose)
Granular.removeSimulationFiles(sim)
@test sim.grains[1].contact_age[1] ≈ sim.time

@info "# Check if bonds add tensile strength"
sim = Granular.createSimulation(id="cohesion")
Granular.addGrainCylindrical!(sim, [0., 0.], 10., 1., tensile_strength=500e3)
Granular.addGrainCylindrical!(sim, [20.1, 0.], 10., 1., tensile_strength=500e3)
sim.grains[1].lin_vel[1] = 0.1
Granular.setTimeStep!(sim)
Granular.setTotalTime!(sim, 10.)
Granular.run!(sim, verbose=verbose)
Granular.removeSimulationFiles(sim)
@test sim.grains[1].lin_vel[1] > 0.
@test sim.grains[1].lin_vel[2] ≈ 0.
@test sim.grains[2].lin_vel[1] > 0.
@test sim.grains[2].lin_vel[2] ≈ 0.
@test sim.grains[1].ang_vel ≈ zeros(3)
@test sim.grains[2].ang_vel ≈ zeros(3)

@info "# Add shear strength and test bending resistance (one grain rotating)"
sim = Granular.createSimulation(id="cohesion")
Granular.addGrainCylindrical!(sim, [0., 0.], 10.1, 1., tensile_strength=500e3,
    shear_strength=500e3)
Granular.addGrainCylindrical!(sim, [20., 0.], 10., 1., tensile_strength=500e3,
    shear_strength=500e3)
sim.grains[1].ang_vel[3] = 0.1
Granular.findContacts!(sim) # make sure contact is registered
sim.grains[1].contact_radius=10.0 # decrease radius so there isn't compression
E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)
Granular.setTimeStep!(sim)
Granular.setTotalTime!(sim, 5.)
#Granular.setOutputFileInterval!(sim, 0.1)
Granular.run!(sim, verbose=verbose)
Granular.removeSimulationFiles(sim)
@test sim.grains[1].lin_vel[1] ≈ 0.
@test sim.grains[1].lin_vel[2] ≈ 0.
@test sim.grains[2].lin_vel[1] ≈ 0.
@test sim.grains[2].lin_vel[2] ≈ 0.
@test sim.grains[1].ang_vel[3] != 0.
@test sim.grains[2].ang_vel[3] != 0.
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
E_therm_final = Granular.totalGrainThermalEnergy(sim)
@test E_kin_lin_init ≈ E_kin_lin_final
@test E_kin_rot_init > E_kin_rot_final + E_therm_final

@info "# Add shear strength and test bending resistance (one grain rotating)"
sim = Granular.createSimulation(id="cohesion")
Granular.addGrainCylindrical!(sim, [0., 0.], 10.1, 1., tensile_strength=500e3,
    shear_strength=500e3)
Granular.addGrainCylindrical!(sim, [20., 0.], 10., 1., tensile_strength=500e3,
    shear_strength=500e3)
sim.grains[2].ang_vel[3] = 0.1
Granular.findContacts!(sim) # make sure contact is registered
sim.grains[1].contact_radius=10.0 # decrease radius so there isn't compression
E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)
Granular.setTimeStep!(sim)
Granular.setTotalTime!(sim, 5.)
#Granular.setOutputFileInterval!(sim, 0.1)
Granular.run!(sim, verbose=verbose)
Granular.removeSimulationFiles(sim)
@test sim.grains[1].lin_vel[1] ≈ 0.
@test sim.grains[1].lin_vel[2] ≈ 0.
@test sim.grains[2].lin_vel[1] ≈ 0.
@test sim.grains[2].lin_vel[2] ≈ 0.
@test sim.grains[1].ang_vel[3] != 0.
@test sim.grains[2].ang_vel[3] != 0.
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
E_therm_final = Granular.totalGrainThermalEnergy(sim)
@test E_kin_lin_init ≈ E_kin_lin_final
@test E_kin_rot_init > E_kin_rot_final + E_therm_final

@info "# Add shear strength and test bending resistance (both grains rotating)"
sim = Granular.createSimulation(id="cohesion")
Granular.addGrainCylindrical!(sim, [0., 0.], 10.0000001, 1., tensile_strength=500e3,
    shear_strength=500e3)
Granular.addGrainCylindrical!(sim, [20., 0.], 10., 1., tensile_strength=500e3,
    shear_strength=500e3)
sim.grains[1].ang_vel[3] = 0.1
sim.grains[2].ang_vel[3] = -0.1
Granular.findContacts!(sim) # make sure contact is registered
sim.grains[1].contact_radius=10.0 # decrease radius so there isn't compression
E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)
Granular.setTimeStep!(sim)
Granular.setTotalTime!(sim, 5.)
#Granular.setOutputFileInterval!(sim, 0.1)
Granular.run!(sim, verbose=verbose)
Granular.removeSimulationFiles(sim)
@test sim.grains[1].lin_vel[1] ≈ 0.
@test sim.grains[1].lin_vel[2] ≈ 0.
@test sim.grains[2].lin_vel[1] ≈ 0.
@test sim.grains[2].lin_vel[2] ≈ 0.
@test sim.grains[1].ang_vel[3] != 0.
@test sim.grains[2].ang_vel[3] != 0.
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
E_therm_final = Granular.totalGrainThermalEnergy(sim)
@test E_kin_lin_init ≈ E_kin_lin_final
@test E_kin_rot_init > E_kin_rot_final + E_therm_final

@info "# Break bond through bending I"
sim = Granular.createSimulation(id="cohesion")
Granular.addGrainCylindrical!(sim, [0., 0.], 10.0000001, 1., tensile_strength=500e3,
    shear_strength=500e3)
Granular.addGrainCylindrical!(sim, [20., 0.], 10., 1., tensile_strength=500e3,
    shear_strength=500e3)
sim.grains[1].ang_vel[3] = 100
sim.grains[2].ang_vel[3] = -100
Granular.findContacts!(sim) # make sure contact is registered
sim.grains[1].contact_radius=10.0 # decrease radius so there isn't compression
E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)
Granular.setTimeStep!(sim)
Granular.setTotalTime!(sim, 5.)
#Granular.setOutputFileInterval!(sim, 0.1)
Granular.run!(sim, verbose=verbose)
Granular.removeSimulationFiles(sim)
@test sim.grains[1].lin_vel[1] ≈ 0.
@test sim.grains[1].lin_vel[2] ≈ 0.
@test sim.grains[2].lin_vel[1] ≈ 0.
@test sim.grains[2].lin_vel[2] ≈ 0.
@test sim.grains[1].ang_vel[3] != 0.
@test sim.grains[2].ang_vel[3] != 0.
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
E_therm_final = Granular.totalGrainThermalEnergy(sim)
@test E_kin_lin_init ≈ E_kin_lin_final
@test sim.grains[1].n_contacts == 0
@test sim.grains[2].n_contacts == 0

@info "# Break bond through bending II"
sim = Granular.createSimulation(id="cohesion")
Granular.addGrainCylindrical!(sim, [0., 0.], 10.1, 1., tensile_strength=500e3,
    shear_strength=50e3)
Granular.addGrainCylindrical!(sim, [20., 0.], 10., 1., tensile_strength=500e3,
    shear_strength=50e3)
sim.grains[1].ang_vel[3] = 100
sim.grains[2].ang_vel[3] = 0.0
Granular.findContacts!(sim) # make sure contact is registered
sim.grains[1].contact_radius=10.0 # decrease radius so there isn't compression
E_kin_lin_init = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_init = Granular.totalGrainKineticRotationalEnergy(sim)
Granular.setTimeStep!(sim)
Granular.setTotalTime!(sim, 5.)
#Granular.setOutputFileInterval!(sim, 0.1)
Granular.run!(sim, verbose=verbose)
Granular.removeSimulationFiles(sim)
@test sim.grains[1].lin_vel[1] ≈ 0.
@test sim.grains[1].lin_vel[2] ≈ 0.
@test sim.grains[2].lin_vel[1] ≈ 0.
@test sim.grains[2].lin_vel[2] ≈ 0.
@test sim.grains[1].ang_vel[3] != 0.
@test sim.grains[2].ang_vel[3] != 0.
E_kin_lin_final = Granular.totalGrainKineticTranslationalEnergy(sim)
E_kin_rot_final = Granular.totalGrainKineticRotationalEnergy(sim)
E_therm_final = Granular.totalGrainThermalEnergy(sim)
@test E_kin_lin_init ≈ E_kin_lin_final
@test sim.grains[1].n_contacts == 0
@test sim.grains[2].n_contacts == 0
