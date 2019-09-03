module SimradEK60

using SimradRaw

export Sv, TS, pings, power, powerdb,  athwartshipangle, alongshipangle, R, filetime, power2db, octet2deg

# Float32 is okay for most practical purposes and within 10^-5 of EchoView
# Float64 gets to 10^-7 of Echoview
FLOAT_TYPE = Float32

################################################################################

# We split the RAW file into a series of EK60 specific pings.

# Whilst it is tempting to include latitude and longitude in the ping,
# this requires NMEA parsing and decisions about interpolation. Some
# people use external GPSs. Since the processing approach could be a
# user preference and potential source of errors, we choose not to
# include them. A caller can easily access NMEA datagrams produced by
# SimradRaw.jl and call PyNmea.

struct EK60Ping
    power::Vector{Int16}
    athwartshipangle::Vector{Int8}
    alongshipangle::Vector{Int8}
    filetime::UInt64
    frequency::FLOAT_TYPE
    soundvelocity::FLOAT_TYPE
    sampleinterval::FLOAT_TYPE
    absorptioncoefficient::FLOAT_TYPE
    transmitpower::FLOAT_TYPE
    pulselength::FLOAT_TYPE
    gain::FLOAT_TYPE
    equivalentbeamangle::FLOAT_TYPE
    sacorrection::FLOAT_TYPE
    sacorrectiontable::Vector{FLOAT_TYPE}
    pulselengthtable::Vector{FLOAT_TYPE}
end

################################################################################

function load(filename::AbstractString)
    ps = collect(pings(filename))
end

"""
    R(r, s, T)

TVG range correction for Ex60

R is the corrected range (m)

r the uncorrected range (m)

s is the TvgRangeCorrectionOffset value, See Echoview documentation,
Simrad Time Varied Gain (TVG) range correction, http://bit.ly/2pqzS2D

T is the sample thickness (m)
"""
R(r, s, T) = max.(0f0, r .- s*T)


"""
    R(ping::EK60Ping; soundvelocity = nothing, rangecorrectionoffset=2)

Returns the corrected range (depth) of samples in `ping`.
"""
function R(ping::EK60Ping; soundvelocity = nothing, rangecorrectionoffset=2)

    if soundvelocity == nothing
        soundvelocity = ping.soundvelocity
    end

    p = ping.power

    samplethickness = soundvelocity .* ping.sampleinterval / 2 # in metres of range

    r = [x* samplethickness for x in 0:length(p)-1]
    R(r, rangecorrectionoffset, samplethickness)

end

function R(pings::Vector{EK60Ping}; soundvelocity = nothing, rangecorrectionoffset=2)

    r = [R(ping,
           soundvelocity=soundvelocity,
           rangecorrectionoffset=rangecorrectionoffset) for ping in pings]

    myhcat(r)
    
end


R(pings::Channel{EK60Ping}; soundvelocity = nothing, rangecorrectionoffset=2) =
    R(collect(pings),
      soundvelocity=soundvelocity,
      rangecorrectionoffset=rangecorrectionoffset)

###

"""
    filetime(ping::EK60Ping)

Returns the FILETIME timestamp for a ping
"""
filetime(ping::EK60Ping) = ping.filetime

function filetime(pings::Vector{EK60Ping})
    [ping.filetime for ping in pings]
end

filetime(pings::Channel{EK60Ping}) = filetime(collect(pings))

################################################################################

# We must apply the SONAR equation and instrument corrections as
# described in http://bit.ly/2o1oOrq

## % An earlier MATLAB implementation
## % Sv = recvPower + 20 log10(Range) + (2 *  alpha * Range) - (10 * ...
## %           log10((xmitPower * (10^(gain/10))^2 * lambda^2 * ...
## %           c * tau * 10^(psi/10)) / (32 * pi^2)) - (2 * SaCorrection)

