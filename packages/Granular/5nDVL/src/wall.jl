## Manage dynamic walls in the model

export addWallLinearFrictionless!
"""
    function addWallLinear!(simulation, normal, pos[, bc, mass, thickness, 
                            normal_stress, vel, acc, force,
                            contact_viscosity_normal, verbose])

Creates and adds a linear (flat) and frictionless dynamic wall to a grain to a
simulation. Most of the arguments are optional, and come with default values.
The only required arguments are 
`simulation`, `normal`, `pos`, and `bc`.

# Arguments
* `simulation::Simulation`: the simulation object where the wall should be
    added to.
* `normal::Vector{Float64}`: 3d vector denoting the normal to the wall [m].  The
    wall will only interact in the opposite direction of this vector, so the
    normal vector should point in the direction of the grains. If a 2d vector is
    passed, the third (z) component is set to zero.
* `pos::Float64`: position along axis parallel to the normal vector [m].
* `bc::String="fixed"`: boundary condition, possible values are `"fixed"`
    (default), `"normal stress"`, or `"velocity"`.
* `mass::Float64=NaN`: wall mass, which is used if wall boundary conditions
    differs from `bc="fixed"`.  If the parameter is left to its default value,
    the wall mass is set to be equal the total mass of grains in the simulation.
    Units: [kg]
* `thickness::Float64=NaN`: wall thickness, which is used for determining wall
    surface area.  If the parameter is left to its default value, the wall
    thickness is set to be equal to the thickest grain in the simulation.
    Units: [m].
* `normal_stress::Float64=0.`: the wall normal stress when `bc == "normal
    stress"` [Pa].
* `vel::Float64=0.`: the wall velocity along the `normal` vector.  If the
    wall boundary condition is `bc = "velocity"` the wall will move according to
    this constant value.  If `bc = "normal stress"` the velocity will be a free
    parameter. Units: [m/s]
* `force::Float64=0.`: sum of normal forces on the wall from interaction with
    grains [N].
* `contact_viscosity_normal::Float64=0.`: viscosity to apply in parallel to
    elasticity in interactions between wall and particles [N/(m/s)]. When this
    term is larger than zero, the wall-grain interaction acts like a sink of
    kinetic energy.
* `verbose::Bool=true`: show verbose information during function call.

# Examples
The most basic example adds a new fixed wall to the simulation `sim`, with a 
wall-face normal of `[1., 0.]` (wall along *y* and normal to *x*), a position of
`1.5` meter:

```julia
Granular.addWallLinearFrictionless!(sim, [1., 0., 0.], 1.5)
```

The following example creates a wall with a velocity of 0.5 m/s towards *-y*:

```julia
Granular.addWallLinearFrictionless!(sim, [0., 1., 0.], 1.5,
                                    bc="velocity",
                                    vel=-0.5)
```

To create a wall parallel to the *y* axis pushing downwards with a constant
normal stress of 100 kPa, starting at a position of y = 3.5 m:

```julia
Granular.addWallLinearFrictionless!(sim, [0., 1., 0.], 3.5,
                                    bc="normal stress",
                                    normal_stress=100e3)
```
"""
function addWallLinearFrictionless!(simulation::Simulation,
                                    normal::Vector{Float64},
                                    pos::Float64;
                                    bc::String = "fixed",
                                    mass::Float64 = -1.,
                                    thickness::Float64 = -1.,
                                    surface_area::Float64 = -1.,
                                    normal_stress::Float64 = 0.,
                                    vel::Float64 = 0.,
                                    acc::Float64 = 0.,
                                    force::Float64 = 0.,
                                    contact_viscosity_normal::Float64 = 0.,
                                    verbose::Bool=true)

    # Check input values
    if length(normal) != 3
        normal = vecTo3d(normal)
    end

    if bc != "fixed" && bc != "velocity" && bc != "normal stress"
        error("Wall BC must be 'fixed', 'velocity', or 'normal stress'.")
    end

    if !(normal ≈ [1., 0., 0.]) && !(normal ≈ [0., 1., 0.])
        error("Currently only walls with normals orthogonal to the " *
              "coordinate system are allowed, i.e. normals parallel to the " *
              "x or y axes.  Accepted values for `normal` " *
              "are [1., 0., 0.] and [0., 1., 0.]. The passed normal was $normal")
    end

    # if not set, set wall mass to equal the mass of all grains.
    if mass < 0.
        if length(simulation.grains) < 1
            error("If wall mass is not specified, walls should be " *
                  "added after grains have been added to the simulation.")
        end
        mass = 0.
        for grain in simulation.grains
            mass += grain.mass
        end
        if verbose
            @info "Setting wall mass to total grain mass: $mass kg"
        end
    end

    # if not set, set wall thickness to equal largest grain thickness
    if thickness < 0.
        if length(simulation.grains) < 1
            error("If wall thickness is not specified, walls should " *
                  "be added after grains have been added to the simulation.")
        end
        thickness = -Inf
        for grain in simulation.grains
            if grain.thickness > thickness
                thickness = grain.thickness
            end
        end
        if verbose
            @info "Setting wall thickness to max grain thickness: $thickness m"
        end
    end

    # if not set, set wall surface area from the ocean grid
    if surface_area < 0. && bc != "fixed"
        if typeof(simulation.ocean.input_file) == Bool
            error("simulation.ocean must be set beforehand")
        end
        surface_area = getWallSurfaceArea(simulation, normal, thickness)
    end

    # Create wall object
    wall = WallLinearFrictionless(normal,
                                  pos,
                                  bc,
                                  mass,
                                  thickness,
                                  surface_area,
                                  normal_stress,
                                  vel,
                                  acc,
                                  force,
                                  contact_viscosity_normal)

    # Add to simulation object
    addWall!(simulation, wall, verbose)
    nothing
