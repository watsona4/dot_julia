mutable struct kvh_raw_imu_t <: LCMType
    utime::Int64
    packet_count::Int64
    delta_rotation::SVector{3, Float64}
    linear_acceleration::SVector{3, Float64}
end

@lcmtypesetup(kvh_raw_imu_t)
