mutable struct position_3d_t <: LCMType
    translation::vector_3d_t
    rotation::quaternion_t
end

@lcmtypesetup(position_3d_t)
