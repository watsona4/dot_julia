module EchoviewEcs

export load

MYFLOAT = Float32

"""
    FLOAT_LABELS

List of known calibration fields that contain floating point
values. Labels NOT in this list are assumed to be `String`s.

"""
FLOAT_LABELS = ["AbsorptionCoefficient",
     "EK60SaCorrection",
     "Ek60TransducerGain",
     "Frequency",
     "MajorAxis3dbBeamAngle",
     "MajorAxisAngleOffset",
     "MajorAxisAngleSensitivity",
     "MinorAxis3dbBeamAngle",
     "MinorAxisAngleOffset",
     "MinorAxisAngleSensitivity",
     "SoundSpeed",
     "TransmittedPower",
     "TransmittedPulseLength",
     "TwoWayBeamAngle"]

function load(lines::Vector{String})
    fileset = Dict()
    n = []
    m = fileset
    for line in lines
        if occursin("#", line)
            line = split(line, "#")[1]
        end
        if startswith(strip(line),"SourceCal")
            m = copy(fileset)
            push!(n,m)
        end
        if occursin("=", line) && m != nothing
            d = split(line, "=")
            k = strip(d[1])
            v =strip(d[2])
            if k in FLOAT_LABELS
                v = Base.parse(MYFLOAT,v)
            end
            m[k] =v
        end
    end

    return n
end

load(f::IOStream) = load(readlines(f))

"""
    load(filename::AbstractString)

Loads an Echoview calibration supplement file, returning
a `Vector` of `Dict`. Each `Dict` represents a transducer calibration
with keys and values containing the various calibration settings.

See [Echoview calibration supplement files](http://support.echoview.com/WebHelp/Reference/File_formats/Echoview_calibration_supplement_files.html).

"""
function load(filename::AbstractString)
    open(filename) do f
        load(f)
    end
end

end # module
