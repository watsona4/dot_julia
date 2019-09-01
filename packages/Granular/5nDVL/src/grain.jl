## Manage grains in the model

using Test
using LinearAlgebra

export addGrainCylindrical!
"""
    function addGrainCylindrical!(simulation, lin_pos, contact_radius,
                                    thickness[, areal_radius, lin_vel, lin_acc,
                                    force, ang_pos, ang_vel, ang_acc, torque,
                                    density, contact_stiffness_normal,
                                    contact_stiffness_tangential,
                                    contact_viscosity_normal,
                                    contact_viscosity_tangential,
                                    contact_static_friction,
                                    contact_dynamic_friction,
                                    youngs_modulus, poissons_ratio,
                                    tensile_strength, shear_strength,
                                    strength_heal_rate,
                                    fracture_toughness,
                                    ocean_drag_coeff_vert,
                                    ocean_drag_coeff_horiz,
                                    atmosphere_drag_coeff_vert,
                                    atmosphere_drag_coeff_horiz,
                                    pressure, fixed,
                                    allow_x_acc, allow_y_acc, allow_z_acc,
                                    rotating, enabled, verbose,
                                    ocean_grid_pos, atmosphere_grid_pos,
                                    n_contact, granular_stress, ocean_stress,
                                    atmosphere_stress,
                                    thermal_energy,
                                    color])

Creates and adds a cylindrical grain to a simulation. Most of the arguments 
are optional, and come with default values.  The only required arguments are 
`simulation`, `lin_pos`, `contact_radius`, and `thickness`.

# Arguments
* `simulation::Simulation`: the simulation object where the grain should be
    added to.
* `lin_pos::Vector{Float64}`: linear position of grain center [m]. If a
    two-component vector is used, the values will be mapped to *x* and *y*, and
    the *z* component will be set to zero.
* `contact_radius::Float64`: grain radius for granular interaction [m].
* `thickness::Float64`: grain thickness [m].
* `areal_radius = false`: grain radius for determining sea-ice concentration
    [m].
* `lin_vel::Vector{Float64} = [0., 0., 0.]`: linear velocity [m/s]. If a
    two-component vector is used, the values will be mapped to *x* and *y*, and
    the *z* component will be set to zero.
* `lin_acc::Vector{Float64} = [0., 0., 0.]`: linear acceleration [m/s^2]. If a
    two-component vector is used, the values will be mapped to *x* and *y*, and
    the *z* component will be set to zero.
* `force::Vector{Float64} = [0., 0., 0.]`: linear force balance [N]. If a
    two-component vector is used, the values will be mapped to *x* and *y*, and
    the *z* component will be set to zero.
* `ang_pos::Float64 = [0., 0., 0.]`: angular position around its center vertical
    axis [rad]. If a scalar is used, the value will be mapped to *z*, and the
    *x* and *y* components will be set to zero.
* `ang_vel::Float64 = [0., 0., 0.]`: angular velocity around its center vertical
    axis [rad/s]. If a scalar is used, the value will be mapped to *z*, and the
    *x* and *y* components will be set to zero.
* `ang_acc::Float64 = [0., 0., 0.]`: angular acceleration around its center
    vertical axis [rad/s^2]. If a scalar is used, the value will be mapped to
    *z*, and the *x* and *y* components will be set to zero.
* `torque::Float64 = [0., 0., 0.]`: torque around its center vertical axis
    [N*m]. If a scalar is used, the value will be mapped to *z*, and the *x* and
    *y* components will be set to zero.
* `density::Float64 = 934.`: grain mean density [kg/m^3].
* `contact_stiffness_normal::Float64 = 1e7`: contact-normal stiffness [N/m];
    overridden if `youngs_modulus` is set to a positive value.
* `contact_stiffness_tangential::Float64 = 0.`: contact-tangential stiffness
    [N/m]; overridden if `youngs_modulus` is set to a positive value.
* `contact_viscosity_normal::Float64 = 0.`: contact-normal viscosity [N/m/s].
* `contact_viscosity_tangential::Float64 = 0.`: contact-tangential viscosity
    [N/m/s].
* `contact_static_friction::Float64 = 0.4`: contact static Coulomb frictional
    coefficient [-].
* `contact_dynamic_friction::Float64 = 0.4`: contact dynamic Coulomb frictional
    coefficient [-].
* `youngs_modulus::Float64 = 2e7`: elastic modulus [Pa]; overrides any value
    set for `contact_stiffness_normal`.
* `poissons_ratio::Float64 = 0.185`: Poisson's ratio, used to determine the
    contact-tangential stiffness from `youngs_modulus` [-].
* `tensile_strength::Float64 = 0.`: contact-tensile (cohesive) bond strength
    [Pa].
* `shear_strength::Float64 = 0.`: shear strength of bonded contacts [Pa].
* `strength_heal_rate::Float64 = 0.`: rate at which contact bond
    strength is obtained [Pa/s].
* `fracture_toughness::Float64 = 0.`: fracture toughness which influences the 
    maximum compressive strength on granular contact [m^{1/2}*Pa]. A value
    of 1.285e3 m^{1/2}*Pa is used for sea ice by Hopkins 2004.
* `ocean_drag_coeff_vert::Float64 = 0.85`: vertical drag coefficient for ocean
    against grain sides [-].
* `ocean_drag_coeff_horiz::Float64 = 5e-4`: horizontal drag coefficient for
    ocean against grain bottom [-].
* `atmosphere_drag_coeff_vert::Float64 = 0.4`: vertical drag coefficient for
    atmosphere against grain sides [-].
* `atmosphere_drag_coeff_horiz::Float64 = 2.5e-4`: horizontal drag coefficient
    for atmosphere against grain bottom [-].
* `pressure::Float64 = 0.`: current compressive stress on grain [Pa].
* `fixed::Bool = false`: grain is fixed to a constant velocity (e.g. zero).
* `allow_x_acc::Bool = false`: override `fixed` along `x`.
* `allow_y_acc::Bool = false`: override `fixed` along `y`.
* `allow_z_acc::Bool = false`: override `fixed` along `z`.
* `rotating::Bool = true`: grain is allowed to rotate.
* `enabled::Bool = true`: grain interacts with other grains.
* `verbose::Bool = true`: display diagnostic information during the function
    call.
* `ocean_grid_pos::Array{Int, 1} = [0, 0]`: position of grain in the ocean
    grid.
* `atmosphere_grid_pos::Array{Int, 1} = [0, 0]`: position of grain in the
    atmosphere grid.
* `n_contacts::Int = 0`: number of contacts with other grains.
* `granular_stress::Vector{Float64} = [0., 0., 0.]`: resultant stress on grain
    from granular interactions [Pa].
* `ocean_stress::Vector{Float64} = [0., 0., 0.]`: resultant stress on grain from
    ocean drag [Pa].
* `atmosphere_stress::Vector{Float64} = [0., 0., 0.]`: resultant stress on grain
    from atmosphere drag [Pa].
* `thermal_energy::Float64 = 0.0`: thermal energy of grain [J].
* `color::Int=0`: type number, usually used for associating a color to the grain
    during visualization.

# Examples
The most basic example adds a new grain to the simulation `sim`, with a 
center at `[1., 2., 0.]`, a radius of `1.` meter, and a thickness of `0.5` 
meter:

```julia
Granular.addGrainCylindrical!(sim, [1., 2.], 1., .5)
```
Note that the *z* component is set to zero if a two-component vector is passed.

The following example will create a grain with tensile and shear strength, and a
velocity of 0.5 m/s towards -x:

```julia
Granular.addGrainCylindrical!(sim, [4., 2.], 1., .5,
                              tensile_strength = 200e3,
                              shear_strength = 100e3,
                              lin_vel = [-.5, 0.])
```

Fixed grains are useful for creating walls or coasts, and loops are useful
for creating regular arrangements:

```julia
for i=1:5
    Granular.addGrainCylindrical!(sim, [i*2., 0., 3.], 1., .5, fixed=true)
end
```
"""
function addGrainCylindrical!(simulation::Simulation,
                                lin_pos::Vector{Float64},
                                contact_radius::Float64,
                                thickness::Float64;
                                areal_radius = false,
                                lin_vel::Vector{Float64} = [0., 0., 0.],
                                lin_acc::Vector{Float64} = [0., 0., 0.],
                                force::Vector{Float64} = [0., 0., 0.],
                                ang_pos::Vector{Float64} = [0., 0., 0.],
                                ang_vel::Vector{Float64} = [0., 0., 0.],
                                ang_acc::Vector{Float64} = [0., 0., 0.],
                                torque::Vector{Float64} = [0., 0., 0.],
                                density::Float64 = 934.,
                                contact_stiffness_normal::Float64 = 1e7,
                                contact_stiffness_tangential::Float64 = 0.,
                                contact_viscosity_normal::Float64 = 0.,
                                contact_viscosity_tangential::Float64 = 0.,
                                contact_static_friction::Float64 = 0.4,
                                contact_dynamic_friction::Float64 = 0.4,
                                youngs_modulus::Float64 = 2e7,
                                poissons_ratio::Float64 = 0.185,  # Hopkins 2004
                                tensile_strength::Float64 = 0.,
                                shear_strength::Float64 = 0.,
                                strength_heal_rate::Float64 = Inf,
                                fracture_toughness::Float64 = 0.,  
                                ocean_drag_coeff_vert::Float64 = 0.85, # H&C 2011
                                ocean_drag_coeff_horiz::Float64 = 5e-4, # H&C 2011
                                atmosphere_drag_coeff_vert::Float64 = 0.4, # H&C 2011
                                atmosphere_drag_coeff_horiz::Float64 = 2.5e-4, # H&C2011
                                pressure::Float64 = 0.,
                                fixed::Bool = false,
                                allow_x_acc::Bool = false,
                                allow_y_acc::Bool = false,
                                allow_z_acc::Bool = false,
                                rotating::Bool = true,
                                enabled::Bool = true,
                                verbose::Bool = true,
                                ocean_grid_pos::Array{Int, 1} = [0, 0],
                                atmosphere_grid_pos::Array{Int, 1} = [0, 0],
                                n_contacts::Int = 0,
                                granular_stress::Vector{Float64} = [0., 0., 0.],
                                ocean_stress::Vector{Float64} = [0., 0., 0.],
                                atmosphere_stress::Vector{Float64} = [0., 0., 0.],
                                thermal_energy::Float64 = 0.,
                                color::Int = 0)

    # Check input values
    if length(lin_pos) != 3
        lin_pos = vecTo3d(lin_pos)
    end
    if length(lin_vel) != 3
        lin_vel = vecTo3d(lin_vel)
    end
    if length(lin_acc) != 3
        lin_acc = vecTo3d(lin_acc)
    end
    if length(force) != 3
        force = vecTo3d(force)
    end
    if length(ang_pos) != 3
        ang_pos = vecTo3d(ang_pos)
    end
    if length(ang_vel) != 3
        ang_vel = vecTo3d(ang_vel)
    end
    if length(ang_acc) != 3
        ang_acc = vecTo3d(ang_acc)
    end
    if length(torque) != 3
        torque = vecTo3d(torque)
    end
    if length(granular_stress) != 3
        granular_stress = vecTo3d(granular_stress)
    end
    if length(ocean_stress) != 3
        ocean_stress = vecTo3d(ocean_stress)
    end
    if length(atmosphere_stress) != 3
        atmosphere_stress = vecTo3d(atmosphere_stress)
    end
    if contact_radius <= 0.0
        error("Radius must be greater than 0.0 " *
              "(radius = $contact_radius m)")
    end
    if density <= 0.0
        error("Density must be greater than 0.0 " *
              "(density = $density kg/m^3)")
    end

    if !areal_radius
        areal_radius = contact_radius
    end

    contacts::Array{Int, 1} = zeros(Int, simulation.Nc_max)
    position_vector = Vector{Vector{Float64}}(undef, simulation.Nc_max)
    contact_parallel_displacement =
        Vector{Vector{Float64}}(undef, simulation.Nc_max)
    contact_rotation = Vector{Vector{Float64}}(undef, simulation.Nc_max)
    contact_age::Vector{Float64} = zeros(Float64, simulation.Nc_max)
    contact_area::Vector{Float64} = zeros(Float64, simulation.Nc_max)
    compressive_failure::Vector{Bool} = zeros(Bool, simulation.Nc_max)
    for i=1:simulation.Nc_max
        position_vector[i] = zeros(3)
        contact_rotation[i] = zeros(3)
        contact_parallel_displacement[i] = zeros(3)
    end

    # Create grain object with placeholder values for surface area, volume, 
    # mass, and moment of inertia.
    grain = GrainCylindrical(density,

                             thickness,
                             contact_radius,
                             areal_radius,
                             1.0,  # circumreference
                             1.0,  # horizontal_surface_area
                             1.0,  # side_surface_area
                             1.0,  # volume
                             1.0,  # mass
                             1.0,  # moment_of_inertia
                             lin_pos,
                             lin_vel,
                             lin_acc,
                             force,
                             [0., 0., 0.], # external_body_force
                             [0., 0., 0.], # lin_disp

                             ang_pos,
                             ang_vel,
                             ang_acc,
                             torque,

                             fixed,
                             allow_x_acc,
                             allow_y_acc,
                             allow_z_acc,
                             rotating,
                             enabled,

                             contact_stiffness_normal,
                             contact_stiffness_tangential,
                             contact_viscosity_normal,
                             contact_viscosity_tangential,
                             contact_static_friction,
                             contact_dynamic_friction,

                             youngs_modulus,
                             poissons_ratio,
                             tensile_strength,
                             shear_strength,
                             strength_heal_rate,
                             fracture_toughness,

                             ocean_drag_coeff_vert,
                             ocean_drag_coeff_horiz,
                             atmosphere_drag_coeff_vert,
                             atmosphere_drag_coeff_horiz,

                             pressure,
                             n_contacts,
                             ocean_grid_pos,
                             atmosphere_grid_pos,
                             contacts,
                             position_vector,
                             contact_parallel_displacement,
                             contact_rotation,
                             contact_age,
                             contact_area,
                             compressive_failure,

                             granular_stress,
                             ocean_stress,
                             atmosphere_stress,

                             thermal_energy,

                             color
                            )

    # Overwrite previous placeholder values
    grain.circumreference = grainCircumreference(grain)
    grain.horizontal_surface_area = grainHorizontalSurfaceArea(grain)
    grain.side_surface_area = grainSideSurfaceArea(grain)
    grain.volume = grainVolume(grain)
    grain.mass = grainMass(grain)
    grain.moment_of_inertia = grainMomentOfInertia(grain)

    # Add to simulation object
    addGrain!(simulation, grain, verbose)
    nothing
