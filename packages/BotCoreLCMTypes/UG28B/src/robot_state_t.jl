mutable struct robot_state_t <: LCMType
    utime::Int64
    pose::position_3d_t
    twist::twist_t
    num_joints::Int16
    joint_name::Vector{String}
    joint_position::Vector{Float32}
    joint_velocity::Vector{Float32}
    joint_effort::Vector{Float32}
    force_torque::force_torque_t
end

@lcmtypesetup(robot_state_t,
    joint_name => (num_joints,),
    joint_position => (num_joints,),
    joint_velocity => (num_joints,),
    joint_effort => (num_joints,),
)
