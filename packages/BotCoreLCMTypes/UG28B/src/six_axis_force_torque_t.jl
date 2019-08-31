mutable struct six_axis_force_torque_t <: LCMType
    utime::Int64
    force::SVector{3, Float64}
    moment::SVector{3, Float64}
end

@lcmtypesetup(six_axis_force_torque_t)
