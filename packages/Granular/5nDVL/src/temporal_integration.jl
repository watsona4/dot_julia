
export updateGrainKinematics!
"""
    updateGrainKinematics!(simulation::Simulation[,
                             method::String = "Three-term Taylor"])

Update the grain kinematic parameters using a temporal integration scheme,
the current force and torque balance, and gravitational acceleration.  If the
simulation contains a grid with periodic boundaries, affected grain positions
are adjusted accordingly.

# Arguments
* `simulation::Simulation`: update the grain positions in this object 
    according to temporal integration of length `simulation.time_step`.
* `method::String = "Three-term Taylor"`: the integration method to use.  
    Available methods are "Two-term Taylor" and "Three-term Taylor".  The 
    three-term Taylor expansion is slightly more computationally expensive than 
    the two-term Taylor expansion, but offers an order-of-magnitude increase in 
    precision of grain positions.  The two-term expansion can obtain similar 
    precision if the time step is 1/10 the length.
"""
function updateGrainKinematics!(simulation::Simulation;
                                method::String = "Three-term Taylor")

    if method == "Two-term Taylor"
        for grain in simulation.grains
            if !grain.enabled
                continue
            end
            updateGrainKinematicsTwoTermTaylor!(grain, simulation)
        end
    elseif method == "Three-term Taylor"
        for grain in simulation.grains
            if !grain.enabled
                continue
            end
            updateGrainKinematicsThreeTermTaylor!(grain, simulation)
        end
    else
        error("Unknown integration method '$method'")
    end
    moveGrainsAcrossPeriodicBoundaries!(simulation)
    reflectGrainsFromImpermeableBoundaries!(simulation)
    nothing
end

export updateGrainKinematicsTwoTermTaylor!
"""
Use a two-term Taylor expansion for integrating the kinematic degrees of freedom 
for a `grain`.
"""
function updateGrainKinematicsTwoTermTaylor!(grain::GrainCylindrical,
                                             simulation::Simulation)
    grain.lin_acc = grain.force/grain.mass
    grain.ang_acc = grain.torque/grain.moment_of_inertia

    if grain.fixed
        if !grain.allow_x_acc
            grain.lin_acc[1] = 0.
        end
        if !grain.allow_y_acc
            grain.lin_acc[2] = 0.
        end
        if !grain.allow_z_acc
            grain.lin_acc[3] = 0.
        end
        grain.ang_acc = zeros(3)
    elseif !grain.rotating
        grain.ang_acc = zeros(3)
    end

    grain.lin_pos +=
        grain.lin_vel * simulation.time_step +
        0.5*grain.lin_acc * simulation.time_step^2.0

    grain.lin_disp +=
        grain.lin_vel * simulation.time_step +
        0.5*grain.lin_acc * simulation.time_step^2.0

    grain.ang_pos +=
        grain.ang_vel * simulation.time_step +
        0.5*grain.ang_acc * simulation.time_step^2.0

    grain.lin_vel += grain.lin_acc * simulation.time_step
    grain.ang_vel += grain.ang_acc * simulation.time_step
    nothing
end

export updateGrainKinematicsThreeTermTaylor!
"""
Use a three-term Taylor expansion for integrating the kinematic degrees of 
freedom for a `grain`.
"""
function updateGrainKinematicsThreeTermTaylor!(grain::GrainCylindrical,
                                               simulation::Simulation)

    if simulation.time_iteration == 0
        lin_acc_0 = zeros(3)
        ang_acc_0 = zeros(3)
    else
        lin_acc_0 = grain.lin_acc
        ang_acc_0 = grain.ang_acc
    end

    grain.lin_acc = grain.force/grain.mass
    grain.ang_acc = grain.torque/grain.moment_of_inertia

    if grain.fixed
        if !grain.allow_x_acc
            grain.lin_acc[1] = 0.
        end
        if !grain.allow_y_acc
            grain.lin_acc[2] = 0.
        end
        if !grain.allow_z_acc
            grain.lin_acc[3] = 0.
        end
        grain.ang_acc = zeros(3)
    elseif !grain.rotating
        grain.ang_acc = zeros(3)
    end

    # Temporal gradient in acceleration using backwards differences
    d_lin_acc_dt = (grain.lin_acc - lin_acc_0)/simulation.time_step
    d_ang_acc_dt = (grain.ang_acc - ang_acc_0)/simulation.time_step

    grain.lin_pos +=
        grain.lin_vel * simulation.time_step +
        0.5 * grain.lin_acc * simulation.time_step^2. +
        1. / 6. * d_lin_acc_dt * simulation.time_step^3.

    grain.lin_disp +=
        grain.lin_vel * simulation.time_step +
        0.5 * grain.lin_acc * simulation.time_step^2. +
        1. / 6. * d_lin_acc_dt * simulation.time_step^3.

    grain.ang_pos +=
        grain.ang_vel * simulation.time_step +
        0.5 * grain.ang_acc * simulation.time_step^2. +
        1. / 6. * d_ang_acc_dt * simulation.time_step^3.

    grain.lin_vel += grain.lin_acc * simulation.time_step +
        0.5 * d_lin_acc_dt * simulation.time_step^2.
    grain.ang_vel += grain.ang_acc * simulation.time_step +
        0.5 * d_ang_acc_dt * simulation.time_step^2.
    nothing
