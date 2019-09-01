mutable struct driving_control_cmd_t <: LCMType
    timestamp::Int64
    steering_angle::Float64
    throttle_value::Float64
    brake_value::Float64
end

@lcmtypesetup(driving_control_cmd_t)
