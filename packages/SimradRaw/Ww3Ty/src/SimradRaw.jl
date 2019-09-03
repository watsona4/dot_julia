module SimradRaw

export datagrams, readencapsulateddatagram, readdatagramblock,
    readdatagrambody, readdatagram, readdatagramheader, Datagram,
    filetime

# References
# Simrad EK60 Context sensitive on-line help, Release 2.4.X,
# http://www.simrad.net/ek60_ref_english/default.htm

# Read low level C types

function readlong(stream::IO)
    read(stream, Int32)
end

function readshort(stream::IO)
    read(stream, Int16)
end

function readfloat(stream::IO)
    reinterpret(Float32, read(stream, 4))[1]
end

function readbytes(stream::IO, n::Integer)
    read(stream, n)
end

function readchars(stream::IO, n::Integer)
    String(read(stream, n))
end

function readstring(stream::IO, n::Integer)
    rstrip(readchars(stream, n), '\0')
end

function readfloats(stream::IO, n::Integer)
    reinterpret(Float32, read(stream, 4 * n))
end

function readshorts(stream::IO, n::Integer)
    b = Array{Int16}(undef,n)
    read!(stream, b)
    return b
end

function readint8s(stream::IO, n::Integer)
    b = Array{Int8}(undef,n)
    read!(stream, b)
    return b
end

function readushorts(stream::IO, n::Integer)
    read(stream, UInt16, n)
end

function readdword(stream::IO)
    read(stream, UInt32)
end

#

struct DateTime
    lowdatetime::UInt32
    highdatetime::UInt32
end

function readdatetime(stream::IO)
    lowdatetime = readdword(stream)
    highdatetime = readdword(stream)
    DateTime(lowdatetime, highdatetime)
end

"
Returns the filetime being the number of 100 nanosecond intervals
since January 1, 1601 of a given DateTime.
"
function filetime(d::DateTime)
    d.highdatetime * 4294967296 + d.lowdatetime
end

#

"""
    datagrams(filename, datagramreader=readdatagram)

`datagrams` returns an iterator over the datagrams in the RAW file
designated by `filename`.

"""
function datagrams(filename::AbstractString;
                   datagramreader=readdatagram::Function)

    datagrams([filename], datagramreader=datagramreader)
end

function datagrams(filenames::Vector{String};
                   datagramreader=readdatagram::Function)
    function _it(chn1)
        for filename in filenames
            
            # FIXME: The spec requires us to check endianness by comparing
            # length fields, but in practice, everyone is using PC/Windows
            
            open(filename) do f
                while !eof(f)
                    datagram = readencapsulateddatagram(f, datagramreader=datagramreader)
                    put!(chn1, datagram)
                end
            end
        end
    end

    return Channel(_it, ctype=Datagram)
end

#

function load(filename::AbstractString)
    collect(datagrams(filename))
end

#

function readencapsulateddatagram(stream::IO;
                                  datagramreader=readdatagram::Function)
    length = readlong(stream)
    datagram = datagramreader(stream, length)
    length2 = length = readlong(stream)

    if length != length2
        error("Invalid datagram")
    end
    datagram
end

#

abstract type Datagram end

struct DatagramHeader
    datagramtype::String
    datetime::DateTime
end

"""
    filetime(d::DatagramHeader)

Returns the filetime being the number of 100 nanosecond intervals
since January 1, 1601 of a given DatagramHeader.
"""
function filetime(d::DatagramHeader)
    filetime(d.datetime)
end


function readdatagramheader(stream::IO, length::Integer)
    headerlength = 12
    datagramtype = readchars(stream, 4)
    datetime = readdatetime(stream)
    l = length - headerlength
    dgheader = DatagramHeader(datagramtype, datetime)
    body = readdatagramblock(stream, l)

    return dgheader, body
end

function readdatagrambody(stream::IO, length::Integer, dgheader::DatagramHeader)

    datagramtype = dgheader.datagramtype

    if datagramtype == "XML0"
        return readxmldatagram(stream, length, dgheader)
    elseif datagramtype == "FIL1"
        return readbinarydatagram(stream, length, dgheader)
    elseif datagramtype == "CON0"
        return readconfigurationdatagram(stream, dgheader)
    elseif datagramtype == "NME0"
        return readtextdatagram(stream, length, dgheader)
    elseif datagramtype == "RAW0"
        return readsamplebinarydatagram0(stream, dgheader)
    elseif datagramtype == "RAW3"
        return readsamplebinarydatagram3(stream, dgheader)
    elseif datagramtype == "MRU0"
        return readmrudatagram(stream, dgheader)
    elseif datagramtype == "TAG0"
        return readtextdatagram(stream, length, dgheader)
    else
        warn("No implementation for ", datagramtype)
        return readbinarydatagram(stream, length, dgheader)
    end
end

function readdatagram(stream::IO, length::Integer)

    headerlength = 12
    datagramtype = readchars(stream, 4)
    datetime = readdatetime(stream)

    dgheader = DatagramHeader(datagramtype, datetime)

    l = length - headerlength

    return readdatagrambody(stream, l, dgheader)

