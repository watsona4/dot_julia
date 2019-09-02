# -------------------------------------------------------------------------
#   Saving and loading of (complete) observable
# -------------------------------------------------------------------------
"""
    saveobs(obs::Observable{T}[, filename::AbstractString, entryname::AbstractString])

Saves complete representation of the observable to JLD file.

Default filename is "Observables.jld" and default entryname is `name(obs)`.

See also [`loadobs`](@ref).
"""
function saveobs(obs::AbstractObservable, filename::AbstractString=obs.outfile, 
                    entryname::AbstractString=(inmemory(obs) ? obs.group : obs.group*"/observable"))
    fileext(filename) == "jld" || error("\"$(filename)\" is not a valid JLD filename.")
    if !isfile(filename)
        save(filename, entryname, obs)
    else
        jldopen(filename, "r+") do f
            !HDF5.has(f.plain, entryname) || delete!(f, entryname)
            write(f, entryname, obs)
        end
    end
    nothing
end



"""
    loadobs(filename::AbstractString, entryname::AbstractString)

Load complete representation of an observable from JLD file.

See also [`saveobs`](@ref).
"""
function loadobs(filename::AbstractString, entryname::AbstractString)
    fileext(filename) == "jld" || error("\"$(filename)\" is not a valid JLD filename.")
    return load(filename, entryname)
end





struct ObservableResult{T,S}
    name::String
    count::Int64
    mean::T
    error::S
end


function _print_header(io::IO, r::ObservableResult{T, S}) where {T, S}
    print(io, "ObservableResult{$(T), $(S)}")
    nothing
end

function _println_body(io::IO, r::ObservableResult{T, S}) where {T, S}
    println(io)
    println(io, "| Name: ", r.name)
    print(io, "| Count: ", r.count)
    if r.count > 0 && ndims(r.error) == 0
        print(io, "\n| Mean: ", round.(r.mean, digits=5))
        print(io, "\n| StdError: ", round.(r.error, digits=5))
    end
    nothing
end

# short version (shows up in arrays etc.)
Base.show(io::IO, r::ObservableResult{T, S}) where {T, S} = print(io, "ObservableResult{$(T), $(S)}()")
# verbose version (shows up in the REPL)
Base.show(io::IO, m::MIME"text/plain", r::ObservableResult) = (_print_header(io, r); _println_body(io, r))



function load_result(filename::AbstractString, obs::AbstractString)
    @assert isfile(filename) "File not found."

    p = joinpath("/", obs)

    local name, n, m, err
    jldopen(filename) do f
        name = read(f[joinpath(p, "name")])
        n = read(f[joinpath(p, "count")])
        m = read(f[joinpath(p, "mean")])
        err = read(f[joinpath(p, "error")])
    end

    return ObservableResult(name, n, m, err)
end



# function combined_mean_and_var(ors::ObservableResult{<:Number, <:Number}...)
#     ns = [r.count for r in ors]
#     μs = [r.mean for r in ors]
#     vs = [r.error^2 for r in ors]

#     return Helpers.combined_mean_and_var(ns, μs, vs)
# end


# function combined_mean_and_var(ors::ObservableResult{<:Number, <:AbstractArray}...)
#     ns = [r.count for r in ors]
#     μs = [r.mean for r in ors]
#     vs = [r.error^2 for r in ors]

#     return Helpers.combined_mean_and_var(ns, μs, vs)
# end




# personal wrapper
function getfrom(filename::AbstractString, obs::AbstractString, what::AbstractString)
    if !(what in ["ts", "ts_flat", "timeseries", "timeseries_flat"])
        d = joinpath("obs/", obs, what)
        return jldopen(filename) do f
            return read(f[d])
        end
    else
        grp = joinpath("obs/", obs)
        return occursin("flat", what) ? ts_flat(filename, grp) : ts(filename, grp)
    end
end





"""
List all observables in a given file and HDF5 group.
"""
function listobs(filename::AbstractString, group::AbstractString="obs/")
    s = Vector{String}()
    HDF5.h5open(filename, "r") do f
        if HDF5.has(f, group)
            for el in HDF5.names(f[group])
                # println(el)
                push!(s, el)
            end
        end
    end
    return s
end




"""
Remove an observable.
"""
function rmobs(filename::AbstractString, dset::AbstractString, group::AbstractString="obs/")
    HDF5.h5open(filename, "r+") do f
        HDF5.o_delete(f, joinpath(group,dset))
    end
end