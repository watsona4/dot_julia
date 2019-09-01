#/usr/bin/env julia
import Granular

#### Create a loose granular assemblage and let it settle at towards -y
sim = Granular.createSimulation(id="sedimentation")

# Generate 10 grains along x and 25 grains along y, with radii between 0.2 and
# 1.0 m.
Granular.regularPacking!(sim, [7, 25], 0.02, 0.2,
                         tiling="triangular",
                         padding_factor=0.1)

# Visualize the grain-size distribution
#Granular.plotGrainSizeDistribution(sim)

# Create a grid for contact searching spanning the extent of the grains in the
# simulation
Granular.fitGridToGrains!(sim, sim.ocean)

# Make the grid boundaries impermeable for the grains, which 
Granular.setGridBoundaryConditions!(sim.ocean, "impermeable")

# Add gravitational acceleration to all grains
g = [0., -9.8]
for grain in sim.grains
    Granular.addBodyForce!(grain, grain.mass*g)
end

# Automatically set the computational time step based on grain sizes and
# properties
Granular.setTimeStep!(sim)

# Set the total simulation time for this step [s]
Granular.setTotalTime!(sim, 10.0)

# Set the interval in model time between simulation files [s]
Granular.setOutputFileInterval!(sim, 0.2)

# Start the simulation
Granular.run!(sim)

# Try to render the simulation if `pvpython` is installed on the system
Granular.render(sim, trim=false)
