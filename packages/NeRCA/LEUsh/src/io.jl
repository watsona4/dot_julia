# # I/O related functions
#
# The following function are used to read datastructures from KM3NeT
# dataformats like HDF5 or custom binary types.

"""
    function read_compound(dset::HDF5.HDF5Dataset, T::DataType)

Read an HDF5Compund structure from an HDF5 dataset.
"""
function read_compound(dset::HDF5.HDF5Dataset, T::DataType)
    filetype = HDF5.datatype(dset) # packed layout on disk
    memtype_id = HDF5.h5t_get_native_type(filetype.id) # padded layout in memory
    @assert sizeof(T) == HDF5.h5t_get_size(memtype_id) "Type sizes don't match!"
    out = Vector{T}(undef, length(dset))
    HDF5.h5d_read(dset.id, memtype_id, HDF5.H5S_ALL, HDF5.H5S_ALL, HDF5.H5P_DEFAULT, out)
    HDF5.h5t_close(memtype_id)
    out
end


function read_compound(filename::AbstractString,
                       h5loc::AbstractString,
                       T::DataType)
    fobj = HDF5.h5open(filename)
    data = read_compound(fobj, h5loc, T)
    close(fobj)
    data
end


function read_compound(fobj::HDF5.HDF5File,
                       h5loc::AbstractString,
                       T::DataType)
    data = read_compound(fobj[h5loc], T)
    data
end



function read_hits(fobj::HDF5.HDF5File, idx::Int, n_hits::Int)
    hits = Vector{Hit}()
    channel_id = fobj["hits/channel_id"][idx+1:idx+n_hits]
    dom_id = fobj["hits/dom_id"][idx+1:idx+n_hits]
    t = fobj["hits/time"][idx+1:idx+n_hits]
    tot = fobj["hits/tot"][idx+1:idx+n_hits]
    triggered = fobj["hits/triggered"][idx+1:idx+n_hits]
    for i ∈ 1:n_hits
        hit =  Hit(channel_id[i], dom_id[i], t[i], tot[i], triggered[i])
        push!(hits, hit)
    end
    return hits
end

function read_hits(fobj::HDF5.HDF5File, group_id::Int)
    hit_indices = read_indices(fobj, "/hits")
    idx = hit_indices[group_id+1][1]
    n_hits = hit_indices[group_id+1][2]
    hits = read_hits(fobj, idx, n_hits)::Vector{Hit}
    hits
end


function read_hits(filename::AbstractString, group_id::Int)
    f = h5open(filename, "r")
    hits = read_hits(f, group_id)
    close(f)
    return hits
end


function read_hits(filename::AbstractString,
                    group_ids::Union{Array{T}, UnitRange{T}}) where {T<:Integer}
    f = h5open(filename, "r")
    hit_indices = read_indices(f, "/hits")

    hits_collection = Dict{Int, Vector{Hit}}()
    for group_id ∈ group_ids
        idx = hit_indices[group_id+1][1]
        n_hits = hit_indices[group_id+1][2]
        hits = read_hits(f, idx, n_hits)::Vector{Hit}
        hits_collection[group_id] = hits
    end
    close(f)
    return hits_collection
end


function read_hits(f::DAQEventFile, group_id)
    idx = f._hit_indices[group_id+1][1]
    n_hits = f._hit_indices[group_id+1][2]
    read_hits(f._fobj, idx, n_hits)::Vector{Hit}
end


function read_mchits(fobj::HDF5.HDF5File, idx::Int, n_hits::Int)
    hits = Vector{McHit}()
    a = fobj["mc_hits/a"][idx+1:idx+n_hits]
    origin = fobj["mc_hits/origin"][idx+1:idx+n_hits]
    pmt_id = fobj["mc_hits/pmt_id"][idx+1:idx+n_hits]
    t = fobj["mc_hits/time"][idx+1:idx+n_hits]
    for i ∈ 1:n_hits
        hit =  McHit(a[i], origin[i], pmt_id[i], t[i])
        push!(hits, hit)
    end
    return hits
