mutable struct joint_angles_t <: LCMType
    utime::Int64
    robot_name::String
    num_joints::Int32
    joint_name::Vector{String}
    joint_position::Vector{Float64}
end

@lcmtypesetup(joint_angles_t,
    joint_name => (num_joints,),
    joint_position => (num_joints,)
)
