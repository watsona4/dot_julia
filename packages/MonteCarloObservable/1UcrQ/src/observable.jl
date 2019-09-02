const SUPPORTED_TYPES = Union{Array{<:Number}, Number}

"""
A Markov Chain Monte Carlo observable.
"""
mutable struct Observable{MeasurementType<:SUPPORTED_TYPES, MeanType<:SUPPORTED_TYPES, InMemory} <: AbstractObservable

    # parameters (external)
    name::String
    alloc::Int
    outfile::String
    group::String # where to put data in JLD file

    # internal
    n_meas::Int # total number of measurements
    elsize::Tuple{Vararg{Int}}
    n_dims::Int
    timeseries::Vector{MeasurementType}
    tsidx::Int # points to next free slot in timeseries (!= n_meas+1 for inmemory == false)
    colons::Vector{Colon} # substitute for .. for JLD datasets

    mean::MeanType # estimate for mean

    Observable{T, MT, IM}() where {T, MT, IM} = new()
end




# -------------------------------------------------------------------------
#   Constructor / Initialization
# -------------------------------------------------------------------------
"""
    Observable(t, name; keyargs...)

Create an observable of type `t`.

The following keywords are allowed:

* `alloc`: preallocated size of time series container
* `outfile`: default HDF5/JLD output file for io operations
* `group`: target path within `outfile`
* `inmemory`: wether to keep the time series in memory or on disk
* `meantype`: type of the mean (should be compatible with measurement type `t`)

See also [`Observable`](@ref).
"""
function Observable(::Type{T};
                    name::String="unnamed",
                    alloc::Int=1000,
                    inmemory::Bool=true,
                    outfile::String="Observables.jld",
                    group::String=name,
                    meantype::DataType=Type{Union{}}) where T

    @assert T <: SUPPORTED_TYPES "Only numbers or arrays of numbers supported as measurement types."
    @assert isconcretetype(T) "Type must be concrete."

    # load old memory dump if !inmemory
    oldfound = false
    if !inmemory && isfile(outfile)
        jldopen(outfile) do f
            HDF5.has(f.plain, group) && (oldfound = true)
        end
    end
    oldfound && (return loadobs_frommemory(outfile, group))


    # trying to find sensible DataType for mean if not given
    mt = meantype
    if mt == Type{Union{}} # not set
        if eltype(T)<:Real
            mt = ndims(T)>0 ? Array{Float64, ndims(T)} : Float64
        else
            mt = ndims(T)>0 ? Array{ComplexF64, ndims(T)} : ComplexF64
        end
    end

    @assert ndims(T) == ndims(mt)

    obs = Observable{T, mt, inmemory}()
    obs.name = name
    obs.alloc = alloc
    obs.outfile = outfile
    obs.group = group

    _init!(obs)
    return obs
end

Observable(::Type{T}, name::String; kw...) where T = Observable(T; name=name, kw...)

DiskObservable(args...; kw...) = Observable(args...; kw..., inmemory=false)




"""
    _init!(obs)

Initialize non-external fields of observable `obs`.
"""
function _init!(obs::Observable{T}) where T
    # internal
    obs.n_meas = 0
    obs.elsize = (-1,) # will be determined on first push! call
    obs.colons = [Colon() for _ in 1:ndims(T)]
    obs.n_dims = ndims(T)

    obs.tsidx = 1
    obs.timeseries = Vector{T}(undef, obs.alloc) # init with Missing values in Julia 1.0?

    if ndims(T) == 0
        obs.mean = convert(T, zero(eltype(T)))
    else
        obs.mean = convert(T, fill(zero(eltype(T)), fill(0, ndims(T))...))
    end
    nothing
end


"""
    reset!(obs::Observable{T})

Resets all measurement information in `obs`.
"""
reset!(obs::Observable{T}) where T = _init!(obs)









# -------------------------------------------------------------------------
#   Constructor macros
# -------------------------------------------------------------------------
"""
Convenience macro for generating an Observable from a vector of measurements.
"""
macro obs(arg)
    return quote
        # local o = Observable($(esc(eltype))($(esc(arg))), $(esc(string(arg))))
        local o = Observable($(esc(eltype))($(esc(arg))), "unnamed")
        push!(o, $(esc(arg)))
        o
    end