end

export grainCircumreference
"Returns the circumreference of the grain"
function grainCircumreference(grain::GrainCylindrical)
    return pi*grain.areal_radius*2.
end

export grainHorizontalSurfaceArea
"Returns the top or bottom (horizontal) surface area of the grain"
function grainHorizontalSurfaceArea(grain::GrainCylindrical)
    return pi*grain.areal_radius^2.
end

export grainSideSurfaceArea
"Returns the surface area of the grain sides"
function grainSideSurfaceArea(grain::GrainCylindrical)
    return grainCircumreference(grain)*grain.thickness
end

export grainVolume
"Returns the volume of the grain"
function grainVolume(grain::GrainCylindrical)
    return grainHorizontalSurfaceArea(grain)*grain.thickness
end

export grainMass
"Returns the mass of the grain"
function grainMass(grain::GrainCylindrical)
    return grainVolume(grain)*grain.density
end

export grainMomentOfInertia
"Returns the moment of inertia of the grain"
function grainMomentOfInertia(grain::GrainCylindrical)
    return 0.5*grainMass(grain)*grain.areal_radius^2.
end

export convertGrainDataToArrays
"""
Gathers all grain parameters from the `GrainCylindrical` type in continuous 
arrays in an `GrainArrays` structure.
"""
function convertGrainDataToArrays(simulation::Simulation)

    ifarr = GrainArrays(
                        # Material properties
                        ## density
                        Array{Float64}(undef, length(simulation.grains)),

                        # Geometrical properties
                        ## thickness
                        Array{Float64}(undef, length(simulation.grains)),
                        ## contact_radius
                        Array{Float64}(undef, length(simulation.grains)),
                        ## areal_radius
                        Array{Float64}(undef, length(simulation.grains)),
                        ## circumreference
                        Array{Float64}(undef, length(simulation.grains)),
                        ## horizontal_surface_area
                        Array{Float64}(undef, length(simulation.grains)),
                        ## side_surface_area
                        Array{Float64}(undef, length(simulation.grains)),
                        ## volume
                        Array{Float64}(undef, length(simulation.grains)),
                        ## mass
                        Array{Float64}(undef, length(simulation.grains)),
                        ## moment_of_inertia
                        Array{Float64}(undef, length(simulation.grains)),

                        # Linear kinematic degrees of freedom along horiz plane
                        ## lin_pos
                        zeros(Float64, 3, length(simulation.grains)),
                        ## lin_vel
                        zeros(Float64, 3, length(simulation.grains)),
                        ## lin_acc
                        zeros(Float64, 3, length(simulation.grains)),
                        ## force
                        zeros(Float64, 3, length(simulation.grains)),
                        ## external_body_force
                        zeros(Float64, 3, length(simulation.grains)),
                        ## lin_disp
                        zeros(Float64, 3, length(simulation.grains)),

                        # Angular kinematic degrees of freedom for vert. rot.
                        ## ang_pos
                        zeros(Float64, 3, length(simulation.grains)),
                        ## ang_vel
                        zeros(Float64, 3, length(simulation.grains)),
                        ## ang_acc
                        zeros(Float64, 3, length(simulation.grains)),
                        ## torque
                        zeros(Float64, 3, length(simulation.grains)),

                        # Kinematic constraint flags
                        ## fixed
                        Array{Int}(undef, length(simulation.grains)),
                        ## allow_x_acc
                        Array{Int}(undef, length(simulation.grains)),
                        ## allow_y_acc
                        Array{Int}(undef, length(simulation.grains)),
                        ## allow_z_acc
                        Array{Int}(undef, length(simulation.grains)),
                        ## rotating
                        Array{Int}(undef, length(simulation.grains)),
                        ## enabled
                        Array{Int}(undef, length(simulation.grains)),

                        # Rheological parameters
                        ## contact_stiffness_normal
                        Array{Float64}(undef, length(simulation.grains)),
                        ## contact_stiffness_tangential
                        Array{Float64}(undef, length(simulation.grains)),
                        ## contact_viscosity_normal
                        Array{Float64}(undef, length(simulation.grains)),
                        ## contact_viscosity_tangential
                        Array{Float64}(undef, length(simulation.grains)),
                        ## contact_static_friction
                        Array{Float64}(undef, length(simulation.grains)),
                        ## contact_dynamic_friction
                        Array{Float64}(undef, length(simulation.grains)),

                        ## youngs_modulus
                        Array{Float64}(undef, length(simulation.grains)),
                        ## poissons_ratio
                        Array{Float64}(undef, length(simulation.grains)),
                        ## tensile_strength
                        Array{Float64}(undef, length(simulation.grains)),
                        ## shear_strength
                        Array{Float64}(undef, length(simulation.grains)),
                        ## strength_heal_rate
                        Array{Float64}(undef, length(simulation.grains)),
                        ## fracture_toughness
                        Array{Float64}(undef, length(simulation.grains)),

                        # Ocean/atmosphere interaction parameters
                        ## ocean_drag_coeff_vert
                        Array{Float64}(undef, length(simulation.grains)),
                        ## ocean_drag_coeff_horiz
                        Array{Float64}(undef, length(simulation.grains)),
                        ## atmosphere_drag_coeff_vert
                        Array{Float64}(undef, length(simulation.grains)),
                        ## atmosphere_drag_coeff_horiz
                        Array{Float64}(undef, length(simulation.grains)),

                        # Interaction
                        ## pressure
                        Array{Float64}(undef, length(simulation.grains)),
                        ## n_contacts
                        Array{Int}(undef, length(simulation.grains)),

                        ## granular_stress
                        zeros(Float64, 3, length(simulation.grains)),
                        ## ocean_stress
                        zeros(Float64, 3, length(simulation.grains)),
                        ## atmosphere_stress
                        zeros(Float64, 3, length(simulation.grains)),

                        ## thermal_energy
                        Array{Float64}(undef, length(simulation.grains)),

                        # Visualization parameters
                        ## color
                        Array{Int}(undef, length(simulation.grains)),

                       )

    # fill arrays
    for i=1:length(simulation.grains)
        ifarr.density[i] = simulation.grains[i].density

        ifarr.thickness[i] = simulation.grains[i].thickness
        ifarr.contact_radius[i] = simulation.grains[i].contact_radius
        ifarr.areal_radius[i] = simulation.grains[i].areal_radius
        ifarr.circumreference[i] = simulation.grains[i].circumreference
        ifarr.horizontal_surface_area[i] =
            simulation.grains[i].horizontal_surface_area
        ifarr.side_surface_area[i] = simulation.grains[i].side_surface_area
        ifarr.volume[i] = simulation.grains[i].volume
        ifarr.mass[i] = simulation.grains[i].mass
        ifarr.moment_of_inertia[i] = simulation.grains[i].moment_of_inertia

        ifarr.lin_pos[1:3, i] = simulation.grains[i].lin_pos
        ifarr.lin_vel[1:3, i] = simulation.grains[i].lin_vel
        ifarr.lin_acc[1:3, i] = simulation.grains[i].lin_acc
        ifarr.force[1:3, i] = simulation.grains[i].force
        ifarr.external_body_force[1:3, i] =
            simulation.grains[i].external_body_force
        ifarr.lin_disp[1:3, i] = simulation.grains[i].lin_disp

        ifarr.ang_pos[1:3, i] = simulation.grains[i].ang_pos
        ifarr.ang_vel[1:3, i] = simulation.grains[i].ang_vel
        ifarr.ang_acc[1:3, i] = simulation.grains[i].ang_acc
        ifarr.torque[1:3, i] = simulation.grains[i].torque

        ifarr.fixed[i] = Int(simulation.grains[i].fixed)
        ifarr.allow_x_acc[i] = Int(simulation.grains[i].allow_x_acc)
        ifarr.allow_y_acc[i] = Int(simulation.grains[i].allow_y_acc)
        ifarr.allow_z_acc[i] = Int(simulation.grains[i].allow_z_acc)
        ifarr.rotating[i] = Int(simulation.grains[i].rotating)
        ifarr.enabled[i] = Int(simulation.grains[i].enabled)

        ifarr.contact_stiffness_normal[i] = 
            simulation.grains[i].contact_stiffness_normal
        ifarr.contact_stiffness_tangential[i] = 
            simulation.grains[i].contact_stiffness_tangential
        ifarr.contact_viscosity_normal[i] = 
            simulation.grains[i].contact_viscosity_normal
        ifarr.contact_viscosity_tangential[i] = 
            simulation.grains[i].contact_viscosity_tangential
        ifarr.contact_static_friction[i] = 
            simulation.grains[i].contact_static_friction
        ifarr.contact_dynamic_friction[i] = 
            simulation.grains[i].contact_dynamic_friction

        ifarr.youngs_modulus[i] = simulation.grains[i].youngs_modulus
        ifarr.poissons_ratio[i] = simulation.grains[i].poissons_ratio
        ifarr.tensile_strength[i] = simulation.grains[i].tensile_strength
        ifarr.shear_strength[i] = simulation.grains[i].shear_strength
        ifarr.strength_heal_rate[i] = simulation.grains[i].strength_heal_rate
        ifarr.fracture_toughness[i] = 
            simulation.grains[i].fracture_toughness

        ifarr.ocean_drag_coeff_vert[i] = 
            simulation.grains[i].ocean_drag_coeff_vert
        ifarr.ocean_drag_coeff_horiz[i] = 
            simulation.grains[i].ocean_drag_coeff_horiz
        ifarr.atmosphere_drag_coeff_vert[i] = 
            simulation.grains[i].atmosphere_drag_coeff_vert
        ifarr.atmosphere_drag_coeff_horiz[i] = 
            simulation.grains[i].atmosphere_drag_coeff_horiz

        ifarr.pressure[i] = simulation.grains[i].pressure
        ifarr.n_contacts[i] = simulation.grains[i].n_contacts

        ifarr.granular_stress[1:3, i] = simulation.grains[i].granular_stress
        ifarr.ocean_stress[1:3, i] = simulation.grains[i].ocean_stress
        ifarr.atmosphere_stress[1:3, i] = simulation.grains[i].atmosphere_stress

        ifarr.thermal_energy[i] = simulation.grains[i].thermal_energy

        ifarr.color[i] = simulation.grains[i].color
    end

    return ifarr
