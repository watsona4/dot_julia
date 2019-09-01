# Iterator State Placeholders
@inline _dummy_iterate_state(itr) = iterate(itr)[2]
@inline _dummy_iterate_state(itr::Array) = 0
@inline _dummy_iterate_state(itr::OrdinalRange{T}) where {T} = zero(T)
@inline _dummy_iterate_state(itr::StaticArray) = (Base.OneTo(1), 0)
@inline _dummy_iterate_state(itr::Base.Generator) = _dummy_iterate_state(itr.iter)
@inline _dummy_iterate_state(itr::Iterators.Filter) = _dummy_iterate_state(itr.itr)

@inline _dummy_iterate_result(itr) = iterate(itr)
@inline _dummy_iterate_result(itr::AbstractArray{T}) where {T} = (zero(T), _dummy_iterate_state(itr))

# ControlInterval Iteration
@inline Base.iterate(c::ControlInterval) = (c, nothing)
@inline Base.iterate(c::ControlInterval, ::Any) = nothing
@inline Base.eltype(::Type{CI}) where {CI<:ControlInterval} = CI
@inline Base.length(::ControlInterval) = 1

# Propagate
struct Propagate{D,S,C,T}
    f::D
    x0::S
    cs::C
    ss::T
end

Base.length(itr::Propagate) = length(itr.ss)
Base.eltype(::Type{Propagate{D,S,C,T}}) where {D,S,C,T} = S

@inline function _start(itr::Propagate)
    cs_iter_result = iterate(itr.cs)
    if (cs_done = cs_iter_result === nothing)
        cs_iter_result = _dummy_iterate_result(itr.cs)
    end
    ((itr.x0, zero(eltype(itr.ss)), cs_done, cs_iter_result),)
end

@inline function Base.iterate(itr::Propagate, state=_start(itr))
    x, t, cs_done, cs_iter_result = state[1][1], state[1][2], state[1][3], state[1][4]
    ss_state = Base.tail(state)

    ss_iter_result = iterate(itr.ss, ss_state...)
    ss_iter_result === nothing && return nothing
    s, ss_state = ss_iter_result

    c, cs_state = cs_iter_result
    if !cs_done
        while s >= t + duration(c)
            x = propagate(itr.f, x, c)
            t += duration(c)
            cs_iter_result = iterate(itr.cs, cs_state)
            cs_iter_result === nothing && return x, ((x, t, true, (c, cs_state)), ss_state)
            c, cs_state = cs_iter_result
        end
        y = propagate(itr.f, x, c, s - t)
    else
        y = x
    end

    y, ((x, t, cs_done, cs_iter_result), ss_state)
end

# InstantaneousControl
struct InstantaneousControl{C,T}
    cs::C
    ss::T
end

Base.length(itr::InstantaneousControl) = length(itr.ss)
function Base.eltype(::Type{InstantaneousControl{C,T}}) where {C,T}
    typeof(instantaneous_control(zero(eltype(C)), zero(eltype(T))))
end

@inline function _start(itr::InstantaneousControl)
    cs_iter_result = iterate(itr.cs)
    if (cs_done = cs_iter_result === nothing)
        cs_iter_result = _dummy_iterate_result(itr.cs)
    end
    ((zero(eltype(itr.ss)), cs_done, cs_iter_result),)
end

@inline function Base.iterate(itr::InstantaneousControl, state=_start(itr))
    t, cs_done, cs_iter_result = state[1][1], state[1][2], state[1][3]
    ss_state = Base.tail(state)

    ss_iter_result = iterate(itr.ss, ss_state...)
    ss_iter_result === nothing && return nothing
    s, ss_state = ss_iter_result

    c, cs_state = cs_iter_result
    if !cs_done
        while s >= t + duration(c)
            t += duration(c)
            cs_iter_result = iterate(itr.cs, cs_state)
            cs_iter_result === nothing && return (instantaneous_control(c, duration(c)), 
                                                  ((t, true, (c, cs_state)), ss_state))
            c, cs_state = cs_iter_result
        end
        ic = instantaneous_control(c, s-t)
    else
        ic = instantaneous_control(c, duration(c))
    end

    ic, ((t, cs_done, cs_iter_result), ss_state)
end
