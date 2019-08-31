mutable struct pose_t <: LCMType
    utime::Int64
    pos::SVector{3, Float64}
    vel::SVector{3, Float64}
    orientation::SVector{4, Float64}
    rotation_rate::SVector{3, Float64}
    accel::SVector{3, Float64}
end

@lcmtypesetup(pose_t)