end

function deleteGrainArrays!(ifarr::GrainArrays)
    f1 = zeros(1)
    f2 = zeros(1,1)
    i1 = zeros(Int, 1)

    ifarr.density = f1

    ifarr.thickness = f1
    ifarr.contact_radius = f1
    ifarr.areal_radius = f1
    ifarr.circumreference = f1
    ifarr.horizontal_surface_area = f1
    ifarr.side_surface_area = f1
    ifarr.volume = f1
    ifarr.mass = f1
    ifarr.moment_of_inertia = f1

    ifarr.lin_pos = f2
    ifarr.lin_vel = f2
    ifarr.lin_acc = f2
    ifarr.force = f2
    ifarr.external_body_force = f2
    ifarr.lin_disp = f2

    ifarr.ang_pos = f2
    ifarr.ang_vel = f2
    ifarr.ang_acc = f2
    ifarr.torque = f2

    ifarr.fixed = i1
    ifarr.allow_x_acc = i1
    ifarr.allow_y_acc = i1
    ifarr.allow_z_acc = i1
    ifarr.rotating = i1
    ifarr.enabled = i1

    ifarr.contact_stiffness_normal = f1
    ifarr.contact_stiffness_tangential = f1
    ifarr.contact_viscosity_normal = f1
    ifarr.contact_viscosity_tangential = f1
    ifarr.contact_static_friction = f1
    ifarr.contact_dynamic_friction = f1

    ifarr.youngs_modulus = f1
    ifarr.poissons_ratio = f1
    ifarr.tensile_strength = f1
    ifarr.shear_strength = f1
    ifarr.strength_heal_rate = f1
    ifarr.fracture_toughness = f1

    ifarr.ocean_drag_coeff_vert = f1
    ifarr.ocean_drag_coeff_horiz = f1
    ifarr.atmosphere_drag_coeff_vert = f1
    ifarr.atmosphere_drag_coeff_horiz = f1

    ifarr.pressure = f1
    ifarr.n_contacts = i1

    ifarr.granular_stress = f2
    ifarr.ocean_stress = f2
    ifarr.atmosphere_stress = f2

    ifarr.thermal_energy = f1

    ifarr.color = i1
    nothing
