const ToT = UInt8
const ChannelID = UInt8
const DOMID = UInt32
const Floor = UInt8
const DU = UInt8
const HitTime = Float64

struct Position{T} <: FieldVector{3, T}
    x::T
    y::T
    z::T

    Position(x::T, y::T, z::T) where {T} = new{T}(x, y, z)
end

Position(x, y, z) = Position(promote(x, y, z)...)

# Base.*(x::Vector3D, y::Vector3D ) = Vector3D(SVector(y)* SVector(x))

struct Direction{T} <: FieldVector{3, T}
    x::T
    y::T
    z::T
end

Direction(x, y, z) = Direction(promote(x, y, z)...)

function Direction(ϕ, θ)
    Direction(cos(ϕ)*cos(θ), sin(ϕ)*cos(θ), sin(θ))
end

Base.show(io::IO, p::Position) = begin
    s = Printf.@sprintf "%.2f %.2f %.2f" p.x p.y p.z
    print(io, s)
end

Base.show(io::IO, d::Direction) = begin
    s = Printf.@sprintf "%.2f %.2f %.2f" d.x d.y d.z
    print(io, s)
end

struct MCEventInfo
    event_id::Int64
    group_id::Int64
    mc_id::Int64
    mc_time::Float64
    nanoseconds::Int64
    run_id::Int64
    timestamp::Int64
    weight_w1::Float64
    weight_w2::Float64
    weight_w3::Float64
    weight_w4::Float64
end

Base.show(io::IO, e::MCEventInfo) = begin
    print(io, "MCEventInfo: id($(e.event_id)), mc_id($(e.mc_id)), " *
          "mc_time($(e.mc_time) ($(e.nanoseconds)), ts($(e.timestamp)), run_id($(e.run_id))")
end

struct DAQEventInfo
    det_id::Int64
    event_id::Int64
    frame_index::Int64
    group_id::Int64
    mc_run_id::Int64
    mc_time::Float64
    nanoseconds::Int64
    overlays::Int64
    run_id::Int64
    timestamp::Int64
    trigger_counter::Int64
    trigger_mask::Int64
    weight_w1::Float64
    weight_w2::Float64
    weight_w3::Float64
    weight_w4::Float64
end

Base.show(io::IO, e::DAQEventInfo) = begin
    print(io, "DAQEventInfo: id($(e.event_id)), det_id($(e.det_id)), " *
          "timestamp($(e.timestamp) ($(e.nanoseconds)), run_id($(e.run_id))")
end

struct JMuon
    JENERGY_CHI2::Float64
    JENERGY_ENERGY::Float64
    JGANDALF_BETA0_RAD::Float64
    JGANDALF_BETA1_RAD::Float64
    JGANDALF_CHI2::Float64
    JGANDALF_LAMBDA::Float64
    JGANDALF_NUMBER_OF_HITS::Float64
    JGANDALF_NUMBER_OF_ITERATIONS::Float64
    JMUONENERGY::Bool
    JMUONGANDALF::Bool
    JMUONPREFIT::Bool
    JMUONSIMPLEX::Bool
    JMUONSTART::Bool
    JSTART_LENGTH_METRES::Float64
    JSTART_NPE_MIP::Float64
    JSTART_NPE_MIP_TOTAL::Float64
    dir_x::Float64
    dir_y::Float64
    dir_z::Float64
    energy::Float64
    group_id::Int64
    id::Int64
    length::Float64
    likelihood::Float64
    pos_x::Float64
    pos_y::Float64
    pos_z::Float64
    rec_type::Int64
    time::Float64
end

struct TimesliceInfo
    frame_index::UInt32
    slice_id::UInt32
    timestamp::UInt32
    nanoseconds::UInt32
    n_frames::UInt32
    group_id::UInt32
end

struct Track
    dir::Direction
    pos::Position
    time
end

# Fit
abstract type AbstractRecoTrack end

struct RecoTrack<:AbstractRecoTrack
    dir::Direction
    pos::Position
    time::Float64
end

struct NoRecoTrack<:AbstractRecoTrack end

