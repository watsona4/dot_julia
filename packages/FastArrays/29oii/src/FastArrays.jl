module FastArrays

export AbstractFastArray
export AbstractImmutableFastArray, AbstractMutableFastArray
abstract type AbstractFastArray{T, N} <: DenseArray{T, N} end
abstract type AbstractImmutableFastArray{T, N} <: AbstractFastArray{T, N} end
abstract type AbstractMutableFastArray{T, N} <: AbstractFastArray{T, N} end



const BndSpec =
    Union{UnitRange{Int}, Int, Colon, NTuple{2, Union{Int, Nothing}}}

struct MutableFastArrayImpl{
        N, FixedBnds, DynBnds, DynStrs, DynLen, DynOff, T} <:
            AbstractMutableFastArray{T, N}
    dynbnds::DynBnds            # bounds (lower, upper)
    dynstrs::DynStrs            # strides
    dynlen::DynLen              # length
    dynoff::DynOff              # offset
    data::Vector{T}

    function MutableFastArrayImpl{
            N, FixedBnds, DynBnds, DynStrs, DynLen, DynOff, T}(
                ::UndefInitializer, dynbnds::DynBnds) where {
                    N, FixedBnds, DynBnds, DynStrs, DynLen, DynOff, T}
        check_invariant(
            Val{N}, Val{FixedBnds}, DynBnds, DynStrs, DynLen, DynOff)
        dynbnds, dynstrs, dynlen, dynoff, length =
            calc_details(
                Val{FixedBnds}, DynBnds, DynStrs, DynLen, DynOff, dynbnds)
        data = Vector{T}(undef, length)
        new{N, FixedBnds, DynBnds, DynStrs, DynLen, DynOff, T}(
            dynbnds, dynstrs, dynlen, dynoff, data)
    end
end

@generated function MutableFastArrayImpl{
        N, FixedBnds, DynBnds, DynStrs, DynLen, DynOff, T}(
            ::UndefInitializer, bnds::BndSpec...) where {
                N, FixedBnds, DynBnds, DynStrs, DynLen, DynOff, T}
    @assert nfields(bnds) == N
    dynbnds = []
    for i in 1:N
        bnd = getfield(bnds, i)
        if bnd === UnitRange{Int}
            push!(dynbnds, :((bnds[$i].start, bnds[$i].stop)))
        elseif bnd === Int
            push!(dynbnds, :((nothing, bnds[$i])))
        elseif bnd === Colon
            push!(dynbnds, :((nothing, nothing)))
        elseif bnd <: NTuple{2, Union{Int, Nothing}}
            push!(dynbnds, :((bnds[$i][1], bnds[$i][2])))
        else
            @assert false
        end
    end
    dynbnds = :(tuple($(dynbnds...)))
    quote
        MutableFastArrayImpl{
            N, FixedBnds, DynBnds, DynStrs, DynLen, DynOff, T}(undef, $dynbnds)
    end
end

@generated function check_invariant(
        ::Type{Val{N}}, ::Type{Val{FixedBnds}}, ::Type{DynBnds},
        ::Type{DynStrs}, ::Type{DynLen}, ::Type{DynOff}) where {
            N, FixedBnds, DynBnds, DynStrs, DynLen, DynOff}
    inv = invariant(N, FixedBnds, DynBnds, DynStrs, DynLen, DynOff)
    quote
        @assert $inv
    end
end

