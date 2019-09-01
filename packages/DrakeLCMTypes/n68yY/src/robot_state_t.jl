mutable struct robot_state_t <: LCMType
    timestamp::Int64

    num_robots::Int32
    robot_name::Vector{String}

    num_joints::Int32
    joint_robot::Vector{Int32}
    joint_name::Vector{String}

    joint_position::Vector{Float32}
    joint_velocity::Vector{Float32}
end

@lcmtypesetup(robot_state_t,
    robot_name => (num_robots,),
    joint_robot => (num_joints,),
    joint_name => (num_joints,),
    joint_position => (num_joints,),
    joint_velocity => (num_joints,),
)