# MC
struct MCTrack
    bjorken_y::Float64
    dir_x::Float64
    dir_y::Float64
    dir_z::Float64
    E::Float64
    group_id::Int64
    id::Int64
    interaction_channel::Int64
    is_cc::Bool
    length::Float64
    pos_x::Float64
    pos_y::Float64
    pos_z::Float64
    t::Float64
    particle_type::Int64
end

Track(t::MCTrack) = Track([t.dir_x, t.dir_y, t.dir_z], [t.pos_x, t.pos_y, t.pos_z], t.t)


Base.show(io::IO, t::MCTrack) = begin
    E = Printf.@sprintf "%0.1f" t.E
    bjorken_y = Printf.@sprintf "%0.2f" t.bjorken_y
    print(io, "MCTrack: bjorken_y($(bjorken_y)), t($(t.t)), " *
              "pos($(t.pos_x), $(t.pos_y), $(t.pos_z)), " *
              "dir($(t.dir_x), $(t.dir_y), $(t.dir_z)), " *
              "E($(E)), type($(t.particle_type))")
end


# Hardware
struct PMT
    channel_id::ChannelID
    pos::Position
    dir::Direction
end


struct DOM
    id::UInt32
    floor::Floor
    du::DU
    pmts::Vector{PMT}
end

struct Calibration
    det_id::Int32
    pos::Dict{Int32,Vector{NeRCA.Position}}
    dir::Dict{Int32,Vector{NeRCA.Direction}}
    t0::Dict{Int32,Vector{Float64}}
    du::Dict{Int32,DU}
    floor::Dict{Int32,Floor}
    max_z
    n_dus
end

Base.show(io::IO, c::Calibration) = begin
    print(io, "Calibration data for detector '$(c.det_id)' " *
              "with $(length(c.pos)) modules.")
end

# Signal
abstract type AbstractHit end
abstract type DAQHit<:AbstractHit end


Base.isless(lhs::AbstractHit, rhs::AbstractHit) = lhs.t < rhs.t


struct Hit <: DAQHit
    channel_id::ChannelID
    dom_id::DOMID
    t::HitTime
    tot::ToT
    triggered::Bool
end

Base.show(io::IO, h::DAQHit) = begin
    print(io, "$(typeof(h)): DOM ID $(h.dom_id), channel ID, $(h.channel_id), t=$(h.t), tot=$(h.tot)")
end

struct McHit <: AbstractHit
    a::Float32
    origin::UInt32
    pmt_id::UInt32
    t::HitTime
end

mutable struct Multiplicity
    count::Int32
    id::Int64
end

struct CalibratedHit <: DAQHit
    channel_id::ChannelID
    dom_id::UInt32
    du::DU
    floor::Floor
    t::HitTime
    tot::ToT
    pos::Position
    dir::Direction
    t0::HitTime
    triggered::Bool
    multiplicity::Multiplicity
end


struct TimesliceHit <: DAQHit
    channel_id::Int8
    dom_id::UInt32
    t::Int32
    tot::Int16
end

Hit(hit::HDF5.HDF5Compound{5}) = begin
    Hit(hit.data...)
end

const TriggerMask = Int64

struct DAQTriggeredHit <: DAQHit
    dom_id::Int32
    channel_id::UInt8
    t::Int32
    tot::UInt8
    trigger_mask::TriggerMask
end

struct DAQEvent
    det_id::Int32
    run_id::Int32
    timeslice_id::Int32
    timestamp::Int32
    ticks::Int32
    trigger_counter::Int64
    trigger_mask::Int64
    overlays::Int32
    n_triggered_hits::Int32
    triggered_hits::Vector{DAQTriggeredHit}
    n_hits::Int32
    hits::Vector{Hit}
end

Base.show(io::IO, d::DAQEvent) = begin
    print(io, "DAQEvent: $(d.n_triggered_hits) triggered hits, " *
              "$(d.n_hits) snapshot hits")
end


struct DAQEventFile
    filename
    n_events
    _fobj::HDF5.HDF5File
    _hit_indices
    _event_infos::Vector{DAQEventInfo}

    function DAQEventFile(filename)
        fobj = HDF5.h5open(filename, "r")
        event_infos = read_compound(fobj, "/event_info", DAQEventInfo)
        hit_indices = read_indices(fobj, "/hits")

        new(filename, length(event_infos), fobj, hit_indices, event_infos)
    end
