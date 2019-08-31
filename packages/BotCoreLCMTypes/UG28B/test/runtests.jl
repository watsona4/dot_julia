using BotCoreLCMTypes
using LCMCore
using LCMCore: fingerprint

using Test

#=
The following Python code was used to retrieve all of the
fingerprints for the various bot_core lcmtypes automatically:

import sys
import inspect
import struct
import bot_core

for name, obj in inspect.getmembers(bot_core):
    if inspect.isclass(obj):
        print("{:s} => {:d},".format(name, struct.unpack('q', obj._get_packed_fingerprint())[0]))

import sys
import inspect
import struct
import drake

for name, obj in inspect.getmembers(drake):
    if inspect.isclass(obj):
        print("{:s} => {:d},".format(name, struct.unpack('q', obj._get_packed_fingerprint())[0]))

=#


"""
Equality test for most types, but we compare LCMType instances
by looking at their fields, since otherwise == just falls back
to === which compares object identity and is thus not very
informative.
"""
closeenough(x, y) = x == y
function closeenough(x::LCMType, y::LCMType)
    (typeof(x) == typeof(y)) || return false
    for name in fieldnames(typeof(x))
        closeenough(getfield(x, name), getfield(y, name)) || return false
    end
    true
end


@testset "BotCoreLCMTypes" begin
    expected_fingerprints_network_order = Dict(
        atlas_command_t => 1312111223708868662,
        force_torque_t => -575550166132800226,
        gps_data_t => 1591358810433180375,
        gps_satellite_info_list_t => 6630954057076318457,
        gps_satellite_info_t => -3841388522418257571,
        image_metadata_t => -8143784636512515174,
        image_sync_t => 3436534526547922253,
        image_t => -1083725853459778796,
        images_t => 4243505650783468064,
        ins_t => 4613985382350956424,
        joint_angles_t => -8005155243827168194,
        joint_state_t => -6587704215521773762,
        kvh_raw_imu_batch_t => 8667107086997737736,
        kvh_raw_imu_t => 2860203241911737633,
        planar_lidar_t => -8260152468248931869,
        pointcloud2_t => 5339961563394395403,
        pointcloud_t => 7588611463407503629,
        pointfield_t => 7874274974017539762,
        pose_t => 6778111308394862126,
        position_3d_t => 8736894522790027246,
        quaternion_t => 2236618827848571702,
        raw_t => -8160235860338714832,
        rigid_transform_t => -5853054794096467990,
        robot_state_t => 8515145021206371399,
        robot_urdf_t => 6244330983731234563,
        sensor_status_t => -5959806439264436958,
        six_axis_force_torque_array_t => -6289052062373553992,
        six_axis_force_torque_t => -1425131401932437513,
        system_status_t => -5287778015234963678,
        twist_t => 5454792568601052517,
        utime_t => 3436534526547922253,
        vector_3d_t => 2207305183986155182,
        viewer_command_t => 3337564407834538480,
        viewer_draw_t => 4918545815192686401,
        viewer_geometry_data_t => 566142053834305117,
        viewer_link_data_t => 7145691636786734417,
        viewer_load_robot_t => 4120136222412670857,
    )

    for (lcmtype, fingerprint_network_order) in expected_fingerprints_network_order
        @testset "$lcmtype" begin
            @testset "constructor" begin
                msg = lcmtype()
                for name in fieldnames(typeof(msg))
                    @test closeenough(getfield(msg, name), LCMCore.defaultval(typeof(getfield(msg, name))))
                end
            end
            @testset "fingerprint" begin
                @test hton(fingerprint(lcmtype)) == fingerprint_network_order
            end
        end
    end
end