function invariant(N, FixedBnds, DynBnds, DynStrs, DynLen, DynOff)
    isa(N, Int) || (@error "internal error"; return false)
    N >= 0 || (@error "internal error"; return false)
    isa(FixedBnds, NTuple{N, NTuple{2, Union{Int, Nothing}}}) ||
        (@error "internal error"; return false)
    DynBnds <: Tuple || (@error "internal error"; return false)
    fieldcount(DynBnds) == N || (@error "internal error"; return false)
    for i in 1:N
        DynBnd = fieldtype(DynBnds, i)
        DynBnd <: Tuple || (@error "internal error"; return false)
        fieldcount(DynBnd) == 2 || (@error "internal error"; return false)
        for f in 1:2
            if FixedBnds[i][f] !== nothing
                fieldtype(DynBnd, f) === Nothing ||
                    (@error "internal error"; return false)
            else
                fieldtype(DynBnd, f) === Int ||
                    (@error "internal error"; return false)
            end
        end
    end
    for i in 1:N
        if FixedBnds[i][1] !== nothing && FixedBnds[i][2] !== nothing
            FixedBnds[i][2] >= FixedBnds[i][1] - 1 ||
                (@error "internal error"; return false)
        end
    end
    DynStrs <: Tuple || (@error "internal error"; return false)
    hasfixedoffset = true
    hasfixedlength = true
    for i in 1:N
        hasfixedoffset = hasfixedlength && FixedBnds[i][1] !== nothing
        if hasfixedlength
            fieldtype(DynStrs, i) === Nothing ||
                (@error "internal error"; return false)
        else
            fieldtype(DynStrs, i) === Int ||
                (@error "internal error"; return false)
        end
        hasfixedlength &=
            FixedBnds[i][1] !== nothing && FixedBnds[i][2] !== nothing
    end
    if hasfixedlength
        DynLen === Nothing || (@error "internal error"; return false)
    else
        DynLen === Int || (@error "internal error"; return false)
    end
    if hasfixedoffset
        DynOff === Nothing || (@error "internal error"; return false)
    else
        DynOff === Int || (@error "internal error"; return false)
    end
    return true
end

@generated function calc_details(
        ::Type{Val{FixedBnds}}, ::Type{DynBnds}, ::Type{DynStrs},
        ::Type{DynLen}, ::Type{DynOff}, dynbnds) where {
            FixedBnds, DynBnds, DynStrs, DynLen, DynOff}
    N = length(FixedBnds)
    lbndexprs = []
    for i in 1:N
        if FixedBnds[i][1] !== nothing
            push!(lbndexprs, FixedBnds[i][1])
        else
            push!(lbndexprs, :(dynbnds[$i][1]))
        end
    end
    ubndexprs = []
    for i in 1:N
        if FixedBnds[i][2] !== nothing
            push!(ubndexprs, FixedBnds[i][2])
        else
            push!(ubndexprs, :(dynbnds[$i][2]))
        end
    end
    quote
        lbnds = tuple($(lbndexprs...))
        ubnds1 = tuple($(ubndexprs...))
        ubnds = tuple($((:(max(lbnds[$i] - 1, ubnds1[$i])) for i in 1:N)...))
        length = 1
        $((quote
               $(Symbol("strs", i)) = length
               length *= ubnds[$i] - lbnds[$i] + 1
           end for i in 1:N)...)
        strs = tuple($((Symbol("strs", i) for i in 1:N)...))
        offset = +(1, $((:(- lbnds[$i] * strs[$i]) for i in 1:N)...))
        dynlbnds = tuple($((fieldtype(fieldtype(DynBnds, i), 1) === Int ?
                            :(lbnds[$i]) : :nothing
                            for i in 1:N)...))
        dynubnds = tuple($((fieldtype(fieldtype(DynBnds, i), 2) === Int ?
                            :(ubnds[$i]) : :nothing
                            for i in 1:N)...))
        dynbnds = tuple($((:(dynlbnds[$i], dynubnds[$i]) for i in 1:N)...))
        dynstrs = tuple($((fieldtype(DynStrs, i) === Int ?
                           :(strs[$i]) : :nothing
                           for i in 1:N)...))
        dynlen = $(DynLen === Int ? :length : :nothing)
        dynoff = $(DynOff === Int ? :offset : :nothing)
        dynbnds, dynstrs, dynlen, dynoff, length
    end
end

@generated function lbnd(
        a::MutableFastArrayImpl{N, FixedBnds, DynBnds, DynStrs, DynLen, DynOff},
        ::Type{Val{D}}) where {
            N, FixedBnds, DynBnds, DynStrs, DynLen, DynOff, D}
    if fieldtype(fieldtype(DynBnds, D), 1) === Nothing
        FixedBnds[D][1]
    else
        :(a.dynbnds[D][1])
    end
end

@generated function ubnd(
        a::MutableFastArrayImpl{N, FixedBnds, DynBnds, DynStrs, DynLen, DynOff},
        ::Type{Val{D}}) where {
            N, FixedBnds, DynBnds, DynStrs, DynLen, DynOff, D}
    if fieldtype(fieldtype(DynBnds, D), 2) === Nothing
        FixedBnds[D][2]
    else
        :(a.dynbnds[D][2])
    end
