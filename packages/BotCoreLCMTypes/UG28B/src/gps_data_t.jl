mutable struct gps_data_t <: LCMType
    utime::Int64
    gps_lock::Int32
    longitude::Float64
    latitude::Float64
    elev::Float64
    horizontal_accuracy::Float64
    vertical_accuracy::Float64
    numSatellites::Int32
    speed::Float64
    heading::Float64
    xyz_pos::SVector{3, Float64}
    gps_time::Float64
end

@lcmtypesetup(gps_data_t)
