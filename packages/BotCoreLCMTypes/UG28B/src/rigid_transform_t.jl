mutable struct rigid_transform_t <: LCMType
    utime::Int64
    trans::SVector{3, Float64}
    quat::SVector{4, Float64}
end

@lcmtypesetup(rigid_transform_t)
