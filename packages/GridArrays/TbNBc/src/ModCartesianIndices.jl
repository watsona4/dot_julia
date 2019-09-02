module ModCartesianIndicesBase
export ModCartesianIndices


using Base: tail
import Base: getindex, length, size, IndexStyle, IndexCartesian, in, iterate, mod,
    first, last
@inline mod_tuple(c::NTuple{N,Int}, size::NTuple{N,Int}) where N  =
    ntuple(k->mod(c[k]-1,size[k])+1, Val(N))

@inline mod(c::CartesianIndex{N}, size::NTuple{N,Int}) where N =
    CartesianIndex(mod_tuple(c.I, size))

@inline add_offset_mod(i::NTuple{N,Int}, start::NTuple{N,Int}, size::NTuple{N,Int}, periodic::NTuple{N,Bool}) where N =
    ntuple(k->( periodic[k]  ? add_offset_mod(i[k], start[k], size[k]) : i[k] ), Val(N))

@inline add_offset_mod(i::Int, start::Int, size::Int) =
    start + mod(i-start, size)

struct ModCartesianIndices{N,K} <:AbstractArray{CartesianIndex{N},N}
    size::NTuple{N,Int}
    iter::CartesianIndices{N,K}
    start::CartesianIndex{N}
    stop::CartesianIndex{N}
    periodic::NTuple{N,Bool}
end

getindex(A::ModCartesianIndices, index...) = mod(A.iter[index...],A.size)
IndexStyle(A::ModCartesianIndices) = IndexCartesian()
function ModCartesianIndices(size::NTuple{N,Int}, iranges::UnitRange...) where {N}
    start = CartesianIndex(ntuple(k->first(iranges[k]), Val(N)))
    stop  = CartesianIndex(ntuple(k->last(iranges[k]), Val(N)))
    ModCartesianIndices(size, CartesianIndices(iranges), start, stop, ntuple(k->true,Val(N)))
end

function ModCartesianIndices(size::NTuple{N,Int}, start::CartesianIndex{N}, stop::CartesianIndex,  periodic::NTuple{N,Bool}=ntuple(k->true,Val(N))) where {N}
    iranges = ntuple(k-> ((start[k] <= stop[k]) ? (start[k]:stop[k]) : (start[k]:(stop[k]+size[k]))), Val(N))
    ModCartesianIndices(size, CartesianIndices(iranges), start, stop, periodic)
end

@inline size(m::ModCartesianIndices) = size(m.iter)
@inline length(m::ModCartesianIndices) = length(m.iter)


struct ModUnitRange{I} <:AbstractUnitRange{I}
    size::I
    iter::UnitRange{I}
    periodic::Bool

    function ModUnitRange(size::I, iter::UnitRange{I}, periodic=true) where I<:Integer
        if periodic
            e = last(iter)
            l = length(iter)
            e_aligned = mod(e-1,size)+1
            f_aligned = e_aligned - l + 1
            new{I}(size, f_aligned:e_aligned, periodic)
        else
            new{I}(size, max(1,start(iter)):min(size,last(iter)), periodic)
        end
    end
end

first(r::ModUnitRange) = mod(first(r.iter)-1,r.size)+1
last(r::ModUnitRange) = mod(last(r.iter)-1,r.size)+1

function in(i::Integer, r::ModUnitRange{<:Integer})
    if r.periodic
        i_aligned =  mod(i-1,r.size)+1
        return (i_aligned ∈ r.iter) | (i_aligned ∈ r.iter .+ r.size)
    else
        return in(i, r.iter)
    end
end

function iterate(m::ModUnitRange)
    tuple = iterate(m.iter)
    if tuple != nothing
        index, state = tuple
        mod(index-1, m.size)+1, state
    end
end

function iterate(m::ModUnitRange, state)
    tuple = iterate(m.iter, state)
    if tuple != nothing
        index, state = tuple
        mod(index-1, m.size)+1, state
    end
end

@inline length(m::ModUnitRange) = length(m.iter)

nbindexlist(index::Base.CartesianIndex{N}, size::NTuple{N,Int}, periodic=ntuple(k->false, Val(N))) where {N}  =
    ModCartesianIndices(size, index+CartesianIndex(ntuple(k->-1, Val(N))), index+CartesianIndex(ntuple(k->1, Val(N))), periodic)
nbindexlist(index::Int, size::NTuple{1,Int}, periodic=false)  =
    ModUnitRange(size[1], index-1:index+1, periodic)


end # module
