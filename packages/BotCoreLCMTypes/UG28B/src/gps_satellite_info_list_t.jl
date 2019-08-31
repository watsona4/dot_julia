mutable struct gps_satellite_info_list_t <: LCMType
    utime::Int64
    num_sats::Int32
    sat_info::Vector{gps_satellite_info_t}
end

@lcmtypesetup(gps_satellite_info_list_t,
    sat_info => (num_sats,),
)
