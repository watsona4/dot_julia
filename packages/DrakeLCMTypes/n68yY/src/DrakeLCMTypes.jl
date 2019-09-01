__precompile__()

module DrakeLCMTypes

using LCMCore
using StaticArrays: SVector, SMatrix

export body_motion_data_t,
       body_wrench_data_t,
       drake_signal_t,
       driving_control_cmd_t,
       external_force_torque_t,
       foot_flag_t,
       force_torque_t,
       joint_pd_override_t,
       piecewise_polynomial_t,
       polynomial_t,
       polynomial_matrix_t,
       qp_controller_input_t,
       quadrotor_input_t,
       quadrotor_output_t,
       robot_state_t,
       scope_data_t,
       simulation_command_t,
       support_data_t,
       whole_body_data_t,
       zmp_com_observer_state_t,
       zmp_data_t

include("polynomial_t.jl")
include("polynomial_matrix_t.jl")
include("piecewise_polynomial_t.jl")

include("body_wrench_data_t.jl")
include("body_motion_data_t.jl")
include("joint_pd_override_t.jl")
include("support_data_t.jl")
include("whole_body_data_t.jl")
include("zmp_data_t.jl")
include("qp_controller_input_t.jl")

include("drake_signal_t.jl")
include("driving_control_cmd_t.jl")
include("external_force_torque_t.jl")
include("foot_flag_t.jl")
include("force_torque_t.jl")
include("quadrotor_input_t.jl")
include("quadrotor_output_t.jl")
include("robot_state_t.jl")
include("scope_data_t.jl")
include("simulation_command_t.jl")
include("zmp_com_observer_state_t.jl")

end # module
