mutable struct pointcloud_t <: LCMType
    utime::Int64
    seq::Int32
    frame_id::String
    n_points::Int32
    points::Matrix{Float32}

    n_channels::Int32
    channel_names::Vector{String}
    channels::Matrix{Float32}
end

@lcmtypesetup(pointcloud_t,
    points => (n_points, 3),
    channel_names => (n_channels,),
    channels => (n_channels, n_points),
)