end

export printGrainInfo
"""
    printGrainInfo(grain::GrainCylindrical)

Prints the contents of an grain to stdout in a formatted style.
"""
function printGrainInfo(f::GrainCylindrical)
    println("  density:                 $(f.density) kg/m^3")
    println("  thickness:               $(f.thickness) m")
    println("  contact_radius:          $(f.contact_radius) m")
    println("  areal_radius:            $(f.areal_radius) m")
    println("  circumreference:         $(f.circumreference) m")
    println("  horizontal_surface_area: $(f.horizontal_surface_area) m^2")
    println("  side_surface_area:       $(f.side_surface_area) m^2")
    println("  volume:                  $(f.volume) m^3")
    println("  mass:                    $(f.mass) kg")
    println("  moment_of_inertia:       $(f.moment_of_inertia) kg*m^2\n")

    println("  lin_pos: $(f.lin_pos) m")
    println("  lin_vel: $(f.lin_vel) m/s")
    println("  lin_acc: $(f.lin_acc) m/s^2")
    println("  force:   $(f.force) N\n")
    println("  external_body_force: $(f.external_body_force) N\n")

    println("  ang_pos: $(f.ang_pos) rad")
    println("  ang_vel: $(f.ang_vel) rad/s")
    println("  ang_acc: $(f.ang_acc) rad/s^2")
    println("  torque:  $(f.torque) N*m\n")

    println("  fixed:       $(f.fixed)")
    println("  allow_x_acc: $(f.allow_x_acc)")
    println("  allow_y_acc: $(f.allow_y_acc)")
    println("  allow_z_acc: $(f.allow_z_acc)")
    println("  rotating:    $(f.rotating)")
    println("  enabled:     $(f.enabled)\n")

    println("  k_n: $(f.contact_stiffness_normal) N/m")
    println("  k_t: $(f.contact_stiffness_tangential) N/m")
    println("  γ_n: $(f.contact_viscosity_normal) N/(m/s)")
    println("  γ_t: $(f.contact_viscosity_tangential) N/(m/s)")
    println("  μ_s: $(f.contact_static_friction)")
    println("  μ_d: $(f.contact_dynamic_friction)\n")

    println("  E:                    $(f.youngs_modulus) Pa")
    println("  ν:                    $(f.poissons_ratio)")
    println("  tensile_strength:     $(f.tensile_strength) Pa")
    println("  shear_strength:       $(f.shear_strength) Pa")
    println("  strength_heal_rate:   $(f.strength_heal_rate) Pa/s")
    println("  fracture_toughness:   $(f.fracture_toughness) m^0.5 Pa\n")

    println("  c_o_v:  $(f.ocean_drag_coeff_vert)")
    println("  c_o_h:  $(f.ocean_drag_coeff_horiz)")
    println("  c_a_v:  $(f.atmosphere_drag_coeff_vert)")
    println("  c_a_h:  $(f.atmosphere_drag_coeff_horiz)\n")

    println("  pressure:   $(f.pressure) Pa")
    println("  n_contacts: $(f.n_contacts)")
    println("  contacts:   $(f.contacts)")
    println("  pos_ij:     $(f.position_vector)\n")
    println("  δ_t:        $(f.contact_parallel_displacement)\n")
    println("  θ_t:        $(f.contact_rotation)\n")

    println("  granular_stress:   $(f.granular_stress) Pa")
    println("  ocean_stress:      $(f.ocean_stress) Pa")
    println("  atmosphere_stress: $(f.atmosphere_stress) Pa\n")

    println("  thermal_energy:    $(f.thermal_energy) J\n")

    println("  color:  $(f.color)\n")
    nothing