end

Base.show(io::IO, f::DAQEventFile) = begin
    print(io, "DAQEventFile(\"$(f.filename)\")")
end


function read_io(io::IOBuffer, t::T) where T
    length = read(io, Int32)
    type = read(io, Int32)
    det_id = read(io, Int32)
    run_id = read(io, Int32)
    timeslice_id = read(io, Int32)
    timestamp = read(io, Int32)
    ticks = read(io, Int32)
    trigger_counter = read(io, Int64)
    trigger_mask = read(io, Int64)
    overlays = read(io, Int32)

    n_triggered_hits = read(io, Int32)
    triggered_hits = Vector{DAQTriggeredHit}()
    sizehint!(triggered_hits, n_triggered_hits)
    triggered_map = Dict{Tuple{Int32, UInt8, Int32, UInt8}, Int64}()
    @inbounds for i ∈ 1:n_triggered_hits
        dom_id = read(io, Int32)
        channel_id = read(io, UInt8)
        time = bswap(read(io, Int32))
        tot = read(io, UInt8)
        trigger_mask = read(io, Int64)
        triggered_map[(dom_id, channel_id, time, tot)] = trigger_mask
        push!(triggered_hits, DAQTriggeredHit(dom_id, channel_id, time, tot, trigger_mask))
    end

    n_hits = read(io, Int32)
    hits = Vector{Hit}()
    sizehint!(hits, n_hits)
    @inbounds for i ∈ 1:n_hits
        dom_id = read(io, Int32)
        channel_id = read(io, UInt8)
        time = bswap(read(io, Int32))
        tot = read(io, UInt8)
        key = (dom_id, channel_id, time, tot)
        triggered = false
        if haskey(triggered_map, key)
            triggered = true
        end
        push!(hits, Hit(channel_id, dom_id, time, tot, triggered))
    end

    DAQEvent(det_id, run_id, timeslice_id, timestamp, ticks, trigger_counter, trigger_mask, overlays, n_triggered_hits, triggered_hits, n_hits, hits)
end

struct EventReader
    filename::AbstractString
    detx::AbstractString
    _fobj::HDF5.HDF5File
    _calib::Calibration
    _event_infos::Vector{MCEventInfo}
    _mc_tracks::Dict{Int64, Vector{MCTrack}}
    _length::UInt64

    function EventReader(filename, detx)
        fobj = h5open(filename, "r")
        calib = read_calibration(detx)
        event_infos = read_compound(fobj, "/event_info", MCEventInfo)

        mc_tracks = Dict{Int64}{Vector{MCTrack}}()
        for track in read_compound(fobj, "/mc_tracks", MCTrack)
            group_id = track.group_id + 1
            if !haskey(mc_tracks, group_id)
                mc_tracks[group_id] = Vector{MCTrack}()
            end
            push!(mc_tracks[group_id], track)
        end

        n_events = length(event_infos)
        new(filename, detx, fobj, calib, event_infos, mc_tracks, n_events)
    end
end


Base.show(io::IO, e::EventReader) = begin
    print(io, join(["EventReader: $(e.filename)",
          "       detx: $(e.detx)",
          "     events: $(length(e))"], "\n"))
end

Base.length(e::EventReader) = e._length
Base.firstindex(E::EventReader) = 0
Base.lastindex(E::EventReader) = length(E)


mutable struct Event
    hits::Vector{Hit}
    mc_tracks::Vector{MCTrack}
    info::MCEventInfo
    calib::Calibration
end

function Base.iterate(iter::EventReader)
    group_id = 0
    (iter[group_id], group_id)
end

function Base.iterate(iter::EventReader, state)
    group_id = state + 1
    if group_id >= length(iter)
        return nothing
    end
    return (iter[group_id], group_id)
end

function Base.getindex(E::EventReader, i::Int)
    0 <= i < length(E) || throw(BoundsError(E, i))
    hits = read_hits(E._fobj, i)
    mc_tracks = E._mc_tracks[i+1]
    event_info = E._event_infos[i+1]
    Event(hits, mc_tracks, event_info, E._calib)
end
