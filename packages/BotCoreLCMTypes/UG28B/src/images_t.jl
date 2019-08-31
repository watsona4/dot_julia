mutable struct images_t <: LCMType
    utime::Int64
    n_images::Int32
    image_types::Vector{Int16}
    images::Vector{image_t}
end

@lcmtypesetup(images_t,
    image_types => (n_images,),
    images => (n_images,),
)