end

export grainKineticTranslationalEnergy
"Returns the translational kinetic energy of the grain"
function grainKineticTranslationalEnergy(grain::GrainCylindrical)
    return 0.5*grain.mass*norm(grain.lin_vel)^2.
end

export totalGrainKineticTranslationalEnergy
"""
    totalGrainKineticTranslationalEnergy(simulation)

Returns the sum of translational kinetic energies of all grains in a 
simulation
"""
function totalGrainKineticTranslationalEnergy(simulation::Simulation)
    E_sum = 0.
    for grain in simulation.grains
        E_sum += grainKineticTranslationalEnergy(grain)
    end
    return E_sum
end

export grainKineticRotationalEnergy
"Returns the rotational kinetic energy of the grain"
function grainKineticRotationalEnergy(grain::GrainCylindrical)
    return 0.5*grain.moment_of_inertia*norm(grain.ang_vel)^2.
end

export totalGrainKineticRotationalEnergy
"""
    totalGrainKineticRotationalEnergy(simulation)

Returns the sum of rotational kinetic energies of all grains in a simulation
"""
function totalGrainKineticRotationalEnergy(simulation::Simulation)
    E_sum = 0.
    for grain in simulation.grains
        E_sum += grainKineticRotationalEnergy(grain)
    end
    return E_sum
