#/usr/bin/env julia
ENV["MPLBACKEND"] = "Agg"
import Granular
import JLD2
import PyPlot

################################################################################
#### SIMULATION PARAMETERS                                                     #
################################################################################
let

# Common simulation identifier
id_prefix = "test0"

# Gravitational acceleration vector (cannot be zero; required for Step 1)
g = [0., -9.8]

# Grain package geometry during initialization
nx = 10                         # Grains along x (horizontal)
ny = 50                         # Grains along y (vertical)

# Grain-size parameters
r_min = 0.03                    # Min. grain radius [m]
r_max = 0.1                     # Max. grain radius [m]
gsd_type = "powerlaw"           # "powerlaw" or "uniform" sizes between r_min and r_max
gsd_powerlaw_exponent = -1.8    # GSD power-law exponent
gsd_seed = 1                    # Value to seed random-size generation

# Grain mechanical properties
youngs_modulus = 2e7            # Elastic modulus [Pa]
poissons_ratio = 0.185          # Shear-stiffness ratio [-]
tensile_strength = 0.0          # Inter-grain bond strength [Pa]
contact_dynamic_friction = 0.4  # Coulomb-frictional coefficient [-]
rotating = true                 # Allow grain rotation

# Normal stress for the consolidation and shear [Pa]
N = 20e3

# Shear velocity to apply to the top grains [m/s]
vel_shear = 0.5

# Simulation duration of individual steps [s]
t_init  = 2.0
t_cons  = 2.5
t_shear = 5.0

################################################################################
#### Step 1: Create a loose granular assemblage and let it settle at -y        #
################################################################################
sim = Granular.createSimulation(id="$(id_prefix)-init")

Granular.regularPacking!(sim, [nx, ny], r_min, r_max,
                         size_distribution=gsd_type,
                         size_distribution_parameter=gsd_powerlaw_exponent,
                         seed=gsd_seed)

# Set grain mechanical properties
for grain in sim.grains
    grain.youngs_modulus = youngs_modulus
    grain.poissons_ratio = poissons_ratio
    grain.tensile_strength = tensile_strength
    grain.contact_dynamic_friction = contact_dynamic_friction
    grain.rotating = rotating
end

# Create a grid for contact searching spanning the extent of the grains
Granular.fitGridToGrains!(sim, sim.ocean)

# Make the top and bottom boundaries impermeable, and the side boundaries
# periodic, which will come in handy during shear
Granular.setGridBoundaryConditions!(sim.ocean, "impermeable", "north south",
                                    verbose=false)
Granular.setGridBoundaryConditions!(sim.ocean, "periodic", "east west")

# Add gravitational acceleration to all grains and disable ocean-grid drag.
# Also add viscous energy dissipation between grains, which is disabled before
# consolidation and shear.
for grain in sim.grains
    Granular.addBodyForce!(grain, grain.mass*g)
    Granular.disableOceanDrag!(grain)
    grain.contact_viscosity_normal = 1e4  # N/(m/s)
end

# Automatically set the computational time step based on grain sizes and
# properties
Granular.setTimeStep!(sim)

# Set the total simulation time for this step [s]
# This value may need tweaking if grain sizes or numbers are adjusted.
Granular.setTotalTime!(sim, t_init)

# Set the interval in model time between simulation files [s]
Granular.setOutputFileInterval!(sim, .02)

# Visualize the grain-size distribution
Granular.plotGrainSizeDistribution(sim)

# Start the simulation
Granular.run!(sim)

# Try to render the simulation if `pvpython` is installed on the system
Granular.render(sim, trim=false)

# Save the simulation state to disk in case we need to reuse the current state
Granular.writeSimulation(sim)

# Also copy the simulation in memory, in case we want to loop over different
# normal stresses below:
sim_init = deepcopy(sim)


################################################################################
#### Step 2: Consolidate the previous output under a constant normal stress    #
################################################################################

# Rename the simulation so we don't overwrite output from the previous step
sim.id = "$(id_prefix)-cons-N$(N)Pa"

# Set all linear and rotational velocities to zero
Granular.zeroKinematics!(sim)

# Add a dynamic wall to the top which adds a normal stress downwards.  The
# normal of this wall is downwards, and we place it at the top of the granular
# assemblage.  Here, the inter-grain viscosity is also removed.
y_top = -Inf
for grain in sim.grains
    grain.contact_viscosity_normal = 0.
    if y_top < grain.lin_pos[2] + grain.contact_radius
        y_top = grain.lin_pos[2] + grain.contact_radius
    end
end
Granular.addWallLinearFrictionless!(sim, [0., 1.], y_top,
                                    bc="normal stress", normal_stress=-N,
                                    contact_viscosity_normal=1e3)
@info "Placing top wall at y=$y_top"

# Resize the grid to span the current state
Granular.fitGridToGrains!(sim, sim.ocean)

# Lock the grains at the very bottom so that the lower boundary is rough
y_bot = Inf
for grain in sim.grains
    if y_bot > grain.lin_pos[2] - grain.contact_radius
        y_bot = grain.lin_pos[2] - grain.contact_radius
    end
end
fixed_thickness = 2. * r_max
for grain in sim.grains
    if grain.lin_pos[2] <= fixed_thickness
        grain.fixed = true  # set x and y acceleration to zero
    end
end

# Set current time to zero and reset output file counter
Granular.resetTime!(sim)

# Set the simulation time to run the consolidation for
Granular.setTotalTime!(sim, t_cons)

