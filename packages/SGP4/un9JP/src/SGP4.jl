# Julia wrapper for the sgp4 Python library:
# https://pypi.python.org/pypi/sgp4/

__precompile__()

module SGP4

using PyCall, Dates

import Base.getindex

const sgp4io = PyNULL()
const earth_gravity = PyNULL()
const sgp4_propagation = PyNULL()

function __init__()
    copy!(sgp4io, pyimport_conda("sgp4.io", "sgp4", "conda-forge"))
    copy!(earth_gravity, pyimport("sgp4.earth_gravity"))
    copy!(sgp4_propagation, pyimport("sgp4.propagation"))
end

export GravityModel,
       twoline2rv,
       propagate

struct GravityModel
    model::PyObject # can be any of {wgs72old, wgs72, wgs84}
end

mutable struct SGP4Sat
    s::PyObject
end
getindex(sat::SGP4Sat, sym::Symbol) = sat.s[sym]

GravityModel(ref::AbstractString) = GravityModel(earth_gravity[ref])

# sgp4.io convenience functions
function twoline2rv(line1::String, line2::String, grav::GravityModel)
    return SGP4Sat(sgp4io["twoline2rv"](line1,line2,grav.model))
end

function sgp4( sat::SGP4Sat,
               dtmin::Real )
    r,v = sgp4_propagation["sgp4"](sat.s, dtmin)
    return vcat(r...), vcat(v...)
end

"""
Propagate the satellite by `dtmin` minutes.

Returns (position, velocity)
"""
function propagate( sat::SGP4Sat,
                    dtmin::Real )
    sgp4(sat,dtmin)
end

function propagate(sats::Vector{SGP4Sat},
                   dtmin::Real)
    f = x->propagate(x, dtmin)
    f.(sats)
end

"""
Propagate the satellite from its epoch to the date/time specified

Returns (position, velocity) at the specified time
"""
function propagate( sat::SGP4Sat,
                    year::Real,
                    month::Real,
                    day::Real,
                    hour::Real,
                    min::Real,
                    sec::Real )
    (pos, vel) = sat.s[:propagate](year,month,day,hour,min,sec)

    # check for errors
    if sat.s[:error] != 0
        println(sat.s[:error_message])
    end

    return ([pos...],[vel...])
end

function propagate( sat::SGP4Sat,
                    t::DateTime )
    propagate(sat,
              Dates.year(t),
              Dates.month(t),
              Dates.day(t),
              Dates.hour(t),
              Dates.minute(t),
              Dates.second(t) + Dates.millisecond(t)/1000)
end

function propagate(sat::SGP4Sat,
                   t::AbstractVector{DateTime})
    pos = zeros(3, length(t)) 
    vel = zeros(3, length(t)) 

    for (idx, ti) in enumerate(t)
        pos[:,idx],vel[:,idx] = propagate(sat, ti)
    end
    return (pos,vel)
end

"Generate a satellite ephemeris"
function propagate( sat::SGP4Sat,
                    tstart::DateTime,
                    tstop::DateTime,
                    tstep::Dates.TimePeriod )
    propagate(sat, tstart:tstep:tstop)
end

"tstep specified in seconds"
function propagate( sat::SGP4Sat,
                    tstart::DateTime,
                    tstop::DateTime,
                    tstep::Real )
    propagate(sat,tstart,tstop,Dates.Second(tstep))
end

"Propagate many satellites to a common time"
function propagate( sats::Vector{SGP4Sat},
                    year::Real,
                    month::Real,
                    day::Real,
                    hour::Real,
                    min::Real,
                    sec::Real )
    f = x->propagate(x, year, month, day, hour, min, sec)
    f.(sats)
end

function propagate( sats::Vector{SGP4Sat},
                    t::DateTime )
    f = x->propagate(x, Dates.year(t), Dates.month(t), Dates.day(t), Dates.hour(t), Dates.minute(t), Dates.second(t) + Dates.millisecond(t)/1000)
    f.(sats)
end

end #module
