using Test
using LinearAlgebra

export createEmptyAtmosphere
"Returns empty ocean type for initialization purposes."
function createEmptyAtmosphere()
    return Atmosphere(false,

                      zeros(1),

                      zeros(1,1),
                      zeros(1,1),
                      zeros(1,1),
                      zeros(1,1),

                      zeros(1),

                      zeros(1,1,1,1),
                      zeros(1,1,1,1),

                      Array{Vector{Int}}(undef, 1, 1),
                      zeros(1,1),

                      1, 1, 1, 1,

                      false,

                      false, [0.,0.,0.], [1.,1.,1.], [1,1,1], [1.,1.,1.])
end

export interpolateAtmosphereState
"""
Atmosphere data is containted in `Atmosphere` type at discrete times 
(`Atmosphere.time`).  This function performs linear interpolation between time 
steps to get the approximate atmosphere state at any point in time.  If the 
`Atmosphere` data set only contains a single time step, values from that time 
are returned.
"""
function interpolateAtmosphereState(atmosphere::Atmosphere, t::Float64)
    if length(atmosphere.time) == 1
        return atmosphere.u, atmosphere.v
    elseif t < atmosphere.time[1] || t > atmosphere.time[end]
        error("selected time (t = $(t)) is outside the range of " *
              "time steps in the atmosphere data")
    end
end

export createRegularAtmosphereGrid
"""
    createRegularAtmosphereGrid(n, L[, origo, time, name,
                                bc_west, bc_south, bc_east, bc_north])

Initialize and return a regular, Cartesian `Atmosphere` grid with `n[1]` by
`n[2]` cells in the horizontal dimension, and `n[3]` vertical cells.  The cell
corner and center coordinates will be set according to the grid spatial
dimensions `L[1]`, `L[2]`, and `L[3]`.  The grid `u`, `v`, `h`, and `e` fields
will contain one 4-th dimension matrix per `time` step.  Sea surface will be at
`z=0.` with the atmosphere spanning `z<0.`.  Vertical indexing starts with `k=0`
at the sea surface, and increases downwards.

# Arguments
* `n::Vector{Int}`: number of cells along each dimension [-].
* `L::Vector{Float64}`: domain length along each dimension [m].
* `origo::Vector{Float64}`: domain offset in each dimension [m] (default =
    `[0.0, 0.0]`).
* `time::Vector{Float64}`: vector of time stamps for the grid [s].
* `name::String`: grid name (default = `"unnamed"`).
* `bc_west::Integer`: grid boundary condition for the grains.
* `bc_south::Integer`: grid boundary condition for the grains.
* `bc_east::Integer`: grid boundary condition for the grains.
* `bc_north::Integer`: grid boundary condition for the grains.
"""
function createRegularAtmosphereGrid(n::Vector{Int},
                                     L::Vector{Float64};
                                     origo::Vector{Float64} = zeros(2),
                                     time::Array{Float64, 1} = zeros(1),
                                     name::String = "unnamed",
                                     bc_west::Integer = 1,
                                     bc_south::Integer = 1,
                                     bc_east::Integer = 1,
                                     bc_north::Integer = 1)

    xq = repeat(range(origo[1], stop=origo[1] + L[1], length=n[1] + 1),
                outer=[1, n[2] + 1])
    yq = repeat(range(origo[2], stop=origo[2] + L[2], length=n[2] + 1)',
                outer=[n[1] + 1, 1])

    dx = L./n
    xh = repeat(range(origo[1] + .5*dx[1],
                      stop=origo[1] + L[1] - .5*dx[1],
                      length=n[1]),
                outer=[1, n[2]])
    yh = repeat(range(origo[2] + .5*dx[2],
                      stop=origo[1] + L[2] - .5*dx[2],
                      length=n[2])',
                outer=[n[1], 1])

    zl = -range(.5*dx[3], stop=L[3] - .5*dx[3], length=n[3])

    u = zeros(n[1] + 1, n[2] + 1, n[3], length(time))
    v = zeros(n[1] + 1, n[2] + 1, n[3], length(time))

    return Atmosphere(name,
                 time,
                 xq, yq,
                 xh, yh,
                 zl,
                 u, v,
                 Array{Array{Int, 1}}(undef, size(xh, 1), size(xh, 2)),
                 zeros(size(xh)),
                 bc_west, bc_south, bc_east, bc_north,
                 false,
                 true, origo, L, n, dx)