"""
    Sv(Pr, λ, G, Ψ, c, α, Pt, τ, Sa, R)
where:

R = the corrected range (m) - see TVG Range Correction

Pr = received power (dB re 1 W) - see Simrad EK numbers to Power

Pt = transmitted power (W)

α = absorption coefficient (dB/m)

G0 = transducer peak gain (non-dimensional) calculated as 10^(G/10)

G is the Transducer gain (dB re 1)

λ = wavelength (m) = c/f

f = frequency (Hz)

c = sound speed (m/s)

τ = transmit pulse duration (s) - also known as the
TransmittedPulseLength

ψ = Equivalent Two-way beam angle (Steradians) calculated as 10^(Ψ/10)

Ψ is the Two-way beam angle (dB re 1 Steradian)

Sa = Simrad correction factor (dB re 1m−1) determined during
calibration. This represents the correction required to the Sv
constant to harmonize the TS and NASC measurements.

"""
function Sv(Pr, λ, G, Ψ, c, α, Pt, τ, Sa, R)

    # TVG is applied to samples with ranges greater than 1 meter.
    tvg =  20log10.(max.(1, R))

    csv = 10log10.((Pt * (10^(G/10))^2 *  λ^2 * c * τ * 10^(Ψ/10)) /
                   (32 * FLOAT_TYPE(pi)^2))

    # Ignore absorption for R < 1m
    r =  [(x < 1) ? 0 : x for x in R]

    Pr .+ tvg + (2 * α * r) .- csv .- 2Sa
end

"""
     TS(Pr, λ, G, α, Pt, R)

Target strength

Pr = received power (dB re 1 W) - see Simrad EK numbers to Power

G is the Transducer gain (dB re 1)

α = absorption coefficient (dB/m)

Pt = transmitted power (W)

R = the corrected range (m) - see TVG Range Correction

"""
function TS(Pr, λ, G, α, Pt, R)

    # TVG is applied to samples with ranges greater than 1 meter.
    tvg =  40log10.(max.(1, R))

    csv = 10log10.((Pt * (10^(G/10))^2 *  λ^2) /
                   (16 * FLOAT_TYPE(pi)^2))

    # Ignore absorption for R < 1m
    r =  [(x < 1) ? 0 : x for x in R]

    Pr .+ tvg + (2 * α * r) .- csv
end

"""
    pings(datagrams::Channel{SimradRaw.Datagram})

Returns a `Channel` of `Ping`s from a `Channel` of `Datagram`s.

"""
function pings(datagrams::Channel{SimradRaw.Datagram})
    
    function _it(chn1)
        config = nothing
        for datagram in datagrams
            if datagram.dgheader.datagramtype == "RAW0"

                transducer = config.configurationtransducers[datagram.channel]

                #idx = findfirst(transducer.pulselengthtable, datagram.pulselength)
                idx = findfirst(isequal(datagram.pulselength), transducer.pulselengthtable)
                
                sacorrection = transducer.sacorrectiontable[idx]

                ping = EK60Ping(datagram.power,
                                datagram.athwartshipangle,
                                datagram.alongshipangle,
                                SimradRaw.filetime(datagram.dgheader.datetime),
                                datagram.frequency,
                                datagram.soundvelocity,
                                datagram.sampleinterval,
                                datagram.absorptioncoefficient,
                                datagram.transmitpower,
                                datagram.pulselength,
                                transducer.gain,
                                transducer.equivalentbeamangle,
                                sacorrection,
                                transducer.sacorrectiontable,
                                transducer.pulselengthtable)

                put!(chn1, ping)

            elseif datagram.dgheader.datagramtype == "CON0"
                config = datagram
            end
        end
    end

    return Channel(_it, ctype=EK60Ping)
end


function pings(datagrams::Vector{SimradRaw.Datagram})
    # Is there a neater method here?
    chnl = Channel(c->foreach(i->put!(c,i), datagrams), ctype=SimradRaw.Datagram)
    pings(chnl)
end

"""
    pings(filename::AbstractString)

Returns a `Channel` over `Ping`s from the RAW file designated by
`filename`.

"""
function pings(filename::AbstractString)
    pings([filename])
end

"""
    pings(filenames::Vector{AbstractString}})

Returns a `Channel` of `Pings` from the RAW files designated by
`filenames`.

"""
function pings(filenames::Vector{String})
    pings(datagrams(filenames))

end




