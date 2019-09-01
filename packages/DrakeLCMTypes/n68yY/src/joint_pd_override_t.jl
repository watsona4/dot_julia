mutable struct joint_pd_override_t <: LCMType
    timestamp::Int64
    position_ind::Int32
    qi_des::Float64
    qdi_des::Float64
    kp::Float64
    kd::Float64
    weight::Float64
end

@lcmtypesetup(joint_pd_override_t)
