mutable struct body_wrench_data_t <: LCMType
    timestamp::Int64
    body_name::String
    wrench::SVector{6, Float64}
end

@lcmtypesetup(body_wrench_data_t)
