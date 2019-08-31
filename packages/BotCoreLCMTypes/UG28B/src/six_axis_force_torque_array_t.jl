mutable struct six_axis_force_torque_array_t <: LCMType
    utime::Int64
    num_sensors::Int32
    names::Vector{String}
    sensors::Vector{six_axis_force_torque_t}
end

@lcmtypesetup(six_axis_force_torque_array_t,
    names => (num_sensors,),
    sensors => (num_sensors,)
)
