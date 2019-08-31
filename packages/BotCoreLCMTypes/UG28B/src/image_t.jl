mutable struct image_t <: LCMType
    utime::Int64
    width::Int32
    height::Int32
    row_stride::Int32
    pixelformat::Int32
    size::Int32
    data::Vector{UInt8}
    nmetadata::Int32
    metadata::Vector{image_metadata_t}
end

@lcmtypesetup(image_t,
    data => (size,),
    metadata => (nmetadata,)
)
