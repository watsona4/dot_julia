"""
modeled after the DRCSIM AtlasCommand ROS message, but updated for the atlas hardware API.
control parameter spec:
  * q, qd, f are sensed position, velocity, torque, from AtlasJointState
  * q_d, qd_d, f_d are desired position, velocity, torque, from
    AtlasJointDesired

  The final joint command will be:
   k_q_p   * ( q_d - q )     +
   k_q_i   * 1/s * ( q_d - q ) +
   k_qd_p  * ( qd_d - qd )   +
   k_f_p   * ( f_d - f )     +
   ff_qd   * qd        +
   ff_qd_d   * qd_d        +
   ff_f_d  * f_d         +
   ff_const
"""
mutable struct atlas_command_t <: LCMType
    utime::Int64
    num_joints::Int32
    joint_names::Vector{String}
    position::Vector{Float64}
    velocity::Vector{Float64}
    effort::Vector{Float64}

    k_q_p::Vector{Float64}
    k_q_i::Vector{Float64}
    k_qd_p::Vector{Float64}
    k_f_p::Vector{Float64}
    ff_qd::Vector{Float64}  # maps to kd_position in drcsim API (there isnt an equivalent gain in the bdi api)
    ff_qd_d::Vector{Float64}
    ff_f_d::Vector{Float64}
    ff_const::Vector{Float64}

    # k_torque can be an unsigned int 8value from 0 to 255,
    # at run time, a double between 0 and 1 is obtained
    # by dividing by 255.0d.
    k_effort::Vector{UInt8}

    # max allowed controller update period in milli-seconds simulation time
    # for controller synchronization. See SynchronizationStatistics.msg for
    # tracking synchronization status.
    desired_controller_period_ms::UInt8
end

@lcmtypesetup(atlas_command_t,
    joint_names => (num_joints,),
    position => (num_joints,),
    velocity => (num_joints,),
    effort => (num_joints,),
    k_q_p => (num_joints,),
    k_q_i => (num_joints,),
    k_qd_p => (num_joints,),
    k_f_p => (num_joints,),
    ff_qd => (num_joints,),
    ff_qd_d => (num_joints,),
    ff_f_d => (num_joints,),
    ff_const => (num_joints,),
    k_effort => (num_joints,),
)
