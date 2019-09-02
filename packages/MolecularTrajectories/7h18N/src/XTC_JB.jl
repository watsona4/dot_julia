# James W. Barnett
# jbarnet4@tulane.edu
# Julia module for reading in xtc file with libxdrfile

module Xtc_JB

export xtc_init, read_xtc, close_xtc

#libxdrfile = "/Users/tomlee/opt/xdrfile-1.1.1/lib/libxdrfile.dylib"

mutable struct xtcType
    natoms::Int32
    step::Vector{Int32}
    time::Vector{Float32}
    box::Matrix{Float32}
    x::Matrix{Float32}
    prec::Array{Float32}
    xd::Ptr{Cvoid}
end

function xtc_init(xtcfile) 
    if (!isfile(xtcfile)) 
        error(string(xtcfile," xtc file does not exist."))
    end

    # Get number of atoms in system
    natoms = Cint[0]
    stat = ccall( (:read_xtc_natoms,"libxdrfile"), Int32, (Ptr{UInt8},
        Ptr{Cint}), xtcfile, natoms)

    # Check if we actually did open the file
    if (stat != 0)
        error(string("Failure in opening ", xtcfile))
    end

    # Get C xdrfile pointer
    xd = ccall( (:xdrfile_open,"libxdrfile"), Ptr{Cvoid},
        (Ptr{UInt8},Ptr{UInt8}), xtcfile,"r")

    # Assign everything to this type
    xtc = xtcType(
        natoms[],
        Cint[0],
        Cfloat[0],
        zeros(Cfloat,(3,3)),
        zeros(Cfloat,(3,convert(Int64,(natoms[])))),
        Cfloat[0],
        xd)
    return stat, xtc
end

function read_xtc(xtc)
    stat = ccall( (:read_xtc,"libxdrfile"), Int32, ( Ptr{Cvoid}, Cint,
        Ptr{Cint}, Ptr{Cfloat}, Ptr{Cfloat}, Ptr{Cfloat}, Ptr{Cfloat} ), xtc.xd,
        xtc.natoms, xtc.step, xtc.time, xtc.box, xtc.x, xtc.prec) 
    if (stat != 0 | stat != 11)
        error("Failure in reading xtc frame. Code: $stat")
    end
    return stat
end

function close_xtc(xtc)
    stat = ccall( (:xdrfile_close,"libxdrfile"), Int32, ( Ptr{Cvoid}, ), xtc.xd)
    return stat
end

end
