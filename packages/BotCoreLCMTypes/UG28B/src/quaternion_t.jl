mutable struct quaternion_t <: LCMType
    w::Float64
    x::Float64
    y::Float64
    z::Float64
end

@lcmtypesetup(quaternion_t)