end

export grainThermalEnergy
"Returns the thermal energy of the grain, produced by Coulomb slip"
function grainThermalEnergy(grain::GrainCylindrical)
    return grain.thermal_energy
end

export totalGrainThermalEnergy
"""
    totalGrainKineticTranslationalEnergy(simulation)

Returns the sum of thermal energy of all grains in a simulation
"""
function totalGrainThermalEnergy(simulation::Simulation)
    E_sum = 0.
    for grain in simulation.grains
        E_sum += grainThermalEnergy(grain)
    end
    return E_sum
end

export addBodyForce!
"""
    setBodyForce!(grain, force)

Add to the value of the external body force on a grain.

# Arguments
* `grain::GrainCylindrical`: the grain to set the body force for.
* `force::Vector{Float64}`: a vector of force [N]
"""
function addBodyForce!(grain::GrainCylindrical, force::Vector{Float64})
    grain.external_body_force += vecTo3d(force)
end

export setBodyForce!
"""
    setBodyForce!(grain, force)

Set the value of the external body force on a grain.

# Arguments
* `grain::GrainCylindrical`: the grain to set the body force for.
* `force::Vector{Float64}`: a vector of force [N]
"""
function setBodyForce!(grain::GrainCylindrical, force::Vector{Float64})
    grain.external_body_force = vecTo3d(force)
