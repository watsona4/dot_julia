mutable struct kvh_raw_imu_batch_t <: LCMType
    utime::Int64
    num_packets::Int32
    raw_imu::Vector{kvh_raw_imu_t}
end

@lcmtypesetup(kvh_raw_imu_batch_t,
    raw_imu => (num_packets,)
)