end


function read_mchits(filename::AbstractString, group_id::Int)
    f = h5open(filename, "r")
    hit_indices = read_indices(f, "/mc_hits")
    idx = hit_indices[group_id+1][1]
    n_hits = hit_indices[group_id+1][2]
    hits = read_mchits(f, idx, n_hits)::Vector{McHit}
    close(f)
    return hits
end


function read_mchits(filename::AbstractString,
                    group_ids::Union{Array{T}, UnitRange{T}}) where {T<:Integer}
    f = h5open(filename, "r")
    hit_indices = read_indices(f, "/mc_hits")

    hits_collection = Dict{Int, Vector{McHit}}()
    for group_id ∈ group_ids
        idx = hit_indices[group_id+1][1]
        n_hits = hit_indices[group_id+1][2]
        hits = read_hits(f, idx, n_hits)::Vector{McHit}
        hits_collection[group_id] = hits
    end
    close(f)
    return hits_collection
end

function read_mctracks(filename::AbstractString)
    mc_tracks = Dict{Int64}{Vector{MCTrack}}()
    for track in NeRCA.read_compound(filename, "/mc_tracks", MCTrack)
        group_id = track.group_id
        if !haskey(mc_tracks, group_id)
            mc_tracks[group_id] = Vector{MCTrack}()
        end
        push!(mc_tracks[group_id], track)
    end
    mc_tracks
end

function read_event_info(f::DAQEventFile, group_id)
    f._event_infos[group_id + 1]
end

function read_indices(filename::AbstractString, from::AbstractString)
    f = h5open(filename, "r")
    indices = read_indices(f, from)
    close(f)
    return indices
end


function read_indices(fobj::HDF5.HDF5File, from::AbstractString)
    idc = read(fobj, from * "/_indices")
    indices = [i.data for i ∈ idc]::Vector{Tuple{Int64,Int64}}
    return indices
end

function read_calibration(filename::AbstractString)
    lines = readlines(filename)
    filter!(e->!startswith(e, "#") && !isempty(strip(e)), lines)

    if 'v' ∈ first(lines)
        det_id, version = map(x->parse(Int,x), split(first(lines), 'v'))
        n_doms = parse(Int, lines[4])
        idx = 5
    else
        det_id, n_doms = map(x->parse(Int,x), split(first(lines)))
        version = 1
        idx = 2
    end

    pos = Dict{Int32,Vector{NeRCA.Position}}()
    dir = Dict{Int32,Vector{NeRCA.Direction}}()
    t0s = Dict{Int32,Vector{Float64}}()
    dus = Dict{Int32,UInt8}()
    floors = Dict{Int32,UInt8}()
    n_dus = length(keys(dus))

    max_z = 0.0
    for dom ∈ 1:n_doms
        dom_id, du, floor, n_pmts = map(x->parse(Int,x), split(lines[idx]))
        pos[dom_id] = Vector{NeRCA.Position}()
        dir[dom_id] = Vector{NeRCA.Direction}()
        t0s[dom_id] = Vector{Float64}()
        dus[dom_id] = du
        floors[dom_id] = floor

        for pmt in 1:n_pmts
            l = split(lines[idx+pmt])
            pmt_id = parse(Int,first(l))
            x, y, z, dx, dy, dz = map(x->parse(Float64, x), l[2:7])
            max_z = max(max_z, z)
            t0 = parse(Float64,l[8])
            push!(pos[dom_id], Position(x, y, z))
            push!(dir[dom_id], Direction(dx, dy, dz))
            push!(t0s[dom_id], t0)
        end
        idx += n_pmts + 1
    end
    Calibration(det_id, pos, dir, t0s, dus, floors, max_z, n_dus)
end

# Triggers
is_3dmuon(e::DAQEvent) = Bool(e.trigger_mask & 16 > 0)
is_3dshower(e::DAQEvent) = Bool(e.trigger_mask & 2 > 0)
is_mxshower(e::DAQEvent) = Bool(e.trigger_mask & 4 > 0)
