mutable struct external_force_torque_t <: LCMType
    timestamp::Int64
    num_external_forces::Int16
    body_names::Vector{String}
    fx::Vector{Float64}
    fy::Vector{Float64}
    fz::Vector{Float64}
    tx::Vector{Float64}
    ty::Vector{Float64}
    tz::Vector{Float64}
end

@lcmtypesetup(external_force_torque_t,
    body_names => (num_external_forces,),
    fx => (num_external_forces,),
    fy => (num_external_forces,),
    fz => (num_external_forces,),
    tx => (num_external_forces,),
    ty => (num_external_forces,),
    tz => (num_external_forces,),
)
