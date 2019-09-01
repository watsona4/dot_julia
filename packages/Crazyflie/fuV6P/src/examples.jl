function motor_ramp_test(uri=_connect_first())
    play(uri) do cf
        cf.commander.send_setpoint(0, 0, 0, 0)
        thrust = 20000
        for i = 1:20
            cf.commander.send_setpoint(0, 0, 0, thrust)
            thrust += i > 10 ? -500 : 500
            sleep(0.1)
        end
        cf.commander.send_setpoint(0, 0, 0, 0)
        sleep(0.1)
    end
end
