module Crazyflie

using PyCall

export scan, connect, disconnect
export motor_ramp_test

const bootloader = PyNULL()
const crtp = PyNULL()
const drivers = PyNULL()
const positioning = PyNULL()
const utils = PyNULL()
const crazyflie = PyNULL()
const synccrazyflie = PyNULL()

function __init__()
    copy!(bootloader, pyimport("cflib.bootloader"))
    copy!(crtp, pyimport("cflib.crtp"))
    copy!(drivers, pyimport("cflib.drivers"))
    copy!(positioning, pyimport("cflib.positioning"))
    copy!(utils, pyimport("cflib.utils"))
    copy!(crazyflie, pyimport("cflib.crazyflie"))
    copy!(synccrazyflie, pyimport("cflib.crazyflie.syncCrazyflie"))

    crtp.init_drivers(enable_debug_driver=false)
    nothing
end

function scan()
    available = crtp.scan_interfaces()
    if isempty(available)
        print("No crazyflies found.\n")
    end
    print("Found $(size(available, 1)) crazyflies:\n")
    for device in eachrow(available)
        print("\t" * device[1] * "\n")
    end
    nothing
end

function _first_available()
    available = crtp.scan_interfaces()
    if isempty(available)
        error("No crazyflies found. " *
              "Please specifiy a URI or try again. \n")
    end
    return available[1,1]
end

function connect(uri=_first_available())
    scf = synccrazyflie.SyncCrazyflie(uri, cf=crazyflie.Crazyflie(rw_cache="./cache"))
    scf.open_link()
    return scf
end

function play(alg, uri=_first_available())
    scf = connect(uri)
    alg(scf.cf)
    disconnect(scf)
end

function disconnect(scf)
    scf.close_link()
    nothing
end

include("examples.jl")

end # module
