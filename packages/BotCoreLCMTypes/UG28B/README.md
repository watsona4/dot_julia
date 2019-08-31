# BotCoreLCMTypes

[![Build Status](https://travis-ci.org/JuliaRobotics/BotCoreLCMTypes.jl.svg?branch=master)](https://travis-ci.org/JuliaRobotics/BotCoreLCMTypes.jl)
[![codecov.io](https://codecov.io/github/JuliaRobotics/BotCoreLCMTypes.jl/coverage.svg?branch=master)](https://codecov.io/github/JuliaRobotics/BotCoreLCMTypes.jl?branch=master)

This package implements the [LCM](http://lcm-proj.github.io/) type definitions from [openhumanoids/bot_core_lcmtypes](https://github.com/openhumanoids/bot_core_lcmtypes) in Julia using [LCMCore.jl](https://github.com/JuliaRobotics/LCMCore.jl). Each lcmtype has a matching native Julia type with associated `encode()` and `decode()` methods.

# Examples

```julia
using BotCoreLCMTypes, LCMCore

msg = vector_3d_t()
msg.x = 1
msg.y = 2
msg.z = 3
bytes = encode(msg)

decoded = decode(bytes, vector_3d_t)
@assert decoded.x == msg.x
@assert decoded.y == msg.y
@assert decoded.z == msg.z
```

# Exported Types

```julia
atlas_command_t
force_torque_t
gps_data_t
gps_satellite_info_list_t
gps_satellite_info_t
image_metadata_t
image_sync_t
image_t
images_t
ins_t
joint_angles_t
joint_state_t
kvh_raw_imu_batch_t
kvh_raw_imu_t
planar_lidar_t
pointcloud2_t
pointcloud_t
pointfield_t
pose_t
position_3d_t
quaternion_t
raw_t
rigid_transform_t
robot_state_t
robot_urdf_t
sensor_status_t
six_axis_force_torque_array_t
six_axis_force_torque_t
system_status_t
twist_t
utime_t
vector_3d_t
viewer_command_t
viewer_draw_t
viewer_geometry_data_t
viewer_link_data_t
viewer_load_robot_t
```