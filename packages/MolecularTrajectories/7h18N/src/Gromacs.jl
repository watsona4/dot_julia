
#export XTC, GroBox
export GroTrajectory, write_frame

using Base.Printf

include("XTC_JB.jl")

const xjb = Xtc_JB

struct XTC{V} <: AbstractTrajectory{Frame{V}}
    xtcjb::Vector{xjb.xtcType}
    function XTC{V}(filenames) where V
        #stat, xtcjb = xjb.xtc_init(filename)
        new{V}(
            [ last(xjb.xtc_init(filename)) for filename in filenames ]
        )
    end
end

XTC{V}(filenames::String...) where V = XTC{V}(filenames)

function Base.iterate(xtc::XTC{V}, state=1) where V
    nextstate = state
    while xjb.read_xtc(xtc.xtcjb[nextstate]) == 11 #EOF
        xjb.close_xtc(xtc.xtcjb[nextstate])
        nextstate = state + 1
        if nextstate > length(xtc.xtcjb)
            return nothing
        end
    end
    time = xtc.xtcjb[nextstate].time[1]
    x = xtc.xtcjb[nextstate].x
    positions = [
        V(x[1,i], x[2,i], x[3,i]) for i in 1:xtc.xtcjb[nextstate].natoms[1]
    ]
    bx = xtc.xtcjb[nextstate].box
    box_a = V(bx[1,1],bx[2,1],bx[3,1])
    box_b = V(bx[1,2],bx[2,2],bx[3,2])
    box_c = V(bx[1,3],bx[2,3],bx[3,3])
    box = Box{V,3(true,true,true)}((box_a, box_b, box_c))

    ( Frame{V}(time, box, positions, V[]), nextstate )
    
end

struct GroTrajectory{V} <: AbstractTrajectory{Frame{V}}
    filenames::Vector{String};
    dt::Float64
    function GroTrajectory{V}(
        filenames
        ;
        dt=0.0
    ) where V
        new{V}(collect(filenames), dt)
    end
end

function GroTrajectory{V}(filenames::String...; dt=0.0)  where V
    GroTrajectory{V}(filenames, dt=dt)
end

function gro_frame(io::IO, ::Type{V}, time = 0.0) where V
    lines = readlines(io)
    positions = map(@view(lines[3:end-1])) do line
        V(
            parse(Float64, line[21:28]),
            parse(Float64, line[29:36]),
            parse(Float64, line[37:44]),
        )
    end
    velocities = if 67 < length(lines[3])
        map(@view(lines[3:end-1])) do line
            V(
                parse(Float64, line[45:52]),
                parse(Float64, line[53:60]),
                parse(Float64, line[61:68]),
            )
        end
    else
        V[]
    end
    sides = V( map(x->parse(Float64, x), split(lines[end]))..., )
    Frame{V}(time, Box(sides), positions, velocities)
end

function Base.iterate(gro::GroTrajectory{V}, state=0) where V
    if state+1>length(gro.filenames)
        nothing
    else
        open(gro.filenames[state+1]) do f
            (
                gro_frame(f, V, (state+1)*gro.dt),
                state+1,
            )
        end
    end
end

function write_frame(output, format::Type{GroTrajectory}, frame, topology, comment="")
    println(output, comment)
    pos = frame.positions
    vel = if size(frame.velocities) == size(pos)
        frame.velocities
    else
        zeros(eltype(pos), size(pos))
    end
    t = topology
    println(output, length(pos))
    for i in eachindex(pos)
        Printf.@printf(
            output,
            "%5d%-5s%5s%5d%8.3f%8.3f%8.3f%8.4f%8.4f%8.4f\n",
            t.residue_indices[i],
            t.residue_names[i],
            t.atom_names[i],
            i,
            pos[i][1],
            pos[i][2],
            pos[i][3],
            vel[i][1],
            vel[i][2],
            vel[i][3],
        )
    end
    Lx,Ly,Lz = frame.box.lengths
    Printf.@printf output "%10.5f %9.5f %9.5f\n" Lx Ly Lz
end