end

"""
Convenience macro for generating a "disk observable" (`inmemory=false`) from a vector of measurements.
"""
macro diskobs(arg)
    return quote
        # local o = Observable($(esc(eltype))($(esc(arg))), $(esc(string(arg))))
        local o = Observable($(esc(eltype))($(esc(arg))), "unnamed"; inmemory=false)
        push!(o, $(esc(arg)))
        o
    end
end







# -------------------------------------------------------------------------
#   Basic properties (mostly adding methods to Base functions)
# -------------------------------------------------------------------------
"""
    eltype(obs::Observable{T})

Returns the type `T` of a measurment of the observable.
"""
@inline Base.eltype(obs::Observable{T}) where T = T

"""
Length of observable's time series.
"""
@inline Base.length(obs::Observable{T}) where T = obs.n_meas

"""
Last index of the observable's time series.
"""
@inline Base.lastindex(obs::Observable{T}) where T = length(obs)

"""
Size of the observable (of one measurement).
"""
@inline Base.size(obs::Observable{T}) where T = obs.elsize

"""
Number of dimensions of the observable (of one measurement).

Equivalent to `ndims(T)`.
"""
@inline Base.ndims(obs::Observable{T}) where T = ndims(T)

"""
Returns `true` if the observable hasn't been measured yet.
"""
Base.isempty(obs::Observable{T}) where T = obs.n_meas == 0

"""
    iterate(iter [, state]) -> Tuple{Array{Complex{Float64},1},Int64}

Implementation of Julia's iterator interface
"""
Base.iterate(obs::Observable, state::Int=0) = state+1 <= length(obs) ? (obs[state+1], state+1) : nothing
# TODO: Maybe optimize for disk observables, i.e. load full timeseries in start

"""
Name of the Observable.
"""
name(obs::Observable{T}) where T = obs.name

"""
    rename(obs::Observable, name)

Renames the observable.
"""
rename!(obs::Observable{T}, name::AbstractString) where T = begin obs.name = name; nothing end

"""
Checks wether the observable is kept in memory (vs. on disk).
"""
@inline inmemory(obs::Observable{T, MT, IM}) where {T, MT, IM} = IM

"""
Checks wether the observable is kept in memory (vs. on disk).
"""
@inline isinmemory(obs::Observable) = inmemory(obs)

"""
Check if two observables have equal timeseries.
"""
function Base.:(==)(a::Observable, b::Observable)
    timeseries(a) == timeseries(b)
end






# -------------------------------------------------------------------------
#   Cosmetics: Base.show, Base.summary
# -------------------------------------------------------------------------
function _println_header(io::IO, obs::Observable{T}) where T
    sizestr = ""
    if length(obs) > 0 
        if ndims(T) == 0
            nothing
        elseif ndims(T) == 1
            @inbounds sizestr = "$(size(obs)[1])-element "
        else
            sizestr = string(join(size(obs), "x"), " ")
        end
    end
    # disk = inmemory(obs) ? "" : "Disk-"
    println(io, "$(sizestr)$(T) Observable")
    nothing
end

function _println_body(io::IO, obs::Observable{T}) where T
    println("| Name: ", name(obs))
    !inmemory(obs) && print("| In Memory: ", false,"\n")
    print("| Measurements: ", length(obs))
    if length(obs) > 0
        if ndims(obs) == 0
            print("\n| Mean: ", round(mean(obs), digits=5))
            print("\n| Std: ", round(std(obs), digits=5))
        end
    end
end

Base.show(io::IO, obs::Observable{T}) where T = begin
    _println_header(io, obs)
    _println_body(io, obs)
    nothing
end
Base.show(io::IO, m::MIME"text/plain", obs::Observable{T}) where T = print(io, obs)

Base.summary(io::IO, obs::Observable{T}) where T = _println_header(io, obs)
Base.summary(obs::Observable{T}) where T = summary(stdout, obs)










# -------------------------------------------------------------------------
#   push! and push!
# -------------------------------------------------------------------------
"""
Add measurements to an observable.

    push!(obs::Observable{T}, measurement::T; verbose=false)
    push!(obs::Observable{T}, measurements::AbstractArray{T}; verbose=false)

Note that because of internal preallocation this isn't really a push.
"""
function Base.push!(obs::Observable) end




