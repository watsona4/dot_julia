mutable struct qp_controller_input_t <: LCMType
    be_silent::Bool
    timestamp::Int64
    zmp_data::zmp_data_t

    num_support_data::Int32
    support_data::Vector{support_data_t}

    num_tracked_bodies::Int32
    body_motion_data::Vector{body_motion_data_t}

    num_external_wrenches::Int32
    body_wrench_data::Vector{body_wrench_data_t}

    whole_body_data::whole_body_data_t

    num_joint_pd_overrides::Int32
    joint_pd_override::Vector{joint_pd_override_t}

    param_set_name::String
    torque_alpha_filter::Float64
end

@lcmtypesetup(qp_controller_input_t,
    support_data => (num_support_data,),
    body_motion_data => (num_tracked_bodies,),
    body_wrench_data => (num_external_wrenches,),
    joint_pd_override => (num_joint_pd_overrides,),
)
