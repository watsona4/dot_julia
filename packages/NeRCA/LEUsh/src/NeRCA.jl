module NeRCA

using LinearAlgebra
using Printf
using Sockets
using DataStructures
using StaticArrays
using HDF5
using PGFPlotsX
using RecipesBase
using PlotThemes
using JuMP
using Ipopt
using Statistics

import Base: +, -, *

export
    Position, Direction,
    ChannelID, DOMID, ToT, Floor, DU, HitTime,
    MCEventInfo, MCTrack, Hit, CalibratedHit, McHit, TimesliceHit,
    RecoTrack, NoRecoTrack,
    DAQEvent, read_io,
    is_mxshower, is_3dmuon, is_3dshower,
    read_indices, read_hits, read_tracks, read_calibration, read_event_info,
    Calibration, calibrate,
    duhits, domhits, nfoldhits, triggered,
    mc_run_id,
    svdfit, matrix, rows,
    CHClient, CHTag, CHPrefix, CHMessage, subscribe,
    ztplot,
    savefigs,
    @ip_str


include("constants.jl")
include("types.jl")
include("tools.jl")
include("io.jl")
include("math.jl")
include("hits.jl")
include("mc.jl")
include("fit.jl")
include("controlhost.jl")
include("plot.jl")


"""
    function calibrate(hits::Vector{T}, calibration::Calibration) where {T<:DAQHit}

Apply geometry and time calibration to given hits.
"""
function calibrate(hits::Vector{T}, calibration::Calibration) where {T<:DAQHit}
    calibrated_hits = Vector{CalibratedHit}()
    for hit in hits
        dom_id = hit.dom_id
        channel_id = hit.channel_id
        tot = hit.tot
        pos = calibration.pos[dom_id][channel_id+1]
        dir = calibration.dir[dom_id][channel_id+1]
        t0 = calibration.t0[dom_id][channel_id+1]
        t = hit.t + t0
        du = calibration.du[dom_id]
        floor = calibration.floor[dom_id]
        triggered = false
        if T === Hit
            triggered = hit.triggered
        end
        if T === DAQTriggeredHit
            triggered = hit.trigger_mask > 0
        end
        c_hit = CalibratedHit(channel_id, dom_id, du, floor, t, tot,
                              pos, dir, t0, triggered, Multiplicity(0,0))
        push!(calibrated_hits, c_hit)
    end
    calibrated_hits
end

# Utility
rows(x) = (x[i, :] for i in indices(x,1))


# Math
Base.angle(d1::Direction, d2::Direction) = acos(dot(d1/norm(d1), d2/norm(d2)))
Base.angle(a::T, b::T) where {T<:Union{CalibratedHit, PMT, MCTrack}} = Base.angle(a.dir, b.dir)
Base.angle(a::FieldVector{3}, b::Union{CalibratedHit, PMT, MCTrack}) = Base.angle(a, b.dir)
Base.angle(a::Union{CalibratedHit, PMT, MCTrack}, b::FieldVector{3}) = Base.angle(a.dir, b)

function matrix(v::Vector)
    m = length(v)
    n = length(v[1])

    M = zeros(m, n)
    i = 1
    for j ∈ 1:n
        for k ∈ 1:m
            M[i] = v[k][j]
            i += 1
        end
    end
    M
end


function svdfit(M)
    com = mean(M, dims=1)
    subtr = M .- com
    U, S, V = svd(subtr)
    return com[:], V[:, 1]
end


end # module