end

@generated function str(
        a::MutableFastArrayImpl{N, FixedBnds, DynBnds, DynStrs, DynLen, DynOff},
        ::Type{Val{D}}) where {
            N, FixedBnds, DynBnds, DynStrs, DynLen, DynOff, D}
    if fieldtype(DynStrs, D) === Nothing
        *(1, (FixedBnds[i][2] - FixedBnds[i][1] + 1 for i in 1:D-1)...)
    else
        :(a.dynstrs[D])
    end
end

@generated function len(
        a::MutableFastArrayImpl{N, FixedBnds, DynBnds, DynStrs, DynLen, DynOff}
        ) where {N, FixedBnds, DynBnds, DynStrs, DynLen, DynOff}
    if DynLen === Nothing
        *(1, (FixedBnds[i][2] - FixedBnds[i][1] + 1 for i in 1:N)...)
    else
        :(a.dynlen)
    end
end

@generated function off(
        a::MutableFastArrayImpl{N, FixedBnds, DynBnds, DynStrs, DynLen, DynOff}
        ) where {N, FixedBnds, DynBnds, DynStrs, DynLen, DynOff}
    if DynOff === Nothing
        strs = Int[1]
        for i in 2:N
            push!(strs, strs[i-1] * (FixedBnds[i-1][2] - FixedBnds[i-1][1] + 1))
        end
        +(1, (- strs[i] * FixedBnds[i][1] for i in 1:N)...)
    else
        :(a.dynoff)
    end
end



export FastArray
@generated function FastArray(bnds::NTuple{N, BndSpec}) where {N}
    isfixed = NTuple{2, Bool}[]
    fixedbnds = []
    for i in 1:N
        bnd = fieldtype(bnds, i)
        if bnd === UnitRange{Int}
            push!(isfixed, (true, true))
            push!(fixedbnds,
                  :((bnds[$i].start, max(bnds[$i].start - 1, bnds[$i].stop))))
        elseif bnd === Int
            push!(isfixed, (true, false))
            push!(fixedbnds, :((bnds[$i], nothing)))
        elseif bnd === Colon
            push!(isfixed, (false, false))
            push!(fixedbnds, :((nothing, nothing)))
        elseif bnd === Tuple{Int, Int}
            push!(isfixed, (true, true))
            push!(fixedbnds,
                  :((bnds[$i][1], max(bnds[$i][1] - 1, bnds[$i][2]))))
        elseif bnd === Tuple{Int, Nothing}
            push!(isfixed, (true, false))
            push!(fixedbnds, :((bnds[$i][1], nothing)))
        elseif bnd === Tuple{Nothing, Int}
            push!(isfixed, (false, true))
            push!(fixedbnds, :((nothing, bnds[$i][2])))
        elseif bnd === Tuple{Nothing, Nothing}
            push!(isfixed, (false, false))
            push!(fixedbnds, :((nothing, nothing)))
        else
            @assert false
        end
    end
    dynbnds = []
    for i in 1:N
        lbnd = isfixed[i][1] ? :Nothing : :Int
        ubnd = isfixed[i][2] ? :Nothing : :Int
        push!(dynbnds, :(Tuple{$lbnd, $ubnd}))
    end
    dynstrs = []
    hasfixedoffset = true
    hasfixedlength = true
    for i in 1:N
        hasfixedoffset = hasfixedlength && isfixed[i][1]
        push!(dynstrs, hasfixedlength ? :Nothing : :Int)
        hasfixedlength &= isfixed[i][1] && isfixed[i][2]
    end
    dynlen = hasfixedlength ? :Nothing : :Int
    dynoff = hasfixedoffset ? :Nothing : :Int
    fixedbnds = :(tuple($(fixedbnds...)))
    dynbnds = :(Tuple{$(dynbnds...)})
    dynstrs = :(Tuple{$(dynstrs...)})
    quote
        MutableFastArrayImpl{
            $N, $fixedbnds, $dynbnds, $dynstrs, $dynlen, $dynoff}
    end
end

@generated function FastArray(bnds::BndSpec...)
    quote
        FastArray(bnds)
    end
end



