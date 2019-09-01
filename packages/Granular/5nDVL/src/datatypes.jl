## Particle composite types
mutable struct GrainCylindrical

    # Material properties
    density::Float64

    # Geometrical parameters
    thickness::Float64
    contact_radius::Float64
    areal_radius::Float64
    circumreference::Float64
    horizontal_surface_area::Float64
    side_surface_area::Float64
    volume::Float64
    mass::Float64
    moment_of_inertia::Float64

    # Linear kinematic degrees of freedom along horizontal plane
    lin_pos::Vector{Float64}
    lin_vel::Vector{Float64}
    lin_acc::Vector{Float64}
    force::Vector{Float64}
    external_body_force::Vector{Float64}
    lin_disp::Vector{Float64}

    # Angular kinematic degrees of freedom for vertical rotation around center
    ang_pos::Vector{Float64}
    ang_vel::Vector{Float64}
    ang_acc::Vector{Float64}
    torque::Vector{Float64}

    # Kinematic constraint flags
    fixed::Bool
    allow_x_acc::Bool
    allow_y_acc::Bool
    allow_z_acc::Bool
    rotating::Bool
    enabled::Bool

    # Rheological parameters
    contact_stiffness_normal::Float64
    contact_stiffness_tangential::Float64
    contact_viscosity_normal::Float64
    contact_viscosity_tangential::Float64
    contact_static_friction::Float64
    contact_dynamic_friction::Float64

    youngs_modulus::Float64
    poissons_ratio::Float64
    tensile_strength::Float64
    shear_strength::Float64
    strength_heal_rate::Float64
    fracture_toughness::Float64

    # Ocean/atmosphere interaction parameters
    ocean_drag_coeff_vert::Float64
    ocean_drag_coeff_horiz::Float64
    atmosphere_drag_coeff_vert::Float64
    atmosphere_drag_coeff_horiz::Float64

    # Interaction
    pressure::Float64
    n_contacts::Int
    ocean_grid_pos::Vector{Int}
    atmosphere_grid_pos::Vector{Int}
    contacts::Vector{Int}
    position_vector::Vector{Vector{Float64}}
    contact_parallel_displacement::Vector{Vector{Float64}}
    contact_rotation::Vector{Vector{Float64}}
    contact_age::Vector{Float64}
    contact_area::Vector{Float64}
    compressive_failure::Vector{Bool}

    granular_stress::Vector{Float64}
    ocean_stress::Vector{Float64}
    atmosphere_stress::Vector{Float64}

    thermal_energy::Float64

    # Visualization parameters
    color::Int
end

# Type for linear (flat) and frictionless dynamic walls
mutable struct WallLinearFrictionless
    normal::Vector{Float64}   # Wall-face normal vector
    pos::Float64              # Position along axis parallel to normal vector
    bc::String                # Boundary condition
    mass::Float64             # Mass, used when bc != "fixed"
    thickness::Float64        # Wall thickness
    surface_area::Float64     # Wall surface area
    normal_stress::Float64    # Normal stress when bc == "normal stress"
    vel::Float64              # Velocity (constant when bc == "normal stress")
    acc::Float64              # Acceleration (zero when bc == "velocity")
    force::Float64            # Sum of normal forces on wall
    contact_viscosity_normal::Float64 # Wall-normal contact viscosity
end