end

export compareGrains
"""
    compareGrains(if1::GrainCylindrical, if2::GrainCylindrical)

Compare values of two grain objects using the `Base.Test` framework.
"""
function compareGrains(if1::GrainCylindrical, if2::GrainCylindrical)

    @test if1.density ≈ if2.density
    @test if1.thickness ≈ if2.thickness
    @test if1.contact_radius ≈ if2.contact_radius
    @test if1.areal_radius ≈ if2.areal_radius
    @test if1.circumreference ≈ if2.circumreference
    @test if1.horizontal_surface_area ≈ if2.horizontal_surface_area
    @test if1.side_surface_area ≈ if2.side_surface_area
    @test if1.volume ≈ if2.volume
    @test if1.mass ≈ if2.mass
    @test if1.moment_of_inertia ≈ if2.moment_of_inertia

    @test if1.lin_pos ≈ if2.lin_pos
    @test if1.lin_vel ≈ if2.lin_vel
    @test if1.lin_acc ≈ if2.lin_acc
    @test if1.force ≈ if2.force
    @test if1.external_body_force ≈ if2.external_body_force
    @test if1.lin_disp ≈ if2.lin_disp

    @test if1.ang_pos ≈ if2.ang_pos
    @test if1.ang_vel ≈ if2.ang_vel
    @test if1.ang_acc ≈ if2.ang_acc
    @test if1.torque ≈ if2.torque

    @test if1.fixed == if2.fixed
    @test if1.rotating == if2.rotating
    @test if1.enabled == if2.enabled

    @test if1.contact_stiffness_normal ≈ if2.contact_stiffness_normal
    @test if1.contact_stiffness_tangential ≈ if2.contact_stiffness_tangential
    @test if1.contact_viscosity_normal ≈ if2.contact_viscosity_normal
    @test if1.contact_viscosity_tangential ≈ if2.contact_viscosity_tangential
    @test if1.contact_static_friction ≈ if2.contact_static_friction
    @test if1.contact_dynamic_friction ≈ if2.contact_dynamic_friction

    @test if1.youngs_modulus ≈ if2.youngs_modulus
    @test if1.poissons_ratio ≈ if2.poissons_ratio
    @test if1.tensile_strength ≈ if2.tensile_strength
    @test if1.shear_strength ≈ if2.shear_strength
    @test if1.strength_heal_rate ≈ if2.strength_heal_rate
    @test if1.fracture_toughness ≈ if2.fracture_toughness

    @test if1.ocean_drag_coeff_vert ≈ if2.ocean_drag_coeff_vert
    @test if1.ocean_drag_coeff_horiz ≈ if2.ocean_drag_coeff_horiz
    @test if1.atmosphere_drag_coeff_vert ≈ if2.atmosphere_drag_coeff_vert
    @test if1.atmosphere_drag_coeff_horiz ≈ if2.atmosphere_drag_coeff_horiz

    @test if1.pressure ≈ if2.pressure
    @test if1.n_contacts == if2.n_contacts
    @test if1.ocean_grid_pos == if2.ocean_grid_pos
    @test if1.contacts == if2.contacts
    @test if1.position_vector == if2.position_vector
    @test if1.contact_parallel_displacement == if2.contact_parallel_displacement
    @test if1.contact_rotation == if2.contact_rotation
    @test if1.contact_age ≈ if2.contact_age
    @test if1.contact_area ≈ if2.contact_area
    @test if1.compressive_failure ≈ if2.compressive_failure

    @test if1.granular_stress ≈ if2.granular_stress
    @test if1.ocean_stress ≈ if2.ocean_stress
    @test if1.atmosphere_stress ≈ if2.atmosphere_stress

    @test if1.thermal_energy ≈ if2.thermal_energy

    @test if1.color ≈ if2.color
    nothing