end

#

function readdatagramblock(stream::IO, length::Integer)
    read(stream, length)
end

#

struct XMLDatagram <: Datagram
    dgheader::DatagramHeader
    text::String
end

function readxmldatagram(stream::IO, l::Integer, dgheader::DatagramHeader)
    text = readchars(stream, l)
    XMLDatagram(dgheader, text)
end

#

struct BinaryDatagram <: Datagram
    dgheader::DatagramHeader
    bytes
end

function readbinarydatagram(stream::IO, l::Integer, dgheader::DatagramHeader)
    bytes = read(stream, l)
    BinaryDatagram(dgheader, bytes)
end

# The MRU binary datagram contains motion sensor data

struct MRUDatagram <: Datagram
    dgheader::DatagramHeader
    heave::Float32
    roll::Float32
    pitch::Float32
    heading::Float32
end

function readmrudatagram(stream::IO, dgheader::DatagramHeader)
    heave =  readfloat(stream)
    roll = readfloat(stream)
    pitch = readfloat(stream)
    heading = readfloat(stream)

    MRUDatagram(dgheader, heave, roll, pitch, heading)
end

#

struct TextDatagram <: Datagram
    dgheader::DatagramHeader
    text::String
end

function readtextdatagram(stream::IO, length::Integer, dgheader::DatagramHeader)
    text = readchars(stream, length)
    TextDatagram(dgheader, text)
end

# EK80 sample datagram

struct SampleDatagram3 <: Datagram
    dgheader::DatagramHeader
    channelid::String
    datatype::Int16
    offset::Int32
    count::Int32
    samples # TODO
end

# The sample datagram 3 contains sample data from each "ping". The
# datagram may have a different size and contain different kind of
# data, depending on the DataType parameter.

function readsamplebinarydatagram3(stream::IO, dgheader::DatagramHeader)
    channelid = readstring(stream, 128)
    datatype = readshort(stream)
    spare = readchars(stream, 2)
    offset = readlong(stream);
    count = readlong(stream);

    # The number of values in Samples[] depends on the value of Count
    # and the Datatype.  As an example a DataType decimal value of
    # 1032 means that Samples[] contains ComplexFloat32 samples and
    # that each sample consists of 4 complex numbers (one from each of
    # the 4 transducer quadrants).

    if datatype == 1032
        samples = readbytes(stream, 4 * 2 * count * 4)
    else
        error("Datatype $(datatype) not yet implemented.")
    end

    SampleDatagram3(dgheader, channelid, datatype, offset, count, samples)
end

# EK60 sample datagram

struct SampleDatagram0 <: Datagram
    dgheader::DatagramHeader
    channel::Int16 # Channel number
    mode::Int16 # Datatype
    transducerdepth::Float32 # [m]
    frequency::Float32 # [Hz]
    transmitpower::Float32 # [W]
    pulselength::Float32 # [s]
    bandwidth::Float32 # [Hz]
    sampleinterval::Float32 # [s]
    soundvelocity::Float32 # [m/s]
    absorptioncoefficient::Float32 # [dB/m]
    heave::Float32 # [m]
    txroll::Float32 # [deg]
    txpitch::Float32 # [deg]
    temperature::Float32 # [C]
    rxroll::Float32 # [Deg]
    rxpitch::Float32 # [Deg]
    offset::Int32 #First sample
    count::Int32 # Number of samples
    power::Array{Int16} # Compressed format - See Remark 1!

    # 1. Power: The power data contained in the sample datagram is
    # compressed. In order to restore the correct value(s), you must
    # decompress the value according to the equation below.
    # y = x (10    # * log10(2) / 256) where: x = power value derived
    # from the datagram, y = converted value (in dB)

    athwartshipangle::Array{Int8}
    alongshipangle::Array{Int8} # See Remark 2 below!

    # 2. Angle: The fore-and-aft (alongship) and athwartship
    # electrical angles are output as one 16-bit word. The alongship
    # angle is the most significant byte while the athwartship angle
    # is the least significant byte. Angle data is expressed in 2's
    # complement format, and the resolution is given in steps of
    # 180/128 electrical degrees per unit. Positive numbers denotes
    # the fore and starboard directions.

end