# adding single: numbers
Base.push!(obs::Observable{T}, measurement::S; kw...) where {T<:Number, S<:Number} = _push!(obs, measurement; kw...);

# adding single: arrays
Base.push!(obs::Observable{Array{T,N}}, measurement::AbstractArray{S,N}; kw...) where {T, S<:Number, N} = _push!(obs, measurement; kw...);

# adding multiple: vector of measurements
function Base.push!(obs::Observable{T}, measurements::AbstractVector{T}; kw...) where T
    @inbounds for i in eachindex(measurements)
        _push!(obs, measurements[i]; kw...)
    end
    nothing
end

# adding multiple: arrays one dimension higher (last dim == ts dim)
function Base.push!(obs::Observable{T}, measurements::AbstractArray{S, N}; kw...) where {T,S<:Number,N}
    N == obs.n_dims + 1 || throw(DimensionMismatch("Dimensions of given measurements ($(N-1)) don't match observable's dimensions ($(obs.n_dims))."))
    length(obs) == 0 || size(measurements)[1:N-1] == obs.elsize || error("Sizes of measurements don't match observable size.")

    @inbounds for i in Base.axes(measurements, ndims(measurements))
        _push!(obs, measurements[.., i]; kw...)
    end
    nothing
end


Base.append!(obs::Observable, measurement; kwargs...) = push!(obs, measurement; kwargs...)


# implementation
@inline function _push!(obs::Observable{T}, measurement; verbose=false) where T
    if obs.elsize == (-1,) # first add
        obs.elsize = size(measurement)
        obs.mean = zero(measurement)
    end

    size(measurement) == obs.elsize || error("Measurement size != observable size")

    # add to time series
    verbose && println("Adding measurment to time series [chunk].")
    obs.timeseries[obs.tsidx] = copy(measurement)
    obs.tsidx += 1

    # update mean estimate
    verbose && println("Updating mean estimate.")
    obs.mean = (obs.n_meas * obs.mean + measurement) / (obs.n_meas + 1)
    obs.n_meas += 1

    if obs.tsidx == length(obs.timeseries)+1 # next push! would overflow
        verbose && println("Handling time series [chunk] overflow.")
        if inmemory(obs)
            verbose && println("Increasing time series size.")
            tslength = length(obs.timeseries)
            new_timeseries = Vector{T}(undef, tslength + obs.alloc)
            new_timeseries[1:tslength] = obs.timeseries
            obs.timeseries = new_timeseries
        else
            verbose && println("Dumping time series chunk to disk.")
            flush(obs)
            verbose && println("Setting time series index to 1.")
            obs.tsidx = 1
        end
    end
    verbose && println("Done.")
    nothing
end





