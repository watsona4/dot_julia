mutable struct planar_lidar_t <: LCMType
    utime::Int64
    nranges::Int32
    ranges::Vector{Float32}

    nintensities::Int32
    intensities::Vector{Float32}

    rad0::Float32
    radstep::Float32
end

@lcmtypesetup(planar_lidar_t,
    ranges => (nranges,),
    intensities => (nintensities,),
)
