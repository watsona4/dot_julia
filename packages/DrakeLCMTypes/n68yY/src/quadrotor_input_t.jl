mutable struct quadrotor_input_t <: LCMType
    timestamp::Int64
    motors::SVector{4, Float64}
end

@lcmtypesetup(quadrotor_input_t)
