export setTotalTime!
"""
    setTotalTime!(simulation::Simulation, t::Float64)

Sets the total simulation time of the `simulation` object to `t`, with parameter 
value checks.
"""
function setTotalTime!(simulation::Simulation, t::Float64)
    if t <= 0.0
        error("Total time should be a positive value (t = $t s)")
    end
    simulation.time_total = t
    nothing
end

export setCurrentTime!
"""
    setCurrentTime!(simulation::Simulation, t::Float64)

Sets the current simulation time of the `simulation` object to `t`, with 
parameter value checks.
"""
function setCurrentTime!(simulation::Simulation, t::Float64)
    if t <= 0.0
        error("Current time should be a positive value (t = $t s)")
    end
    simulation.time = t
    nothing
end

export incrementCurrentTime!
"""
    incrementCurrentTime!(simulation::Simulation, t::Float64)

Sets the current simulation time of the `simulation` object to `t`, with 
parameter value checks.
"""
function incrementCurrentTime!(simulation::Simulation, t::Float64)
    if t <= 0.0
        error("Current time increment should be a positive value (t = $t s)")
    end
    simulation.time += t
    simulation.file_time_since_output_file += t
    nothing
end

export setOutputFileInterval!
"""
   setOutputFileInterval!(simulation::Simulation, t::Float64)

Sets the simulation-time interval between output files are written to disk.  If 
this value is zero or negative, no output files will be written.
"""
function setOutputFileInterval!(simulation::Simulation, t::Float64; 
    verbose=true)
    if t <= 0.0 && verbose
        @info "No output files will be written"
    end
    simulation.file_time_step = t
    nothing
end

export disableOutputFiles!
"Disables the write of output files to disk during a simulation."
function disableOutputFiles!(simulation::Simulation)
    simulation.file_time_step = 0.0
    nothing
end

export checkTimeParameters
"Checks if simulation temporal parameters are of reasonable values."
function checkTimeParameters(simulation::Simulation; single_step::Bool=false)
    if !single_step && (simulation.time_total <= 0.0 || simulation.time_total <= 
                        simulation.time)
        error("Total time should be positive and larger than current " *
            "time.\n  t_total = $(simulation.time_total) s, " *
            "t = $(simulation.time) s")
    end
    if simulation.time_step <= 0.0
        error("Time step should be positive (t = $(simulation.time_step))")
    end
    nothing
end

export findSmallestGrainMass
"Finds the smallest mass of all grains in a simulation.  Used to determine 
the optimal time step length."
function findSmallestGrainMass(simulation::Simulation)
    m_min = 1e20
    i_min = -1
    for i=1:length(simulation.grains)
        @inbounds grain = simulation.grains[i]
        if grain.mass < m_min
            m_min = grain.mass
            i_min = i
        end
    end
    return m_min, i_min
end

export findLargestGrainStiffness
"Finds the largest elastic stiffness of all grains in a simulation.  Used to 
determine the optimal time step length."
function findLargestGrainStiffness(simulation::Simulation)
    k_n_max = 0.
    k_t_max = 0.
    i_n_max = -1
    i_t_max = -1
    for i=1:length(simulation.grains)

        @inbounds grain = simulation.grains[i]

        if grain.youngs_modulus > 0.
            k_n = grain.youngs_modulus*grain.thickness  # A = h*r
            k_t = k_n * 2. * (1. - grain.poissons_ratio^2.)/
                ((2. - grain.poissons_ratio) * (1. + grain.poissons_ratio))
        else
            k_n = grain.contact_stiffness_normal
            k_t = grain.contact_stiffness_tangential
        end

        if k_n > k_n_max
            k_n_max = k_n
            i_n_max = i
        end
        if k_t > k_t_max
            k_t_max = k_t
            i_t_max = i
        end
    end
    return k_n_max, k_t_max, i_n_max, i_t_max
end

export setTimeStep!
"""
    setTimeStep!(simulation[, epsilon, verbose])

Find the computational time step length suitable given the grain radii, contact
stiffnesses, and grain density. Uses the scheme by Radjaii et al. 2011.

# Arguments
* `simulation::Simulation`: the simulation object to modify.
* `epsilon::Float64=0.07`: safety factor in the time step scheme. Larger values
    are more likely to cause unstable behavior than smaller values.
* `verbose::Bool=true`: display the resultant time step in the console.
"""
function setTimeStep!(simulation::Simulation;
                      epsilon::Float64=0.07, verbose::Bool=true)

    if length(simulation.grains) < 1
        error("At least 1 grain is needed to find the computational time step.")
    end

    k_n_max, k_t_max, _, _ = findLargestGrainStiffness(simulation)
    m_min, _ = findSmallestGrainMass(simulation)

    simulation.time_step = epsilon/(sqrt(maximum([k_n_max, k_t_max])/m_min))

    if simulation.time_step <= 1.0e-20
        error("Time step too small or negative ($(simulation.time_step) s)")
    end

    if verbose
        @info "Time step length t=$(simulation.time_step) s"
    end
    nothing
end

export resetTime!
"""
    resetTime!(simulation)

Reset the current time to zero, and reset output file counters in order to
restart a simulation.  This function does not overwrite the time step
(`Simulation.time_step`), the output
file interval (`Simulation.file_time_step`), or the total simulation time
(`Simulation.time_total`).

# Arguments
* `simulation::Simulation`: the simulation object for which to reset the
    temporal parameters.
"""
function resetTime!(sim::Simulation)
    sim.time_iteration = 0
    sim.time = 0.0
    sim.file_number = 0
    sim.file_time_since_output_file = 0.
end