end

export addAtmosphereDrag!
"""
Add drag from linear and angular velocity difference between atmosphere and all 
grains.
"""
function addAtmosphereDrag!(simulation::Simulation)
    if typeof(simulation.atmosphere.input_file) == Bool
        error("no atmosphere data read")
    end

    u, v = interpolateAtmosphereState(simulation.atmosphere, simulation.time)
    uv_interp = Vector{Float64}(undef, 2)
    sw = Vector{Float64}(undef, 2)
    se = Vector{Float64}(undef, 2)
    ne = Vector{Float64}(undef, 2)
    nw = Vector{Float64}(undef, 2)

    for grain in simulation.grains

        if !grain.enabled
            continue
        end

        i, j = grain.atmosphere_grid_pos
        k = 1

        x_tilde, y_tilde = getNonDimensionalCellCoordinates(simulation.
                                                            atmosphere,
                                                            i, j,
                                                            grain.lin_pos)
        x_tilde = clamp(x_tilde, 0., 1.)
        y_tilde = clamp(y_tilde, 0., 1.)

        bilinearInterpolation!(uv_interp, u, v, x_tilde, y_tilde, i, j, k, 1)
        applyAtmosphereDragToGrain!(grain, uv_interp[1], uv_interp[2])
        applyAtmosphereVorticityToGrain!(grain,
                                      curl(simulation.atmosphere,
                                           x_tilde, y_tilde,
                                           i, j, k, 1, sw, se, ne, nw))
    end
    nothing
end

export applyAtmosphereDragToGrain!
"""
Add Stokes-type drag from velocity difference between atmosphere and a single 
grain.
"""
function applyAtmosphereDragToGrain!(grain::GrainCylindrical,
                                  u::Float64, v::Float64)
    ρ_a = 1.2754   # atmosphere density

    drag_force = ρ_a * π * 
    (2.0*grain.ocean_drag_coeff_vert*grain.areal_radius*.1*grain.thickness + 
     grain.atmosphere_drag_coeff_horiz*grain.areal_radius^2.0) *
        ([u, v] - grain.lin_vel[1:2])*norm([u, v] - grain.lin_vel[1:2])

    grain.force += vecTo3d(drag_force)
    grain.atmosphere_stress = vecTo3d(drag_force/grain.horizontal_surface_area)
    nothing
end

export applyAtmosphereVorticityToGrain!
"""
Add Stokes-type torque from angular velocity difference between atmosphere and a 
single grain.  See Eq. 9.28 in "Introduction to Fluid Mechanics" by Nakayama 
and Boucher, 1999.
"""
function applyAtmosphereVorticityToGrain!(grain::GrainCylindrical, 
                                            atmosphere_curl::Float64)
    ρ_a = 1.2754   # atmosphere density

    grain.torque[3] +=
        π * grain.areal_radius^4. * ρ_a * 
        (grain.areal_radius / 5. * grain.atmosphere_drag_coeff_horiz + 
        .1 * grain.thickness * grain.atmosphere_drag_coeff_vert) * 
        norm(.5 * atmosphere_curl - grain.ang_vel[3]) * 
        (.5 * atmosphere_curl - grain.ang_vel[3])
    nothing
end

export compareAtmospheres
"""
    compareAtmospheres(atmosphere1::atmosphere, atmosphere2::atmosphere)

Compare values of two `atmosphere` objects using the `Base.Test` framework.
"""
function compareAtmospheres(atmosphere1::Atmosphere, atmosphere2::Atmosphere)

    @test atmosphere1.input_file == atmosphere2.input_file
    @test atmosphere1.time ≈ atmosphere2.time

    @test atmosphere1.xq ≈ atmosphere2.xq
    @test atmosphere1.yq ≈ atmosphere2.yq

    @test atmosphere1.xh ≈ atmosphere2.xh
    @test atmosphere1.yh ≈ atmosphere2.yh

    @test atmosphere1.zl ≈ atmosphere2.zl

    @test atmosphere1.u ≈ atmosphere2.u
    @test atmosphere1.v ≈ atmosphere2.v

    if isassigned(atmosphere1.grain_list, 1)
        @test atmosphere1.grain_list == atmosphere2.grain_list
    end
    nothing
end