# Type for gathering data from grain objects into single arrays
mutable struct GrainArrays

    # Material properties
    density::Vector{Float64}

    # Geometrical parameters
    thickness::Vector{Float64}
    contact_radius::Vector{Float64}
    areal_radius::Vector{Float64}
    circumreference::Vector{Float64}
    horizontal_surface_area::Vector{Float64}
    side_surface_area::Vector{Float64}
    volume::Vector{Float64}
    mass::Vector{Float64}
    moment_of_inertia::Vector{Float64}

    # Linear kinematic degrees of freedom along horizontal plane
    lin_pos::Array{Float64, 2}
    lin_vel::Array{Float64, 2}
    lin_acc::Array{Float64, 2}
    force::Array{Float64, 2}
    external_body_force::Array{Float64, 2}
    lin_disp::Array{Float64, 2}

    # Angular kinematic degrees of freedom for vertical rotation around center
    ang_pos::Array{Float64, 2}
    ang_vel::Array{Float64, 2}
    ang_acc::Array{Float64, 2}
    torque::Array{Float64, 2}

    # Kinematic constraint flags
    fixed::Vector{Int}
    allow_x_acc::Vector{Int}
    allow_y_acc::Vector{Int}
    allow_z_acc::Vector{Int}
    rotating::Vector{Int}
    enabled::Vector{Int}

    # Rheological parameters
    contact_stiffness_normal::Vector{Float64}
    contact_stiffness_tangential::Vector{Float64}
    contact_viscosity_normal::Vector{Float64}
    contact_viscosity_tangential::Vector{Float64}
    contact_static_friction::Vector{Float64}
    contact_dynamic_friction::Vector{Float64}

    youngs_modulus::Vector{Float64}
    poissons_ratio::Vector{Float64}
    tensile_strength::Vector{Float64}
    shear_strength::Vector{Float64}
    strength_heal_rate::Vector{Float64}
    fracture_toughness::Vector{Float64}

    ocean_drag_coeff_vert::Vector{Float64}
    ocean_drag_coeff_horiz::Vector{Float64}
    atmosphere_drag_coeff_vert::Vector{Float64}
    atmosphere_drag_coeff_horiz::Vector{Float64}

    pressure::Vector{Float64}
    n_contacts::Vector{Int}

    granular_stress::Array{Float64, 2}
    ocean_stress::Array{Float64, 2}
    atmosphere_stress::Array{Float64, 2}

    thermal_energy::Vector{Float64}

    color::Vector{Int}
end

#=
Type containing all relevant data from MOM6 NetCDF files.  The ocean grid is a 
staggered of Arakawa-B type, with south-west convention centered on the 
h-points.  During read, the velocities are interpolated to the cell corners 
(q-points).

    q(  i,j+1) ------------------ q(i+1,j+1)
         |                             |
         |                             |
         |                             |
         |                             |
         |         h(  i,  j)          |
         |                             |
         |                             |
         |                             |
         |                             |
    q(  i,  j) ------------------ q(i+1,  j)

# Fields
* `input_file::String`: path to input NetCDF file
* `time::Array{Float64, 1}`: time in days
* `xq::Array{Float64, 2}`: nominal longitude of q-points [degrees_E]
* `yq::Array{Float64, 2}`: nominal latitude of q-points [degrees_N]
* `xh::Array{Float64, 2}`: nominal longitude of h-points [degrees_E]
* `yh::Array{Float64, 2}`: nominal latitude of h-points [degrees_N]
* `zl::Array{Float64, 1}`: layer target potential density [kg m^-3]
* `zi::Array{Float64, 1}`: interface target potential density [kg m^-3]
* `u::Array{Float64, Int}`: zonal velocity (positive towards west) [m/s], 
    dimensions correspond to placement in `[xq, yq, zl, time]`.
* `v::Array{Float64, Int}`: meridional velocity (positive towards north) [m/s], 
    dimensions correspond to placement in `[xq, yq, zl, time]`.
* `h::Array{Float64, Int}`: layer thickness [m], dimensions correspond to 
    placement in `[xh, yh, zl, time]`.
* `e::Array{Float64, Int}`: interface height relative to mean sea level [m],  
    dimensions correspond to placement in `[xh, yh, zi, time]`.
* `grain_list::Array{Float64, Int}`: indexes of grains contained in the 
    ocean grid cells.
* `bc_west::Integer`: Boundary condition type for the west edge of the grid.
        1: inactive,
        2: periodic
* `bc_south::Integer`: Boundary condition type for the south edge of the grid.
        1: inactive,
        2: periodic
* `bc_east::Integer`: Boundary condition type for the east edge of the grid.
        1: inactive,
        2: periodic
* `bc_north::Integer`: Boundary condition type for the north edge of the grid.
        1: inactive,
        2: periodic
