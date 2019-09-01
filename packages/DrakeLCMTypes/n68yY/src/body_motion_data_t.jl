mutable struct body_motion_data_t <: LCMType
    timestamp::Int64
    body_or_frame_name::String
    spline::piecewise_polynomial_t
    quat_task_to_world::SVector{4, Float64}
    translation_task_to_world::SVector{3, Float64}
    xyz_kp_multiplier::SVector{3, Float64}
    xyz_damping_ratio_multiplier::SVector{3, Float64}
    expmap_kp_multiplier::Float64
    expmap_damping_ratio_multiplier::Float64
    weight_multiplier::SVector{6, Float64}
    in_floating_base_nullspace::Bool
    control_pose_when_in_contact::Bool
end

@lcmtypesetup(body_motion_data_t)