"""
    flush(obs::Observable)

This is the crucial function if `inmemory(obs) == false`. It updates the time series on disk.
It is called from `push!` everytime the alloc limit is reached (overflow).

You can call the function manually to save an intermediate state.
"""
function Base.flush(obs::Observable)
    @assert !isinmemory(obs) "Can only flush disk observables (`!inmemory(obs)`)."

    fname = obs.outfile
    grp = endswith(obs.group, "/") ? obs.group : obs.group*"/"
    tsgrp = joinpath(grp, "timeseries")
    alloc = obs.alloc

    try
        jldopen(fname, isfile(fname) ? "r+" : "w", compress=true) do f
            if !HDF5.has(f.plain, grp) # first flush?
                write(f, joinpath(grp,"count"), length(obs))
                write(f, joinpath(grp, "mean"), mean(obs))

                write(f, joinpath(grp, "name"), name(obs))
                write(f, joinpath(grp, "alloc"), obs.alloc)
                write(f, joinpath(grp, "elsize"), [obs.elsize...])
                write(f, joinpath(grp, "eltype"), string(eltype(obs)))
                write(f, joinpath(tsgrp,"chunk_count"), 1)
                if obs.tsidx == length(obs.timeseries) + 1 # regular flush
                    # write full chunk
                    write(f, joinpath(tsgrp,"ts_chunk1"), TimeSeriesSerializer(obs.timeseries))
                else # (early) manual flush
                    # write partial chunk
                    hdf5ver = HDF5.libversion
                    hdf5ver >= v"1.10" || @warn "HDF5 version $(hdf5ver) < 1.10.x Manual flushing might lead to larger output file because space won't be freed on dataset delete."
                    write(f, joinpath(tsgrp,"ts_chunk1"), TimeSeriesSerializer(obs.timeseries[1:obs.tsidx-1]))
                end

            else # not first flush
                c = read(f[joinpath(grp, "count")])
                cc = read(f[joinpath(tsgrp, "chunk_count")])

                if !(cc * alloc == c) # was last flushed manually
                    # delete last incomplete chunk
                    delete!(f, joinpath(tsgrp, "ts_chunk$(cc)"))
                    cc -= 1
                end

                if obs.tsidx == length(obs.timeseries) + 1 # regular flush
                    # write full chunk
                    write(f, joinpath(tsgrp,"ts_chunk$(cc+1)"), TimeSeriesSerializer(obs.timeseries))
                else # (early) manual flush
                    obs.tsidx == 1 && (return nothing) # there is nothing to flush

                    # write partial chunk
                    hdf5ver = HDF5.libversion
                    hdf5ver >= v"1.10" || @warn "HDF5 version $(hdf5ver) < 1.10.x Manual flushing might lead to larger output file because space won't be freed on dataset delete."
                    write(f, joinpath(tsgrp,"ts_chunk$(cc+1)"), TimeSeriesSerializer(obs.timeseries[1:obs.tsidx-1]))
                end

                delete!(f, joinpath(tsgrp, "chunk_count"))
                write(f, joinpath(tsgrp,"chunk_count"), cc+1)

                delete!(f, joinpath(grp, "count"))
                write(f, joinpath(grp,"count"), length(obs))

                delete!(f, joinpath(grp, "mean"))
                write(f, joinpath(grp, "mean"), mean(obs))
            end
        end
    catch er
        error("Couldn't update observable on disk! Error: ", er)
    end

    nothing
end









# -------------------------------------------------------------------------
#   getindex, view, and timeseries access
# -------------------------------------------------------------------------
"""
Returns the time series of the observable.

If `isinmemory(obs) == false` it will read the time series from disk.

See also [`getindex`](@ref) and [`view`](@ref).
"""
timeseries(obs::Observable{T}) where T = obs[1:end]
ts(obs::Observable) = timeseries(obs)



# interface
"""
    view(obs::Observable{T}, args...)

Get, if possible, a view into the time series of the observable.
"""
function Base.view(obs::Observable) end

"""
    getindex(obs::Observable{T}, args...)

Get an element of the time series of the observable.
"""
function Base.getindex(obs::Observable) end




# implementation
function Base.view(obs::Observable{T}, idx::Int) where T
    1 <= idx <= length(obs) || throw(BoundsError(typeof(obs), idx))
    if inmemory(obs)
        view(obs.timeseries, idx)
    else
        error("Only supported for `inmemory(obs) == true`. Alternatively, load the timeseries as an array (e.g. with timeseries_frommemory_flat) and use views into this array.");
    end
end
function Base.view(obs::Observable{T}, rng::UnitRange{Int}) where T
    rng.start >= 1 && rng.stop <= length(obs) || throw(BoundsError(typeof(obs), rng))
    if inmemory(obs)
        view(obs.timeseries, rng)
    else
        error("Only supported for `inmemory(obs) == true`. Alternatively, load the timeseries as an array (e.g. with timeseries_frommemory_flat) and use views into this array.");
    end
end
Base.view(obs::Observable, c::Colon) = view(obs, 1:length(obs))




function Base.getindex(obs::Observable{T}, idx::Int) where T
    1 <= idx <= length(obs) || throw(BoundsError(typeof(obs), idx))
    if inmemory(obs)
        return getindex(obs.timeseries, idx)
    else
        if length(obs) < obs.alloc # no chunk dumped to disk yet
            return obs.timeseries[idx]
        else
            return getindex_fromfile(obs, idx)
        end
    end
end
function Base.getindex(obs::Observable{T}, rng::UnitRange{Int}) where T
    rng.start >= 1 && rng.stop <= length(obs) || throw(BoundsError(typeof(obs), rng))
    if inmemory(obs)
        return getindex(obs.timeseries, rng)
    else
        if length(obs) < obs.alloc # no chunk dumped to disk yet
            return obs.timeseries[rng]
        else
            return getindexrange_fromfile(obs, rng)
        end
    end