=#
mutable struct Ocean
    input_file::Any

    time::Vector{Float64}

    # q-point (cell corner) positions
    xq::Array{Float64, 2}
    yq::Array{Float64, 2}

    # h-point (cell center) positions
    xh::Array{Float64, 2}
    yh::Array{Float64, 2}

    # Vertical positions
    zl::Vector{Float64}
    zi::Vector{Float64}
    
    # Field values
    u::Array{Float64, 4}
    v::Array{Float64, 4}
    h::Array{Float64, 4}
    e::Array{Float64, 4}

    # Grains in grid cells
    grain_list::Array{Vector{Int}, 2}
    porosity::Array{Float64, 2}

    # Boundary conditions for grains
    bc_west::Integer
    bc_south::Integer
    bc_east::Integer
    bc_north::Integer

    # If the grid is regular, allow for simpler particle sorting
    regular_grid::Bool

    # Grid size when regular_grid == true
    origo::Vector{Float64} # Grid origo
    L::Vector{Float64}     # Grid length
    n::Vector{Integer}     # Cell count
    dx::Vector{Float64}    # Cell size
end

#=
The atmosphere grid is a staggered of Arakawa-B type, with south-west convention 
centered on the h-points.  During read, the velocities are interpolated to the 
cell corners (q-points).

    q(  i,j+1) ------------------ q(i+1,j+1)
         |                             |
         |                             |
         |                             |
         |                             |
         |         h(  i,  j)          |
         |                             |
         |                             |
         |                             |
         |                             |
    q(  i,  j) ------------------ q(i+1,  j)

# Fields
* `input_file::String`: path to input NetCDF file
* `time::Vector{Float64}`: time in days
* `xq::Array{Float64, 2}`: nominal longitude of q-points [degrees_E]
* `yq::Array{Float64, 2}`: nominal latitude of q-points [degrees_N]
* `xh::Array{Float64, 2}`: nominal longitude of h-points [degrees_E]
* `yh::Array{Float64, 2}`: nominal latitude of h-points [degrees_N]
* `zl::Vector{Float64}`: vertical position [m]
* `u::Array{Float64, Int}`: zonal velocity (positive towards west) [m/s], 
    dimensions correspond to placement in `[xq, yq, zl, time]`.
* `v::Array{Float64, Int}`: meridional velocity (positive towards north) [m/s], 
    dimensions correspond to placement in `[xq, yq, zl, time]`.
* `grain_list::Array{Float64, Int}`: interface height relative to mean sea 
    level [m],  dimensions correspond to placement in `[xh, yh, zi, time]`.
* `bc_west::Integer`: Boundary condition type for the west edge of the grid.
        1: inactive,
        2: periodic
* `bc_south::Integer`: Boundary condition type for the south edge of the grid.
        1: inactive,
        2: periodic
* `bc_east::Integer`: Boundary condition type for the east edge of the grid.
        1: inactive,
        2: periodic
* `bc_north::Integer`: Boundary condition type for the north edge of the grid.
        1: inactive,
        2: periodic
=#
mutable struct Atmosphere
    input_file::Any

    time::Vector{Float64}

    # q-point (cell corner) positions
    xq::Array{Float64, 2}
    yq::Array{Float64, 2}

    # h-point (cell center) positions
    xh::Array{Float64, 2}
    yh::Array{Float64, 2}

    # Vertical positions
    zl::Vector{Float64}
    
    # Field values
    u::Array{Float64, 4}
    v::Array{Float64, 4}

    # Grains in grid cells
    grain_list::Array{Vector{Int}, 2}
    porosity::Array{Float64, 2}

    # Boundary conditions for grains
    bc_west::Integer
    bc_south::Integer
    bc_east::Integer
    bc_north::Integer

    # If true the grid positions are identical to the ocean grid
    collocated_with_ocean_grid::Bool

    # If the grid is regular, allow for simpler particle sorting
    regular_grid::Bool

    # Grid size when regular_grid == true
    origo::Vector{Float64} # Grid origo
    L::Vector{Float64}     # Grid length
    n::Vector{Integer}     # Cell count
    dx::Vector{Float64}    # Cell size
end

# Top-level simulation type
mutable struct Simulation
    id::String

    time_iteration::Int
    time::Float64
    time_total::Float64
    time_step::Float64
    file_time_step::Float64
    file_number::Int
    file_time_since_output_file::Float64

    grains::Vector{GrainCylindrical}

    ocean::Ocean
    atmosphere::Atmosphere

    Nc_max::Int

    walls::Vector{WallLinearFrictionless}
end

# Mappings between boundary condition keys (Integers) and strings
const grid_bc_strings = ["inactive", "periodic", "impermeable"]
const grid_bc_flags = Dict(zip(grid_bc_strings, 1:length(grid_bc_strings)))
