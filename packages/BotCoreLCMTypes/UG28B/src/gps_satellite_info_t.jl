mutable struct gps_satellite_info_t <: LCMType
    used_for_nav::Bool
    differential_correction_avail::Bool
    orbit_info_avail::Bool
    ephemeris::Bool
    healthy::Bool

    signal_quality::Int16  # 0-idle,(1,2)-searching,3-detected but unstable,4-lock on signal,(5,6)-code and carrier locked, 7-6+receiving @ 50bps
    carrier_to_noise::Int16
    azimuth::Float64
    elevation::Float64
end

@lcmtypesetup(gps_satellite_info_t)
