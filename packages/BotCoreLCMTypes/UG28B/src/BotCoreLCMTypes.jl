__precompile__()

module BotCoreLCMTypes

using LCMCore
using StaticArrays: SVector

export atlas_command_t,
       force_torque_t,
       gps_data_t,
       gps_satellite_info_list_t,
       gps_satellite_info_t,
       image_metadata_t,
       image_sync_t,
       image_t,
       images_t,
       ins_t,
       joint_angles_t,
       joint_state_t,
       kvh_raw_imu_batch_t,
       kvh_raw_imu_t,
       planar_lidar_t,
       pointcloud2_t,
       pointcloud_t,
       pointfield_t,
       pose_t,
       position_3d_t,
       quaternion_t,
       raw_t,
       rigid_transform_t,
       robot_state_t,
       robot_urdf_t,
       sensor_status_t,
       six_axis_force_torque_array_t,
       six_axis_force_torque_t,
       system_status_t,
       twist_t,
       utime_t,
       vector_3d_t,
       viewer_command_t,
       viewer_draw_t,
       viewer_geometry_data_t,
       viewer_link_data_t,
       viewer_load_robot_t

include("atlas_command_t.jl")
include("force_torque_t.jl")
include("gps_data_t.jl")
include("gps_satellite_info_t.jl")
include("gps_satellite_info_list_t.jl")
include("image_metadata_t.jl")
include("image_sync_t.jl")
include("image_t.jl")
include("images_t.jl")
include("ins_t.jl")
include("joint_angles_t.jl")
include("joint_state_t.jl")
include("kvh_raw_imu_t.jl")
include("kvh_raw_imu_batch_t.jl")
include("planar_lidar_t.jl")
include("pointfield_t.jl")
include("pointcloud2_t.jl")
include("pointcloud_t.jl")
include("pose_t.jl")
include("vector_3d_t.jl")
include("quaternion_t.jl")
include("position_3d_t.jl")
include("twist_t.jl")
include("raw_t.jl")
include("rigid_transform_t.jl")
include("robot_state_t.jl")
include("robot_urdf_t.jl")
include("sensor_status_t.jl")
include("six_axis_force_torque_t.jl")
include("six_axis_force_torque_array_t.jl")
include("system_status_t.jl")
include("utime_t.jl")
include("viewer_command_t.jl")
include("viewer_draw_t.jl")
include("viewer_geometry_data_t.jl")
include("viewer_link_data_t.jl")
include("viewer_load_robot_t.jl")
end
