# DrakeLCMTypes

[![Build Status](https://travis-ci.org/JuliaRobotics/DrakeLCMTypes.jl.svg?branch=master)](https://travis-ci.org/JuliaRobotics/DrakeLCMTypes.jl)
[![codecov.io](http://codecov.io/github/JuliaRobotics/DrakeLCMTypes.jl/coverage.svg?branch=master)](http://codecov.io/github/JuliaRobotics/DrakeLCMTypes.jl?branch=master)

This package implements the [LCM](http://lcm-proj.github.io/) type definitions from [Drake](http://drake.mit.edu/) in Julia using [LCMCore.jl](https://github.com/JuliaRobotics/LCMCore.jl). Each lcmtype has a matching native Julia type with associated `encode()` and `decode()` methods.

# Example

```julia
using DrakeLCMTypes, LCMCore

msg = polynomial_t()
msg.timestamp = 12345
msg.num_coefficients = 4
msg.coefficients = [1, 0, 2, 5]  # 1 + 0x + 2x^2 + 5x^3
bytes = encode(msg)

decoded = decode(bytes, polynomial_t)
@assert decoded.timestamp == msg.timestamp
@assert decoded.num_coefficients == msg.num_coefficients
@assert decoded.coefficients == msg.coefficients
```

# Exported Types

```julia
body_motion_data_t
body_wrench_data_t
drake_signal_t
driving_control_cmd_t
external_force_torque_t
foot_flag_t
force_torque_t
joint_pd_override_t
piecewise_polynomial_t
polynomial_t
polynomial_matrix_t
qp_controller_input_t
quadrotor_input_t
quadrotor_output_t
robot_state_t
scope_data_t
simulation_command_t
support_data_t
whole_body_data_t
zmp_com_observer_state_t
zmp_data_t
```