import Base: axes
@generated function axes(a::MutableFastArrayImpl{N}) where {N}
    quote
        $(Expr(:meta, :inline))
        # TODO: Return Base.OneTo for respective fixed lower bounds
        tuple($((:(lbnd(a, Val{$i}) : ubnd(a, Val{$i})) for i in 1:N)...))
    end
end

import Base: size
@generated function size(a::MutableFastArrayImpl{N}) where {N}
    quote
        inds = axes(a)
        tuple($((:(inds[$i].stop - inds[$i].start + 1) for i in 1:N)...))
    end
end
# size(a, d...) is provided by Base

import Base: strides
@generated function strides(a::MutableFastArrayImpl{N}) where {N}
    quote
        tuple($((:(str(a, Val{$i})) for i in 1:N)...))
    end
end
import Base: stride
function stride(a::MutableFastArrayImpl{N}, d::Int) where {N}
    strides(a)[d]
end

import Base: length
function length(a::MutableFastArrayImpl)
    len(a)
end



import Base: IndexStyle
IndexStyle(::Type{<:AbstractFastArray}) = IndexLinear()

export LinearIndex
struct LinearIndex
    ind::Int
end

export linearindex
function linearindex(
        a::MutableFastArrayImpl{N}, idx::CartesianIndex{N}) where {N}
    Base.@_propagate_inbounds_meta()
    @boundscheck checkbounds(a, idx)
    str = strides(a)
    lind = off(a)
    for i in 1:N
        lind += str[i] * idx[i]
    end
    LinearIndex(lind)
end
function linearindex(a::MutableFastArrayImpl{N}, idx::NTuple{N, Int}) where {N}
    Base.@_propagate_inbounds_meta()
    linearindex(a, CartesianIndex(idx))
end

import Base: getindex
function getindex(a::MutableFastArrayImpl, idx::LinearIndex)
    Base.@_propagate_inbounds_meta()
    getindex(a.data, idx.ind)
end
function getindex(a::MutableFastArrayImpl, idx::Union{Tuple, CartesianIndex})
    throw(BoundsError(a, idx))
end
function getindex(
        a::MutableFastArrayImpl{N},
        idx::Union{NTuple{N, Int}, CartesianIndex{N}}) where {N}
    Base.@_propagate_inbounds_meta()
    lidx = linearindex(a, idx)
    @inbounds val = getindex(a, lidx)
    val
end
function getindex(a::MutableFastArrayImpl{N}, ids::Int...) where {N}
    Base.@_propagate_inbounds_meta()
    getindex(a, ids)
end

import Base: setindex!
function setindex!(a::MutableFastArrayImpl, val, idx::LinearIndex)
    Base.@_propagate_inbounds_meta()
    setindex!(a.data, val, idx.ind)
end
function setindex!(a::MutableFastArrayImpl, val,
                   idx::Union{Tuple, CartesianIndex})
    throw(BoundsError(a, idx))
end
function setindex!(
        a::MutableFastArrayImpl{N}, val,
        idx::Union{NTuple{N, Int}, CartesianIndex{N}}) where {N}
    Base.@_propagate_inbounds_meta()
    lidx = linearindex(a, idx)
    @inbounds val = setindex!(a, val, lidx)
    val
end
function setindex!(a::MutableFastArrayImpl{N}, val, ids::Int...) where {N}
    Base.@_propagate_inbounds_meta()
    setindex!(a, val, ids)
end



function start(a::MutableFastArrayImpl)
    inds = axes(a)
    linearindex(a, ntuple(i -> inds[i].start, length(inds)))
end
function done(a::MutableFastArrayImpl, state)
    inds = axes(a)
    state.ind > linearindex(a, ntuple(i -> inds[i].stop, length(inds))).ind
end
function next(a::MutableFastArrayImpl, state)
    a[state], LinearIndex(state.ind + 1)
end

import Base: iterate
function iterate(a::MutableFastArrayImpl)
    iterate(a, start(a))
end
function iterate(a::MutableFastArrayImpl, state)
    done(a, state) && return nothing
    next(a, state)
end

import Base: vec
function vec(a::MutableFastArrayImpl)
    copy(a.data)
end

import Base: collect
function collect(a::MutableFastArrayImpl)
    reshape(vec(a), size(a))
end

end
