mutable struct joint_state_t <: LCMType
    utime::Int64
    num_joints::Int16
    joint_name::Vector{String}
    joint_position::Vector{Float32}
    joint_velocity::Vector{Float32}
    joint_effort::Vector{Float32}
end

@lcmtypesetup(joint_state_t,
    joint_name => (num_joints,),
    joint_position => (num_joints,),
    joint_velocity => (num_joints,),
    joint_effort => (num_joints,),
)