# Run the consolidation experiment, and monitor top wall position over time
time = Float64[]
compaction = Float64[]
effective_normal_stress = Float64[]
while sim.time < sim.time_total

    for i=1:100  # run for 100 steps before measuring shear stress and dilation
        Granular.run!(sim, single_step=true)
    end

    append!(time, sim.time)
    append!(compaction, sim.walls[1].pos)
    append!(effective_normal_stress, Granular.getWallNormalStress(sim))

end
defined_normal_stress = ones(length(effective_normal_stress)) *
    Granular.getWallNormalStress(sim, stress_type="effective")
PyPlot.subplot(211)
PyPlot.subplots_adjust(hspace=0.0)
ax1 = PyPlot.gca()
PyPlot.setp(ax1[:get_xticklabels](),visible=false) # Disable x tick labels
PyPlot.plot(time, compaction)
PyPlot.ylabel("Top wall height [m]")
PyPlot.subplot(212, sharex=ax1)
PyPlot.plot(time, defined_normal_stress)
PyPlot.plot(time, effective_normal_stress)
PyPlot.xlabel("Time [s]")
PyPlot.ylabel("Normal stress [Pa]")
PyPlot.savefig(sim.id * "-time_vs_compaction-stress.pdf")
PyPlot.clf()

# Try to render the simulation if `pvpython` is installed on the system
Granular.render(sim, trim=false)

# Save the simulation state to disk in case we need to reuse the consolidated
# state (e.g. different shear velocities below)
Granular.writeSimulation(sim)

# Also copy the simulation in memory, in case we want to loop over different
# normal stresses below:
sim_cons = deepcopy(sim)


################################################################################
#### Step 3: Shear the consolidated assemblage with a constant velocity        #
################################################################################

# Rename the simulation so we don't overwrite output from the previous step
sim.id = "$(id_prefix)-shear-N$(N)Pa-vel_shear$(vel_shear)m-s"

# Set all linear and rotational velocities to zero
Granular.zeroKinematics!(sim)

# Set current time to zero and reset output file counter
Granular.resetTime!(sim)

# Set the simulation time to run the shear experiment for
Granular.setTotalTime!(sim, t_shear)

# Run the shear experiment
time = Float64[]
shear_stress = Float64[]
shear_strain = Float64[]
dilation = Float64[]
thickness_initial = sim.walls[1].pos - y_bot
x_min = +Inf
x_max = -Inf
for grain in sim.grains
    if x_min > grain.lin_pos[1] - grain.contact_radius
        x_min = grain.lin_pos[1] - grain.contact_radius
    end
    if x_max < grain.lin_pos[1] + grain.contact_radius
        x_max = grain.lin_pos[1] + grain.contact_radius
    end
end
surface_area = (x_max - x_min)
shear_force = 0.
while sim.time < sim.time_total

    # Prescribe the shear velocity to the uppermost grains
    for grain in sim.grains
        if grain.lin_pos[2] >= sim.walls[1].pos - fixed_thickness
            grain.fixed = true
            grain.allow_y_acc = true
            grain.lin_vel[1] = vel_shear
        elseif grain.lin_pos[2] > fixed_thickness  # do not free bottom grains
            grain.fixed = false
        end
    end

    for i=1:100  # run for 100 steps before measuring shear stress and dilation
        Granular.run!(sim, single_step=true)
    end

    append!(time, sim.time)

    # Determine the current shear stress
    shear_force = 0.
    for grain in sim.grains
        if grain.fixed && grain.allow_y_acc
            shear_force += -grain.force[1]
        end
    end
    append!(shear_stress, shear_force/surface_area)

    # Determine the current shear strain
    append!(shear_strain, sim.time*vel_shear/thickness_initial)

    # Determine the current dilation
    append!(dilation, (sim.walls[1].pos - y_bot)/thickness_initial)

end

# Try to render the simulation if `pvpython` is installed on the system
Granular.render(sim, trim=false)

# Save the simulation state to disk in case we need to reuse the sheared state
Granular.writeSimulation(sim)

# Plot time vs. shear stress and dilation
PyPlot.subplot(211)
PyPlot.subplots_adjust(hspace=0.0)
ax1 = PyPlot.gca()
PyPlot.setp(ax1[:get_xticklabels](),visible=false) # Disable x tick labels
PyPlot.plot(time, shear_stress)
PyPlot.ylabel("Shear stress [Pa]")
PyPlot.subplot(212, sharex=ax1)
PyPlot.plot(time, dilation)
PyPlot.xlabel("Time [s]")
PyPlot.ylabel("Volumetric strain [-]")
PyPlot.savefig(sim.id * "-time_vs_shear-stress.pdf")
PyPlot.clf()

# Plot shear strain vs. shear stress and dilation
PyPlot.subplot(211)
PyPlot.subplots_adjust(hspace=0.0)
ax1 = PyPlot.gca()
PyPlot.setp(ax1[:get_xticklabels](),visible=false) # Disable x tick labels
PyPlot.plot(shear_strain, shear_stress)
PyPlot.ylabel("Shear stress [Pa]")
PyPlot.subplot(212, sharex=ax1)
PyPlot.plot(shear_strain, dilation)
PyPlot.xlabel("Shear strain [-]")
PyPlot.ylabel("Volumetric strain [-]")
PyPlot.savefig(sim.id * "-shear-strain_vs_shear-stress.pdf")
PyPlot.clf()

# Plot time vs. shear strain (boring when the shear experiment is rate controlled)
PyPlot.plot(time, shear_strain)
PyPlot.xlabel("Time [s]")
PyPlot.ylabel("Shear strain [-]")
PyPlot.savefig(sim.id * "-time_vs_shear-strain.pdf")
PyPlot.clf()
end
