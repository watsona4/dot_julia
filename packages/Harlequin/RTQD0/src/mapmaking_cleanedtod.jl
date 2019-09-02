@doc raw"""
    mutable struct CleanedTOD{T <: Real}

This structure is used to associated a TOD containing some measurement
with the set of baselines estimated by the destriper. It implements
the iterator interface, which means that it can be used like if it
were an array.

"""
mutable struct CleanedTOD{T <: Real}
    tod::AbstractArray{T,1}
    baselines::AbstractArray{T,1}
end

function Base.iterate(iter::CleanedTOD{T}) where {T <: Real}
    isempty(iter.tod) && return nothing

    first_tod, tod_iter = iterate(iter.tod)
    first_baseline, baseline_iter = iterate(iter.baselines)
    (first_tod - first_baseline, (tod_iter, baseline_iter))
end

function Base.iterate(iter::CleanedTOD{T}, state) where {T <: Real}
    next_tod, next_baseline = state
    next_tod = iterate(iter.tod, next_tod)
    next_baseline = iterate(iter.baselines, next_baseline)

    next_tod === nothing && return nothing
    next_baseline == nothing && return nothing

    (next_tod[1] - next_baseline[1], (next_tod[2], next_baseline[2]))
end

Base.getindex(c::CleanedTOD{T}, idx) where {T <: Real} = c.tod[idx] - c.baselines[idx]
Base.length(c::CleanedTOD{T}) where {T <: Real} = length(c.tod)