end

export getWallSurfaceArea
"""
    getWallSurfaceArea(simulation, wall_index)

Returns the surface area of the wall given the grid size and its index.

# Arguments
* `simulation::Simulation`: the simulation object containing the wall.
* `wall_index::Integer=1`: the wall number in the simulation object.
"""
function getWallSurfaceArea(sim::Simulation, wall_index::Integer)

    if sim.walls[wall_index].normal ≈ [1., 0., 0.]
        return (sim.ocean.yq[end,end] - sim.ocean.yq[1,1]) *
            sim.walls[wall_index].thickness
    elseif sim.walls[wall_index].normal ≈ [0., 1., 0.]
        return (sim.ocean.xq[end,end] - sim.ocean.xq[1,1]) *
            sim.walls[wall_index].thickness
    else
        error("Wall normal not understood")
    end
    nothing
end
function getWallSurfaceArea(sim::Simulation, normal::Vector{Float64},
                            thickness::Float64)

    if length(normal) == 3 && normal ≈ [1., 0., 0.]
        return (sim.ocean.yq[end,end] - sim.ocean.yq[1,1]) * thickness
    elseif length(normal) == 3 && normal ≈ [0., 1., 0.]
        return (sim.ocean.xq[end,end] - sim.ocean.xq[1,1]) * thickness
    else
        error("Wall normal not understood")
    end
    nothing
end

export getWallNormalStress
"""
    getWallNormalStress(simulation[, wall_index, stress_type])

Returns the current "effective" or "defined" normal stress on the wall with
index `wall_index` inside the `simulation` object.  The returned value is given
in Pascal.

# Arguments
* `simulation::Simulation`: the simulation object containing the wall.
* `wall_index::Integer=1`: the wall number in the simulation object.
* `stress_type::String="effective"`: the normal-stress type to return.  The
    defined value corresponds to the normal stress that the wall is asked to
    uphold. The effective value is the actual current normal stress.  Usually,
    the magnitude of the effective normal stress fluctuates around the defined
    normal stress.
"""
function getWallNormalStress(sim::Simulation;
                             wall_index::Integer=1,
                             stress_type::String="effective")
    if stress_type == "defined"
        return sim.walls[wall_index].normal_stress

    elseif stress_type == "effective"
        return sim.walls[wall_index].force / getWallSurfaceArea(sim, wall_index)
    else
        error("stress_type not understood, " *
              "should be 'effective' or 'defined' but is '$stress_type'.")
    end
end
