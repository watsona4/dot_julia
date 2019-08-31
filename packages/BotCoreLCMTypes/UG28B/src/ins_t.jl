mutable struct ins_t <: LCMType
    utime::Int64
    device_time::Int64

    gyro::SVector{3, Float64}
    mag::SVector{3, Float64}
    accel::SVector{3, Float64}
    quat::SVector{4, Float64}

    pressure::Float64
    rel_alt::Float64
end

@lcmtypesetup(ins_t)
