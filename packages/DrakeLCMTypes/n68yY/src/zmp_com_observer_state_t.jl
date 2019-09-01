mutable struct zmp_com_observer_state_t <: LCMType
    utime::Int64
    com::SVector{2, Float64}
    comd::SVector{2, Float64}
    ground_plane_height::Float64
end

@lcmtypesetup(zmp_com_observer_state_t)
