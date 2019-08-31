mutable struct twist_t <: LCMType
    linear_velocity::vector_3d_t
    angular_velocity::vector_3d_t
end

@lcmtypesetup(twist_t)
