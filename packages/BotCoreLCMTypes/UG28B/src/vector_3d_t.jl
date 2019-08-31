mutable struct vector_3d_t <: LCMType
    x::Float64
    y::Float64
    z::Float64
end

@lcmtypesetup(vector_3d_t)
