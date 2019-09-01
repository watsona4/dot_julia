# Crazyflie.jl

[![Build Status](https://travis-ci.org/arlk/Crazyflie.jl.svg?branch=master)](https://travis-ci.org/arlk/Crazyflie.jl) [![codecov](https://codecov.io/gh/arlk/Crazyflie.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/arlk/Crazyflie.jl)

This package provides a Julia interface for [crazyflie-lib-python](https://github.com/bitcraze/crazyflie-lib-python) to communicate with a [crazyflie](https://bitcraze.io).

## Installation

Follow directions from [crazyflie-lib-python](https://github.com/bitcraze/crazyflie-lib-python) to (system-wide) install the python library and any necessary dependencies. Then from the REPL

```julia
julia> ] add https://github.com/arlk/Crazyflie.jl
```

## Usage

#### Scan for crazyflies

```julia
julia> scan()
Found 2 crazyflies:
        radio://0/60/2M
        radio://0/80/2M
```

#### Run an algorithm

The `play` function takes the crazyflie [uri](https://wiki.bitcraze.io/doc:crazyflie:api:python:index#uniform_resource_identifier_uri) and the anonymous function in the `do...end` block as inputs:

```julia
play(uri) do cf
  # send commands
end
```

It constructs the [SyncCrazyflie](https://github.com/bitcraze/crazyflie-lib-python/blob/master/cflib/crazyflie/syncCrazyflie.py) python object, connects to the crazyflie, runs the provided algorithm, and disconnects from the crazyflie.

A motor ramp test example: This is already included in the [examples](https://github.com/arlk/Crazyflie.jl/blob/master/src/examples.jl) and can be invoked directly.

```julia
function motor_ramp_test(uri)
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
```