end
Base.getindex(obs::Observable, c::Colon) = getindex(obs, 1:length(obs))




# disk observables: get from file
function getindex_fromfile(obs::Observable{T}, idx::Int)::T where T
    tsgrp = joinpath(obs.group, "timeseries/")

    currmemchunk = ceil(Int, obs.n_meas / obs.alloc)
    chunknr = ceil(Int,idx / obs.alloc)
    idx_in_chunk = mod1(idx, obs.alloc)

    if chunknr != currmemchunk
        return _getindex_ts_chunk(obs, chunknr, idx_in_chunk)
    else
        if idx_in_chunk < obs.tsidx
            return obs.timeseries[idx_in_chunk]
        else
            return _getindex_ts_chunk(obs, chunknr, idx_in_chunk)
        end
    end
end


function getindexrange_fromfile(obs::Observable{T}, rng::UnitRange{Int})::Vector{T} where T

    getchunknr = i -> fld1(i, obs.alloc)
    chunknr_start = getchunknr(rng.start)
    chunknr_stop = getchunknr(rng.stop)
    
    chunkidx_first_start = mod1(rng.start, obs.alloc)
    chunkidx_first_stop = chunknr_start * obs.alloc
    chunkidx_last_start = 1
    chunkidx_last_stop = mod1(rng.stop, obs.alloc)

    if chunknr_start == chunknr_stop # all in one chunk
        startidx = mod1(rng.start, obs.alloc)
        stopidx = mod1(rng.stop, obs.alloc)
        return _getindex_ts_chunk(obs, chunknr_start, startidx:stopidx)
    else
        # fallback: load full time series and extract range
        return vcat(timeseries_frommemory(obs), obs.timeseries[1:obs.tsidx-1])[rng]

        # While the following is cheaper on memory, it is much(!) slower. TODO: bring it up to speed
        # v = Vector{T}(undef, length(rng))
        # i = 1 # pointer to first free slot in v
        # @indbounds for c in chunknr_start:chunknr_stop
        #     if c == chunknr_start
        #         r = chunkidx_first_start:chunkidx_first_stop

        #         _getindex_ts_chunk!(v[1:length(r)], obs, c, r)
        #         i += length(r)

        #     elseif c == chunknr_stop
        #         r = chunkidx_last_start:chunkidx_last_stop
        #         _getindex_ts_chunk!(v[i:lastindex(v)], obs, c, r)
        #     else
        #         _getindex_ts_chunk!(v[i:(i+obs.alloc-1)], obs, c, Colon())
        #         i += obs.alloc
        #     end
        # end

        # return v

    end
end



function _getindex_ts_chunk(obs::Observable{T}, chunknr::Int, idx_in_chunk::Int)::T where T
    tsgrp = joinpath(obs.group, "timeseries/")

    # Use hyperslab to only read the requested element from disk
    return jldopen(obs.outfile, "r") do f
        val = f[joinpath(tsgrp, "ts_chunk$(chunknr)")][obs.colons..., idx_in_chunk]
        res = dropdims(val, dims=obs.n_dims+1)
        return ndims(T) == 0 ? res[1] : res
    end
end

function _getindex_ts_chunk(obs::Observable{T}, chunknr::Int, rng::UnitRange{Int})::Vector{T} where T
    tsgrp = joinpath(obs.group, "timeseries/")

    # Use hyperslab to only read the requested elements from disk
    return jldopen(obs.outfile, "r") do f
        val = f[joinpath(tsgrp, "ts_chunk$(chunknr)")][obs.colons..., rng]
        return [val[.., i] for i in 1:size(val, ndims(val))]
    end
end

function _getindex_ts_chunk(obs::Observable{T}, chunknr::Int, c::Colon)::Vector{T} where T
    _getindex_ts_chunk(obs, chunknr, 1:obs.alloc)
end




# function _getindex_ts_chunk!(out::AbstractVector{T}, obs::Observable{T}, chunknr::Int, rng::UnitRange{Int})::Nothing where T
#     @assert length(out) == length(rng)
#     tsgrp = joinpath(obs.group, "timeseries/")

