
module MolecularBoxes

export MolecularBox, Box
export isperiodic, separation, center_of_mass

using StaticArrays

"""
MolecularBox has three type parameters:
    * V: An immutable vector such as those implemented in the StaticArrays
        package
    * N: The number of dimensions
    * P: A tuple of booleans indicating which dimensions are periodic

Concrete types inheriting from MolecularBox
must implement 2 fields: vectors and lengths
 si(::Box)
"""
abstract type MolecularBox{V,N,P} end

include("center_of_mass.jl")

@inline isperiodic(b::MolecularBox{V,N,P}) where {V,N,P} = P
@inline isperiodic(b::MolecularBox{V,N,P}, dim) where {V,N,P} = P[dim]

@inline Base.eltype(::MolecularBox{V}) where V = V

struct Box{V,N,P} <: MolecularBox{V,N,P}
    vectors::NTuple{N,V}
    lengths::V
    function Box{V,N,P}(vectors::NTuple{N,V}) where {N,V,P}
        if !isa(N,Integer)
            error("N parameter of a MolecularBox must be an Integer")
        end
        if !isa(P,NTuple{N,Bool})
            error(string("P=$P parameter of a `MolecularBox` must be a tuple ",
                         "of `Bool`s, with one `Bool` for each dimension"))
        end
        for i in 1:N
            if vectors[i][i] <=0 
                error("Diagonal box matrix elements must be >= 0")
            end
            for j in 1:i-1
                if vectors[j][i] != 0 
                    error("box vector element [$(j)][$(i)] must be zero")
                end
            end
            for j in i+1:N
                if vectors[j][i] != 0 
                    warn("Triclinic box support not fully tested ($j,$i)")
                end
            end
        end
        lengths = convert(V, collect(vectors[i][i] for i in 1:N) )
        new{V,N,P}(vectors, lengths)
    end
end

function Box(
    lengths::V;
    periodic=( (true for x in 1:length(lengths))..., )
) where V
    N = length(lengths)
    vectors = map( (i,L)-> begin 
        v = zeros(eltype(V), N)
        v[i] = L
        convert(V,v)
    end, 1:N, lengths)
    Box{V,N,(periodic...,)}((vectors...,))
end

@inline _separation(
    x1,
    x2,
    length,
    periodic::Bool,
) = _separation(x1, x2, length, Val{periodic})

@inline function _separation(
    x1,
    x2,
    length,
    periodic::Type{Val{P}},
) where {P} 
    r = x1-x2
    if P
        hlen = 0.5length
        while r >= hlen
            r-=length
        end
        while r < -hlen
            r+=length
        end
        # faster but unsafe version:
#       r + ifelse(
#           r >= hlen,
#           -length,
#           ifelse(r < -hlen, length, zero(length)),
#       )
        r
    else
        r
    end
end

@inline function separation(
    x1,
    x2,
    box::MolecularBox{V,N,P},
) where {V,N,P}
    _separation.(x1, x2, box.lengths, SVector(P))
end

separation


end #module
