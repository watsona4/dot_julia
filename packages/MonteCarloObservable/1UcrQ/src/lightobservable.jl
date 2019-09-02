# Basically an augmented LogBinner
struct LightObservable{T, N} <: AbstractObservable
    B::LogBinner{T,N}

    # parameters (external)
    name::String
    outfile::String
    group::String # where to put data in JLD file
end



LightObservable(::Type{T}; kwargs...) where T = LightObservable(zero(T); kwargs...)


function LightObservable(x::T;
                    name::String="unnamed",
                    alloc::Integer=1000,
                    outfile::String="Observables.jld",
                    group::String=name) where T <: Union{Number, AbstractArray}

    B = LogBinner(x, capacity=alloc)
    lo = LightObservable(B,
        name,
        outfile,
        group
    )
    return lo
end



@forward LightObservable.B (Base.length, Base.ndims, Base.push!,Base.append!,
                             Base.empty!, Base.isempty, Base.eltype,
                             Statistics.mean, Statistics.var, BinningAnalysis.std_error)




@inline name(obs::LightObservable) = obs.name
@inline inmemory(obs::LightObservable) = true
@inline Base.size(obs::LightObservable) = @inbounds size(obs.B.x_sum[1])




function _print_header(io::IO, obs::LightObservable{T,N}) where {T,N}
    print(io, "LightObservable{$(T),$(N)}")
    nothing
end

function _println_body(io::IO, obs::LightObservable{T,N}) where {T,N}
    n = length(obs)
    println(io)
    println(io, "| Name: ", name(obs))
    print(io, "| Measurements: ", n)
    if n > 0 && ndims(obs) == 0
        print(io, "\n| Mean: ", round.(mean(obs), digits=5))
        print(io, "\n| StdError: ", round.(std_error(obs), digits=5))
    end
    nothing
end

# short version (shows up in arrays etc.)
Base.show(io::IO, obs::LightObservable{T,N}) where {T,N} = print(io, "LightObservable{$(T),$(N)}()")
# verbose version (shows up in the REPL)
Base.show(io::IO, m::MIME"text/plain", obs::LightObservable) = (_print_header(io, obs); _println_body(io, obs))






import Base: error
@deprecate error(obs::LightObservable) std_error(obs)

BinningAnalysis.tau(obs::LightObservable) = BinningAnalysis.tau(obs.B)

# Assure var(obs) == var(data) and same for std
Statistics.var(obs::LightObservable) = var(obs, 1)
Statistics.std(obs::LightObservable) = map(sqrt, var(obs))





# -------------------------------------------------------------------------
#   Exporting results
# -------------------------------------------------------------------------
"""
    export_results(obs::LightObservable[, filename::AbstractString, group::AbstractString])

Export result for given observable nicely to JLD.

Will export name, number of measurements, estimates for mean and standard error.
"""
function export_result(obs::LightObservable, filename::AbstractString=obs.outfile,
                         group::AbstractString=obs.group*"_export"; error=true)
    grp = endswith(group, "/") ? group : group*"/"

    jldopen(filename, isfile(filename) ? "r+" : "w") do f
        !HDF5.has(f.plain, grp) || delete!(f, grp)
        write(f, joinpath(grp, "name"), name(obs))
        write(f, joinpath(grp, "count"), length(obs))
        m = mean(obs)
        write(f, joinpath(grp, "mean"), m)
        if error
            err = std_error(obs)
            write(f, joinpath(grp, "error"), err)
            write(f, joinpath(grp, "error_rel"), abs.(err ./ m))
        end
    end
    nothing
end



"""
    export_error(obs::LightObservable[, filename::AbstractString, group::AbstractString;])

Export standard error estimate.
"""
function export_error(obs::LightObservable, filename::AbstractString=obs.outfile,
                         group::AbstractString=obs.group)
    grp = endswith(group, "/") ? group : group*"/"

    jldopen(filename, isfile(filename) ? "r+" : "w") do f
        !HDF5.has(f.plain, grp*"error") || delete!(f, grp*"error")
        !HDF5.has(f.plain, grp*"error_rel") || delete!(f, grp*"error_rel")
        err = std_error(obs)
        write(f, joinpath(grp, "error"), err)
        write(f, joinpath(grp, "error_rel"), abs.(err ./ mean(obs)))
    end
    nothing
end