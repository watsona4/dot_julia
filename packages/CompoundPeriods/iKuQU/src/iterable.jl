# make CompoundPeriod iterable

eltype(x::CompoundPeriod) = Period
length(x::CompoundPeriod) = length(x.periods)

eltype(x::ReverseCompoundPeriod) = Period
length(x::ReverseCompoundPeriod) = length(x.cperiod.periods)

function Base.iterate(x::CompoundPeriod)
    iszero(length(x)) && return nothing
    return (x.periods[1], 1)
end

function Base.iterate(x::CompoundPeriod, state::Int)
    state === length(x) && return nothing
    state += 1
    return (x.periods[state], state)
end

function Base.iterate(x::ReverseCompoundPeriod)
    n = length(x)
    iszero(n) && return nothing
    return (x.cperiod.periods[n], n)
end

function Base.iterate(x::ReverseCompoundPeriod, state::Int)
    state === 1 && return nothing
    state -= 1
    return (x.cperiod.periods[state], state)
end


# make Period iterable for interoperability with CompoundPeriod

eltype(x::Period) = typeof(x)
length(x::Period) = 1

Base.iterate(x::Period) = (x, 1)
Base.iterate(x::Period, state::Int) = nothing