end

export updateWallKinematics!
"""
    updateWallKinematics!(simulation::Simulation[,
                          method::String = "Three-term Taylor"])

Update the wall kinematic parameters using a temporal integration scheme,
the current force and torque balance, and gravitational acceleration.  If the
simulation contains a grid with periodic boundaries, affected wall positions
are adjusted accordingly.

# Arguments
* `simulation::Simulation`: update the wall positions in this object 
    according to temporal integration of length `simulation.time_step`.
* `method::String = "Three-term Taylor"`: the integration method to use.  
    Available methods are "Two-term Taylor" and "Three-term Taylor".  The 
    three-term Taylor expansion is slightly more computationally expensive than 
    the two-term Taylor expansion, but offers an order-of-magnitude increase in 
    precision of wall positions.  The two-term expansion can obtain similar 
    precision if the time step is 1/10 the length.
"""
function updateWallKinematics!(simulation::Simulation;
                                method::String = "Three-term Taylor")

    if method == "Two-term Taylor"
        for wall in simulation.walls
            if wall.bc == "fixed"
                continue
            end
            updateWallKinematicsTwoTermTaylor!(wall, simulation)
        end
    elseif method == "Three-term Taylor"
        for wall in simulation.walls
            if wall.bc == "fixed"
                continue
            end
            updateWallKinematicsThreeTermTaylor!(wall, simulation)
        end
    else
        error("Unknown integration method '$method'")
    end
    nothing
end

export updateWallKinematicsTwoTermTaylor!
"""
    updateWallKinematicsTwoTermTaylor!(wall, simulation)

Use a two-term Taylor expansion for integrating the kinematic degrees of freedom 
for a `wall`.
"""
function updateWallKinematicsTwoTermTaylor!(wall::WallLinearFrictionless,
                                            simulation::Simulation)
    if wall.bc == "fixed"
        return nothing
    elseif wall.bc == "velocity"
        wall.acc = 0.0
    elseif wall.bc == "normal stress"
        wall.acc = (wall.force + wall.normal_stress*wall.surface_area)/wall.mass
    else
        error("wall boundary condition was not understood ($(wall.bc))")
    end

    wall.pos +=
        wall.vel * simulation.time_step +
        0.5*wall.acc * simulation.time_step^2.0

    wall.vel += wall.acc * simulation.time_step
    nothing
end


export updateWallKinematicsThreeTermTaylor!
"""
    updateWallKinematicsThreeTermTaylor!(wall, simulation)

Use a two-term Taylor expansion for integrating the kinematic degrees of freedom 
for a `wall`.
"""
function updateWallKinematicsThreeTermTaylor!(wall::WallLinearFrictionless,
                                              simulation::Simulation)
    if simulation.time_iteration == 0
        acc_0 = 0.
    else
        acc_0 = wall.acc
    end

    if wall.bc == "fixed"
        return nothing
    elseif wall.bc == "velocity"
        wall.acc = 0.0
    elseif wall.bc == "normal stress"
        wall.acc = (wall.force + wall.normal_stress*wall.surface_area)/wall.mass
    else
        error("wall boundary condition was not understood ($(wall.bc))")
    end

    # Temporal gradient in acceleration using backwards differences
    d_acc_dt = (wall.acc - acc_0)/simulation.time_step

    wall.pos +=
        wall.vel * simulation.time_step +
        0.5*wall.acc * simulation.time_step^2.0 +
        1.0/6.0 * d_acc_dt * simulation.time_step^3.0

    wall.vel += wall.acc * simulation.time_step +
        0.5 * d_acc_dt * simulation.time_step^2.0

    nothing
end
