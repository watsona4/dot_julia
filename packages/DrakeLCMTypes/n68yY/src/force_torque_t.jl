mutable struct force_torque_t <: LCMType
    timestamp::Int64
    fx::Float64
    fy::Float64
    fz::Float64
    tx::Float64
    ty::Float64
    tz::Float64
end

@lcmtypesetup(force_torque_t)