#     # Use hyperslab to only read the requested elements from disk
#     jldopen(obs.outfile, "r") do f
#         val = f[joinpath(tsgrp, "ts_chunk$(chunknr)")][obs.colons..., rng]
#         # return [val[.., i] for i in 1:size(val, ndims(val))]

#         for i in 1:size(val, ndims(val))
#             out[i] = val[.., i]
#         end
#     end
#     nothing
# end

# function _getindex_ts_chunk!(out::AbstractVector{T}, obs::Observable{T}, chunknr::Int, c::Colon)::Nothing where T
#     _getindex_ts_chunk!(out, obs, chunknr, 1:obs.alloc)
#     nothing
# end
































# -------------------------------------------------------------------------
#   Exporting results
# -------------------------------------------------------------------------
"""
    export_results(obs::Observable{T}[, filename::AbstractString, group::AbstractString; timeseries::Bool=false])

Export result for given observable nicely to JLD.

Will export name, number of measurements, estimates for mean and one-sigma error.
Optionally (`timeseries==true`) exports the full time series as well.
"""
function export_result(obs::Observable{T}, filename::AbstractString=obs.outfile, group::AbstractString=obs.group*"_export"; timeseries=false, error=true) where T
    grp = endswith(group, "/") ? group : group*"/"

    jldopen(filename, isfile(filename) ? "r+" : "w") do f
        !HDF5.has(f.plain, grp) || delete!(f, grp)
        write(f, joinpath(grp, "name"), name(obs))
        write(f, joinpath(grp, "count"), length(obs))
        timeseries && write(f, joinpath(grp, "timeseries"), TimeSeriesSerializer(MonteCarloObservable.timeseries(obs)))
        write(f, joinpath(grp, "mean"), mean(obs))
        if error
            err = std_error(obs)
            write(f, joinpath(grp, "error"), err)
            write(f, joinpath(grp, "error_rel"), abs.(err./mean(obs)))
        end
    end
    nothing
end



"""
    export_error(obs::Observable{T}[, filename::AbstractString, group::AbstractString;])

Export one-sigma error estimate and convergence flag.
"""
function export_error(obs::Observable{T}, filename::AbstractString=obs.outfile, group::AbstractString=obs.group) where T
    grp = endswith(group, "/") ? group : group*"/"

    jldopen(filename, isfile(filename) ? "r+" : "w") do f
        !HDF5.has(f.plain, grp*"error") || delete!(f, grp*"error")
        !HDF5.has(f.plain, grp*"error_rel") || delete!(f, grp*"error_rel")
        err = std_error(obs)
        write(f, joinpath(grp, "error"), err)
        write(f, joinpath(grp, "error_rel"), abs.(err./mean(obs)))
    end
    nothing
end









# -------------------------------------------------------------------------
#   load things from memory dump
# -------------------------------------------------------------------------
"""
    loadobs_frommemory(filename::AbstractString, group::AbstractString)

Create an observable based on a memory dump (`inmemory==false`).
"""
function loadobs_frommemory(filename::AbstractString, group::AbstractString)
    grp = endswith(group, "/") ? group : group*"/"
    tsgrp = joinpath(grp, "timeseries")

    isfile(filename) || error("File not found.")

    jldopen(filename) do f
        HDF5.has(f.plain, grp) || error("Group not found in file.")
        name = read(f, joinpath(grp, "name"))
        alloc = read(f, joinpath(grp, "alloc"))
        outfile = filename
        group = grp[1:end-1]
        c = read(f, joinpath(grp, "count"))
        elsize = Tuple(read(f,joinpath(grp, "elsize")))
        element_type = read(f, joinpath(grp, "eltype"))
        themean = read(f,joinpath(grp, "mean"))
        cc = read(f,joinpath(tsgrp, "chunk_count"))

        T = jltype(element_type)
        MT = typeof(themean)
        obs = Observable{T, MT, false}()

        obs.name = name
        obs.alloc = alloc
        obs.outfile = outfile
        obs.group = group
        _init!(obs)

        obs.n_meas = c
        obs.elsize = elsize
        obs.mean = themean

        if !(cc * alloc == c) # was last flushed manually
            last_ts_chunk = read(f, joinpath(tsgrp, "ts_chunk$(cc)"))
            for i in axes(last_ts_chunk, ndims(last_ts_chunk))
                obs.timeseries[i] = last_ts_chunk[..,i]
            end
            obs.tsidx = size(last_ts_chunk, ndims(last_ts_chunk)) + 1
        end

        return obs
    end