end

export enableOceanDrag!
"""
    enableOceanDrag!(grain)

Enable ocean-caused drag on the grain, with values by Hunke and Comeau (2011).
"""
function enableOceanDrag!(grain::GrainCylindrical)
    grain.ocean_drag_coeff_vert = 0.85
    grain.ocean_drag_coeff_horiz = 5e-4
end

export enableAtmosphereDrag!
"""
    enableAtmosphereDrag!(grain)

Enable atmosphere-caused drag on the grain, with values by Hunke and Comeau
(2011).
"""
function enableAtmosphereDrag!(grain::GrainCylindrical)
    grain.atmosphere_drag_coeff_vert = 0.4
    grain.atmosphere_drag_coeff_horiz = 2.5e-4
end
export disableOceanDrag!
"""
    disableOceanDrag!(grain)

Disable ocean-caused drag on the grain.
"""
function disableOceanDrag!(grain::GrainCylindrical)
    grain.ocean_drag_coeff_vert = 0.
    grain.ocean_drag_coeff_horiz = 0.
end

export disableAtmosphereDrag!
"""
    disableAtmosphereDrag!(grain)

Disable atmosphere-caused drag on the grain.
"""
function disableAtmosphereDrag!(grain::GrainCylindrical)
    grain.atmosphere_drag_coeff_vert = 0.
    grain.atmosphere_drag_coeff_horiz = 0.
end

export zeroKinematics!
"""
    zeroKinematics!(simulation)

Set all grain forces, torques, accelerations, and velocities (linear and
rotational) to zero in order to get rid of all kinetic energy.
"""
function zeroKinematics!(sim::Simulation)
    for grain in sim.grains
        grain.lin_vel .= zeros(3)
        grain.lin_acc .= zeros(3)
        grain.force .= zeros(3)
        grain.lin_disp .= zeros(3)
        grain.ang_vel .= zeros(3)
        grain.ang_acc .= zeros(3)
        grain.torque .= zeros(3)
    end
end
