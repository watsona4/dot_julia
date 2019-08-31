mutable struct pointcloud2_t <: LCMType
    utime::Int64
    seq::Int32
    frame_id::String
    height::Int32
    width::Int32

    nfields::Int32
    fields::Vector{pointfield_t}

    is_bigendian::Bool
    point_step::Int32
    row_step::Int32
    data_nbytes::Int32
    data::Vector{UInt8}
    is_dense::Bool
end

@lcmtypesetup(pointcloud2_t,
    fields => (nfields,),
    data => (data_nbytes,),
)