function readsamplebinarydatagram0(stream::IO, dgheader::DatagramHeader)
    channel = readshort(stream) # Channel number
    mode = readshort(stream) # Datatype
    transducerdepth = readfloat(stream) # [m]
    frequency = readfloat(stream) # [Hz]
    transmitpower = readfloat(stream) # [W]
    pulselength = readfloat(stream) # [s]
    bandwidth = readfloat(stream) # [Hz]
    sampleinterval = readfloat(stream) # [s]
    soundvelocity = readfloat(stream) # [m/s]
    absorptioncoefficient = readfloat(stream) # [dB/m]
    heave = readfloat(stream) # [m]
    txroll = readfloat(stream) # [deg]
    txpitch = readfloat(stream) # [deg]
    temperature= readfloat(stream) # [C]
    spare = readshort(stream)
    spare = readshort(stream)
    rxroll = readfloat(stream) # [Deg]
    rxpitch = readfloat(stream) # [Deg]
    offset = readlong(stream) # First sample
    count = readlong(stream) # Number of samples

    power = readshorts(stream, count) # Compressed format - See Remark 1!

    athwartshipangle = []
    alongshipangle = []
    
    if mode != 1
        angles = readint8s(stream, count * 2)
        athwartshipangle = angles[1:2:end]
        alongshipangle = angles[2:2:end]
    end


    SampleDatagram0(dgheader, channel, mode, transducerdepth,
                    frequency, transmitpower, pulselength, bandwidth,
                    sampleinterval, soundvelocity,
                    absorptioncoefficient, heave, txroll, txpitch,
                    temperature, rxroll, rxpitch, offset, count,
                    power, athwartshipangle, alongshipangle)

end

# EK60 configuration datagram

struct ConfigurationHeader
    surveyname::String
    transectname::String
    soundername::String
    version::String
    transducercount::Int32
end

function readconfigurationheader(stream::IO)

    surveyname = readstring(stream, 128) # "Loch Ness"
    transectname = readstring(stream, 128)
    soundername = readstring(stream, 128) # "ER60"
    version = readstring(stream, 30)
    spare = readchars(stream, 98)
    transducercount = readlong(stream) # 1 to 7

    ConfigurationHeader(surveyname, transectname,
                        soundername, version, transducercount)

end

#



struct ConfigurationTransducer
    channelid::String
    beamtype # 0 = Single, 1 = Split
    frequency # [Hz]
    gain # [dB]
    equivalentbeamangle # [dB]
    beamwidthalongship # [degree]
    beamwidthathwartship # [degree]
    anglesensitibityalongship
    anglesensitivityathwartship
    angleoffsetalongship # [degree]
    angleoffsetathwartship # [degree]
    posx # future use
    posy # future use
    posz # future use
    dirx # future use
    diry # future use
    dirz # future use
    pulselengthtable # Available pulse lengths for the channel [s]
    gaintable # Gain for each pulse length in the PulseLengthTable [dB]
    sacorrectiontable # Sa correction for each pulse length in the
                      # PulseLengthTable [dB]
    gptsoftwareversion
end

function readconfigurationtransducer(stream::IO)
    channelid = readstring(stream, 128) # Channel identification
    beamtype = readlong(stream) # 0 = Single, 1 = Split
    frequency = readfloat(stream) # [Hz]
    gain = readfloat(stream) # [dB] - See note below
    equivalentbeamangle = readfloat(stream) # [dB]
    beamwidthalongship = readfloat(stream) # [degree]
    beamwidthathwartship = readfloat(stream) # [degree]
    anglesensitivityalongship= readfloat(stream)
    anglesensitivityathwartship = readfloat(stream)
    angleoffsetalongship = readfloat(stream) # [degree]
    angleoffsetathwartship = readfloat(stream) # [degree]
    posx = readfloat(stream) # future use
    posy = readfloat(stream) # future use
    posz = readfloat(stream) # future use
    dirx = readfloat(stream) # future use
    diry = readfloat(stream) # future use
    dirz = readfloat(stream) # future use
    pulselengthtable = readfloats(stream, 5) # Available pulse lengths for the channel [s]
    spare1 = readchars(stream, 8) # future use
    gaintable = readfloats(stream, 5) # Gain for each pulse length in the PulseLengthTable [dB]
    spare2 = readchars(stream, 8) # future use
    sacorrectiontable = readfloats(stream, 5) # Sa correction for each pulse length in the PulseLengthTable [dB]
    spare3 = readchars(stream, 8);
    gptsoftwareversion =readstring(stream, 16);
    spare4 = readchars(stream, 28);

    ConfigurationTransducer(channelid, beamtype, frequency, gain,
                            equivalentbeamangle, beamwidthalongship,
                            beamwidthathwartship,
                            anglesensitivityalongship,
                            anglesensitivityathwartship,
                            angleoffsetalongship,
                            angleoffsetathwartship, posx, posy, posz,
                            dirx, diry, dirz, pulselengthtable,
                            gaintable,
                            sacorrectiontable,
                            gptsoftwareversion)


end

#

struct ConfigurationDatagram <: Datagram
    dgheader::DatagramHeader
    configurationheader::ConfigurationHeader
    configurationtransducers::Array{ConfigurationTransducer}
end

function readconfigurationdatagram(stream::IO, dgheader::DatagramHeader)
    configurationheader = readconfigurationheader(stream);

    n =  configurationheader.transducercount
    configurationtransducers = []
    for i = 1:n
        configurationtransducer = readconfigurationtransducer(stream)
        push!(configurationtransducers, configurationtransducer)
    end

    ConfigurationDatagram(dgheader,
                          configurationheader,
                          configurationtransducers)
end

end # module
