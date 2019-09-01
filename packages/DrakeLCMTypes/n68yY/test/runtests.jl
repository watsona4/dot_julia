using DrakeLCMTypes
using Test
using LCMCore
using LCMCore: fingerprint

#=
The following Python code was used to retrieve all of the
fingerprints for the various drake lcmtypes automatically:

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

@testset "fingerprints" begin
    expected_fingerprints_network_order = Dict(
        body_motion_data_t => -1697438386000409426,
        body_wrench_data_t => 4386893263873254047,
        drake_signal_t => 7238120976706690118,
        driving_control_cmd_t => -6896084824078521841,
        foot_flag_t => -8864446532455026203,
        force_torque_t => -4222868804320616333,
        joint_pd_override_t => 5714105219971151977,
        piecewise_polynomial_t => -8838642192454639028,
        polynomial_t => 5357274285886765929,
        polynomial_matrix_t => -1258712767803654590,
        qp_controller_input_t => -3544374615258239713,
        quadrotor_input_t => 8036605081750588725,
        quadrotor_output_t => 2366092281809915326,
        robot_state_t => 8839665116654389949,
        scope_data_t => 6915476259009230748,
        simulation_command_t => 9013348952217922704,
        support_data_t => 6151770265999148129,
        whole_body_data_t => -2520944405135015033,
        zmp_com_observer_state_t => -35953723948848452,
        zmp_data_t => 7529117173982992449,
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