"""
    Sv(ping::EK60Ping;
            frequency=nothing,
            gain=nothing,
            equivalentbeamangle=nothing,
            soundvelocity=nothing,
            absorptioncoefficient=nothing,
            transmitpower=nothing,
            pulselength=nothing,
            sacorrection=nothing,
            rangecorrectionoffset=2)

Returns a `Vector` of Sv, the (Mean) Volume backscattering strength (MVBS) in (dB re
1 m-1) for a given `ping`.

The function accepts a number of optional arguments which, if
specified, override the ping's own settings. This facilitates external
calibration.

"""
function Sv(ping::EK60Ping;
            frequency=nothing,
            gain=nothing,
            equivalentbeamangle=nothing,
            soundvelocity=nothing,
            absorptioncoefficient=nothing,
            transmitpower=nothing,
            pulselength=nothing,
            sacorrection=nothing,
            rangecorrectionoffset=2)

    if frequency == nothing
        frequency = ping.frequency
    end

    if gain == nothing
        gain = ping.gain
    end

    if equivalentbeamangle == nothing
        equivalentbeamangle = ping.equivalentbeamangle
    end

    if soundvelocity == nothing
        soundvelocity = ping.soundvelocity
    end

    if absorptioncoefficient == nothing
        absorptioncoefficient = ping.absorptioncoefficient
    end

    if transmitpower == nothing
        transmitpower= ping.transmitpower
    end

    if pulselength == nothing
        pulselength = ping.pulselength
    end

    if sacorrection == nothing
        sacorrection = ping.sacorrection
    end

    pdb = powerdb(ping)

    rangecorrected = R(ping,
                       soundvelocity = soundvelocity,
                       rangecorrectionoffset=rangecorrectionoffset)

    λ =  soundvelocity / frequency # calculate wavelength

    Sv(pdb, λ, gain, equivalentbeamangle,
            soundvelocity, absorptioncoefficient,
            transmitpower, pulselength, sacorrection,
            rangecorrected)

end



"""
    TS(ping::EK60Ping;
            frequency=nothing,
            gain=nothing,
            soundvelocity=nothing,
            absorptioncoefficient=nothing,
            transmitpower=nothing,
            rangecorrectionoffset=0)

Target strength

"""
function TS(ping::EK60Ping;
            frequency=nothing,
            gain=nothing,
            soundvelocity=nothing,
            absorptioncoefficient=nothing,
            transmitpower=nothing,
            rangecorrectionoffset=0)

    if frequency == nothing
        frequency = ping.frequency
    end

    if gain == nothing
        gain = ping.gain
    end

    if soundvelocity == nothing
        soundvelocity = ping.soundvelocity
    end

    if absorptioncoefficient == nothing
        absorptioncoefficient = ping.absorptioncoefficient
    end

    if transmitpower == nothing
        transmitpower= ping.transmitpower
    end

    pdb = powerdb(ping)

    rangecorrected = R(ping,
                       soundvelocity = soundvelocity,
                       rangecorrectionoffset = rangecorrectionoffset)

    λ =  soundvelocity / frequency # calculate wavelength

    TS(pdb, λ, gain, absorptioncoefficient, transmitpower, rangecorrected)

end


function myhcat(s; missingvalue=NaN32)
    ls = map(length,s)
    minlength =minimum(ls)
    maxlength =maximum(ls)
    if minlength == maxlength
        return hcat(s...)
    end

    etype = typeof(missingvalue)
    
    array = Array{etype}(undef, maxlength, length(s))

    array .= missingvalue
    for i in 1:length(s)
        r = 1:length(s[i])
        array[r, i] .= s[i][r]
    end
    return array
end

"""
    Sv(pings::Vector{EK60Ping};
        frequency=nothing,
        gain=nothing,
        equivalentbeamangle=nothing,
        soundvelocity=nothing,
        absorptioncoefficient=nothing,
        transmitpower=nothing,
        pulselength=nothing,
        sacorrection=nothing,
        rangecorrectionoffset=2)

Returns an `Array` of Sv, the Volume backscattering strength in (dB re
1 m-1) for a set of contiguous `pings`.

The function accepts a number of optional arguments which, if
specified, override the pings' own settings. This facilitates external
calibration.

"""
function Sv(pings::Vector{EK60Ping};
            frequency=nothing,
            gain=nothing,
            equivalentbeamangle=nothing,
            soundvelocity=nothing,
            absorptioncoefficient=nothing,
            transmitpower=nothing,
            pulselength=nothing,
            sacorrection=nothing,
            rangecorrectionoffset=2)
    s = [Sv(ping,
            frequency=frequency,
            gain=gain,
            equivalentbeamangle=equivalentbeamangle,
            soundvelocity=soundvelocity,
            absorptioncoefficient=absorptioncoefficient,
            transmitpower=transmitpower,
            pulselength=pulselength,
            sacorrection=sacorrection,
            rangecorrectionoffset=rangecorrectionoffset) for ping in pings]

    myhcat(s)
