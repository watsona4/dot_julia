#!/usr/bin/env julia
import Granular

# Create the simulation object which, among other things, will hold all
# imformation on the simulated grains.  You can call this object whatever you
# want, but in this documentation we will use the name `sim`.
sim = Granular.createSimulation(id="two-grains")


# Add a grain to the simulation object, having the position (0,0) in x-y space,
# a radius of 0.1 m, and a thickness of 0.05 m.
Granular.addGrainCylindrical!(sim, [0.0, 0.0], 0.1, 0.05)

# Add a second grain, placed further down +x.
Granular.addGrainCylindrical!(sim, [0.5, 0.0], 0.1, 0.05)

# Set a velocity of 0.5 m/s along +x for the first grain, to make it bump into
# the second grain.
sim.grains[1].lin_vel[1:2] = [1.0, 0.0]

# Before we can run the simulation, we need to specify the computational time
# step, how often to produce output files for visualization, and for how long to
# run the simulation in model time [s]:
Granular.setTimeStep!(sim)
Granular.setOutputFileInterval!(sim, 0.05)
Granular.setTotalTime!(sim, 1.0)

# Let's save the total kinetic energy before the simulation:
E_kin_before = Granular.totalGrainKineticTranslationalEnergy(sim)

# We can now run the simulation in a single call:
Granular.run!(sim)

# The kinetic energy after:
E_kin_after = Granular.totalGrainKineticTranslationalEnergy(sim)

# Report these values to console
@info "Kinetic energy before: $E_kin_before J"
@info "Kinetic energy after:  $E_kin_after J"

Granular.render(sim, animation=true)