end




mean_frommemory(filename::AbstractString, group::AbstractString) = _frommemory(filename, group, "mean")
error_frommemory(filename::AbstractString, group::AbstractString) = _frommemory(filename, group, "error")
function _frommemory(filename::AbstractString, group::AbstractString, field::AbstractString)
    grp = endswith(group, "/") ? group : group*"/"
    d = joinpath(grp, field)
    return jldopen(filename) do f
        return read(f[d])
    end
end




# time series
timeseries(filename::AbstractString, group::AbstractString; kw...) = timeseries_frommemory(filename, group; kw...)
ts(filename::AbstractString, group::AbstractString; kw...) = timeseries_frommemory(filename, group; kw...)
"""
    timeseries_frommemory(filename::AbstractString, group::AbstractString)

Load time series from memory dump (`inmemory==false`) in HDF5/JLD file.

Will load and concatenate time series chunks. Output will be a vector of measurements.
"""
function timeseries_frommemory(filename::AbstractString, group::AbstractString; kw...)
    ts = timeseries_frommemory_flat(filename, group; kw...)
    r = [ts[.., i] for i in 1:size(ts, ndims(ts))]
    return r
end
timeseries_frommemory(obs::Observable{T}; kw...) where T = timeseries_frommemory(obs.outfile, obs.group; kw...)





timeseries_flat(filename::AbstractString, group::AbstractString; kw...) = timeseries_frommemory_flat(filename, group; kw...)
ts_flat(filename::AbstractString, group::AbstractString; kw...) = timeseries_frommemory_flat(filename, group; kw...)
"""
    timeseries_frommemory_flat(filename::AbstractString, group::AbstractString)

Load time series from memory dump (`inmemory==false`) in HDF5/JLD file.

Will load and concatenate time series chunks. Output will be higher-dimensional
array whose last dimension corresponds to Monte Carlo time.
"""
function timeseries_frommemory_flat(filename::AbstractString, group::AbstractString; verbose=false)
    grp = endswith(group, "/") ? group : group*"/"
    tsgrp = joinpath(grp, "timeseries")

    isfile(filename) || error("File not found.")
    jldopen(filename) do f
        HDF5.has(f.plain, grp) || error("Group not found in file.")
        if typeof(f[grp]) == JLD.JldGroup && HDF5.has(f.plain, tsgrp) && typeof(f[tsgrp]) == JLD.JldGroup
            # n_meas = read(f, joinpath(grp, "count"))
            element_type = read(f, joinpath(grp, "eltype"))
            chunk_count = read(f,joinpath(tsgrp, "chunk_count"))
            T = jltype(element_type)

            firstchunk = read(f, joinpath(tsgrp,"ts_chunk1"))
            # ignore potential empty last chunk
            lastchunk = read(f, joinpath(tsgrp,"ts_chunk$(chunk_count)"))
            if length(lastchunk) == 0
                chunk_count -= 1
            end
            
            chunks = Vector{typeof(firstchunk)}(undef, chunk_count)
            chunks[1] = firstchunk


            for c in 2:chunk_count
                chunks[c] = read(f, joinpath(tsgrp,"ts_chunk$(c)"))
            end

            flat_timeseries = cat(chunks..., dims=ndims(T)+1)

            return flat_timeseries

        else
            if typeof(f[grp]) == JLD.JldDataset
                return read(f, grp)
            elseif HDF5.has(f.plain, joinpath(grp, "timeseries"))
                verbose && println("Loading time series (export_result or old format).")
                flat_timeseries = read(f, joinpath(grp, "timeseries"))
                return flat_timeseries

            elseif HDF5.has(f.plain, joinpath(grp, "timeseries_real"))
                verbose && println("Loading complex time series (old format).")
                flat_timeseries = read(f, joinpath(grp, "timeseries_real")) + im*read(f, joinpath(grp, "timeseries_imag"))
                return flat_timeseries

            else
                error("No timeseries/observable found.")
            end
        end
    end
end