end

"""
    TS(pings::Vector{EK60Ping};
            frequency=nothing,
            gain=nothing,
            soundvelocity=nothing,
            absorptioncoefficient=nothing,
            transmitpower=nothing,
            rangecorrectionoffset=0)

Target strength
"""
function TS(pings::Vector{EK60Ping};
            frequency=nothing,
            gain=nothing,
            soundvelocity=nothing,
            absorptioncoefficient=nothing,
            transmitpower=nothing,
            rangecorrectionoffset=0)
    s = [TS(ping,
            frequency=frequency,
            gain=gain,
            soundvelocity=soundvelocity,
            absorptioncoefficient=absorptioncoefficient,
            transmitpower=transmitpower,
            rangecorrectionoffset=rangecorrectionoffset) for ping in pings]

    myhcat(s)
end



function Sv(pings::Channel{EK60Ping};
            frequency=nothing,
            gain=nothing,
            equivalentbeamangle=nothing,
            soundvelocity=nothing,
            absorptioncoefficient=nothing,
            transmitpower=nothing,
            pulselength=nothing,
            sacorrection=nothing,
            rangecorrectionoffset=2)
    Sv(collect(pings),
       frequency=frequency,
       gain=gain,
       equivalentbeamangle=equivalentbeamangle,
       soundvelocity=soundvelocity,
       absorptioncoefficient=absorptioncoefficient,
       transmitpower=transmitpower,
       pulselength=pulselength,
       sacorrection=sacorrection,
       rangecorrectionoffset=rangecorrectionoffset)
end



function TS(pings::Channel{EK60Ping};
            frequency=nothing,
            gain=nothing,
            soundvelocity=nothing,
            absorptioncoefficient=nothing,
            transmitpower=nothing,
            rangecorrectionoffset=0)
    TS(collect(pings),
       frequency=frequency,
       gain=gain,
       soundvelocity=soundvelocity,
       absorptioncoefficient=absorptioncoefficient,
       transmitpower=transmitpower,
       rangecorrectionoffset=rangecorrectionoffset)
end


#

"""
    athwartshipangle(ping::EK60Ping)

Returns the athwartship phase angle difference vector for the given
ping.

"""
athwartshipangle(ping::EK60Ping) = ping.athwartshipangle

function athwartshipangle(pings::Vector{EK60Ping})
    s = [ping.athwartshipangle for ping in pings]
    myhcat(s, missingvalue=Int8(0))
end

athwartshipangle(pings::Channel{EK60Ping}) = athwartshipangle(collect(pings))

@deprecate(athwartshipanglematrix, athwartshipangle)

#

"""
    alongshipangle(ping::EK60Ping)

Returns the alongship phase angle difference vector for the given
ping.

"""
alongshipangle(ping::EK60Ping) = ping.alongshipangle

function alongshipangle(pings::Vector{EK60Ping})
    s = [ping.alongshipangle for ping in pings]
    myhcat(s, missingvalue=Int8(0))
end

alongshipangle(pings::Channel{EK60Ping}) = alongshipangle(collect(pings))

@deprecate(alongshipanglematrix, alongshipangle)

#

"""
    power(ping::EK60Ping)

Returns power data for a ping in manufacturer units. For decibels,
see `powerdb`.

"""
power(ping::EK60Ping) = ping.power

function power(pings::Vector{EK60Ping})
    s = [ping.power for ping in pings]
    myhcat(s, missingvalue=Int16(0))
end

power(pings::Channel{EK60Ping}) = power(collect(pings))

#

const POWER_MULTIPLIER = FLOAT_TYPE(10 * log10(2) / 256)

"""
    power2db(x)

EK60 power data is stored in a "compressed", manufacturer specific
format. This function converts to decibels.

"""
power2db(x) = x * POWER_MULTIPLIER

"""
    powerdb(x)

Returns power data in decibels. x is one or more `Ping`s.

"""
powerdb(x) = power2db(power(x))


"""
    octet2deg(x)

EK60 split beam angles are stored as signed octets with a resolution
of 180/128.  Convert from octet to degrees.
"""
octet2deg(x) = x * 180/128

end # module