# -------------------------------------------------------------------------
#   Basic Statistics
# -------------------------------------------------------------------------
"""
Mean of the observable's time series.
"""
Statistics.mean(obs::Observable{T}) where T = length(obs) > 0 ? obs.mean : error("Can't calculate mean of empty observable.")

"""
Standard deviation of the observable's time series (assuming uncorrelated data).

See also [`mean(obs)`](@ref), [`var(obs)`](@ref), and [`std_error(obs)`](@ref).
"""
Statistics.std(obs::Observable{T}) where T = length(obs) > 0 ? std(timeseries(obs)) : error("Can't calculate std of empty observable.")

"""
Variance of the observable's time series (assuming uncorrelated data).

See also [`mean(obs)`](@ref), [`std(obs)`](@ref), and [`std_error(obs)`](@ref).
"""
Statistics.var(obs::Observable{T}) where T = length(obs) > 0 ? var(timeseries(obs)) : error("Can't calculate variance of empty observable.")







# -------------------------------------------------------------------------
#   Statistics: error estimation
# -------------------------------------------------------------------------
"""
    std_error(obs::Observable[; method=:full])

Estimates the standard error of the mean.
Respects correlations between measurements through binning analysis.

Optional `method` keyword can be `:log`, `:full`, or `:jackknife`.

See also [`mean(obs)`](@ref).
"""
BinningAnalysis.std_error(obs::Observable; method=:full) = BinningAnalysis.std_error(ts(obs); method=method)


"""
Integrated autocorrelation time (obtained by binning analysis).

See also [`error(obs)`](@ref).
"""
BinningAnalysis.tau(obs::Observable) = BinningAnalysis.tau(ts(obs))


"""
    jackknife(g::Function, obs1, ob2, ...)

Computes the jackknife one sigma error of `g(obs1, obs2, ...)` by performing 
a "leave-one-out" analysis.

See BinningAnalysis.jl for more details.
"""
BinningAnalysis.jackknife(g::Function, obs::Observable{T}) where T = BinningAnalysis.jackknife(g, timeseries(obs))
BinningAnalysis.jackknife(g::Function, obss::Observable{T}...) where T = BinningAnalysis.jackknife(g, hcat(timeseries.(obss)...))




"""
    iswithinerrorbars(a, b, δ[, print=false])

Checks whether numbers `a` and `b` are equal up to given error `δ`.
Will print `x ≈ y + k·δ` for `print=true`.

Is equivalent to `isapprox(a,b,atol=δ,rtol=zero(b))`.
"""
function iswithinerrorbars(a::T, b::S, δ::Real, print::Bool=false) where T<:Number where S<:Number
  equal = isapprox(a,b,atol=δ,rtol=zero(δ))
  if print && !equal
    out = a>b ? abs(a-(b+δ))/δ : -abs(a-(b-δ))/δ
    println("x ≈ y + ",round(out, digits=4),"·δ")
  end
  return equal
end
"""
    iswithinerrorbars(A::AbstractArray{T<:Number}, B::AbstractArray{T<:Number}, Δ::AbstractArray{<:Real}[, print=false])

Elementwise check whether `A` and `B` are equal up to given real error matrix `Δ`.
Will print `A ≈ B + K.*Δ` for `print=true`.
"""
function iswithinerrorbars(A::AbstractArray{T}, B::AbstractArray{S},
                           Δ::AbstractArray{<:Real}, print::Bool=false) where T<:Number where S<:Number
  size(A) == size(B) == size(Δ) || error("A, B and Δ must have same size.")

  R = iswithinerrorbars.(A,B,Δ,false)
  allequal = all(R)

  if print && !all(R)
    if T<:Real && S<:Real
      O = similar(A, promote_type(T,S))
      for i in eachindex(O)
        a = A[i]; b = B[i]; δ = Δ[i]
        O[i] = R[i] ? 0.0 : round(a>b ? abs(a-(b+δ))/δ : -abs(a-(b-δ))/δ, digits=4)
      end
      println("A ≈ B + K.*Δ, where K is:")
      display(O)
    else
      @warn "Unfortunately print=true is only supported for real input."
    end
  end

  return allequal
end
iswithinerrorbars(A::Observable, B::Observable, Δ, print=false) = iswithinerrorbars(timeseries(A), timeseries(B), Δ, print)