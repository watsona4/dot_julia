## Types

## A container for our counters
mutable struct AMVW_Counter
    zero_index::Int
    start_index::Int
    stop_index::Int
    it_count::Int
    tr::Int
end


## Rotators Our rotators have field names c, s where c nad s are
## either T or Complex{T} It proved to be faster to have immutable
## rotators, rather than mutable ones so there are no "setter" methods
## anymore, a new instance (via `Rotator(c,s,i)`) should be used

abstract type CoreTransform{T} end
abstract type AbstractRotator{T} <: CoreTransform{T} end

is_diagonal(r::AbstractRotator{T}) where {T} = norm(r.s) <= eps(T)


Base.copy(a::AbstractRotator) = AbstractRotator(a.c, a.s, a.i)
## get values
vals(r::AbstractRotator{T}) where {T} = (r.c, r.s)
idx(r::AbstractRotator) = r.i


#the index is superflous for now, and a bit of a hassle to keep immutable
#but might be of help later if twisting is approached. Shouldn't effect speed, but does mean 3N storage (Q, Ct, B)
#so may be
#
struct RealRotator{T} <: AbstractRotator{T}
c::T
s::T
i::Int
RealRotator(c::T, s::T, i::Int) where {T} = new{T}(c,s,i)
RealRotator{T}() where {T} = new()
end

function adjoint(r::RealRotator)
    RealRotator(r.c, -r.s, r.i)
end


Base.one(::Type{RealRotator{T}}) where {T} = RealRotator(one(T), zero(T), 0)# end

##################################################
### Okay, now try with complex C, real s

struct ComplexRealRotator{T} <: AbstractRotator{T}
c::Complex{T}
s::T
i::Int
end

function adjoint(r::ComplexRealRotator)
    ComplexRealRotator(conj(r.c), -r.s, r.i)
end

Base.one(::Type{ComplexRealRotator{T}}) where {T} = ComplexRealRotator(complex(one(T), zero(T)), zero(T), 0)



Base.copy(a::ComplexRealRotator) = ComplexRealRotator(a.c, a.s, a.i)


##
Rotator(c::Complex{T}, s::Complex{T}, i::Int) where {T <: Real} =
    Rotator(c, real(s), i)
Rotator(c::Complex{T}, s::T, i::Int) where {T <: Real} = ComplexRealRotator(c,s,i)
Rotator(c::T, s::T, i::Int) where {T <: Real} = RealRotator(c,s,i)


# ##################################################
# ## We use two complex, rather than 3 reals here.
# ## Will be basically the ame storage, as we don't need to include a D, but not quite (12N, not 11N)

struct ComplexComplexRotator{T} <: AbstractRotator{T}
c::Complex{T}
s::Complex{T}
i::Int
end

function adjoint(r::ComplexComplexRotator)
    ComplexComplexRotator(conj(r.c), -r.s, r.i)
end


Base.one(::Type{ComplexComplexRotator{T}}) where {T} = ComplexComplexRotator(complex(one(T), zero(T)), complex(zero(T), zero(T)), 0)



##################################################
## Factorization Types ##
##################################################


# N -- degree of poly
# POLY -- [p0, p1, p2, ..., pn] (not reversed, same as p.a for Poly type
# reverse in the init_state

abstract type FactorizationType{T, ShiftType, Pencil, Twisted} end

## SingleShift(:SingleShift) -- Q, D, U, Ut
## DoubleShift(:DoubleShift) -- Q, U, V, Ut, Vt, W

## :NoPencil -- Ct, B
## :HasPencil -- [D], Ct, B, Ct1, B1, [D1]

## :NotTwisted --
## :IsTwisted -- sigma

## All have: N, POLY, REIGS, IEIGS,
## A, Bk, R, e1, e2, ctr

############### No Pencil, Not Twisted ###################################

## RDS, no pencil, not twisted
#struct Real_DoubleShift_NoPencil_NotTwisted{T} <: FactorizationType{T, Val{:DoubleShift}, Val{:NoPencil}, Val{:NotTwisted}
mutable struct Real_DoubleShift_NoPencil_NotTwisted{T} <: FactorizationType{T, Val{:DoubleShift}, Val{:NoPencil}, Val{:NotTwisted}}

N::Int
POLY::Vector{T}
##
Q::Vector{RealRotator{T}}
Ct::Vector{RealRotator{T}}  # We use C', not C here
B::Vector{RealRotator{T}}
##
REIGS::Vector{T}
IEIGS::Vector{T}
## reusable storage
U::RealRotator{T}
Ut::RealRotator{T}
V::RealRotator{T}
Vt::RealRotator{T}
W::RealRotator{T}
A::Matrix{T}    # for parts of A = QR
R::Matrix{T}    # temp storage, sometimes R part of QR
e1::Vector{T}   # eigen values e1, e2
e2::Vector{T}
ctrs::AMVW_Counter
end

function Base.convert(::Type{FactorizationType{T, Val{:DoubleShift}, Val{:NoPencil}, Val{:NotTwisted}}}, ps::Vector{T}) where {T <: AbstractFloat}

    N = length(ps) - 1

    Real_DoubleShift_NoPencil_NotTwisted(N, ps,
                                         Vector{AMVW.RealRotator{T}}(undef, N), #Q
                                         Vector{AMVW.RealRotator{T}}(undef, N), #Ct '
                                         Vector{AMVW.RealRotator{T}}(undef, N), # B
                                         zeros(T, N),  zeros(T, N), #EIGS
                                         one(RealRotator{T}), one(RealRotator{T}), #U, Ut
                                         one(RealRotator{T}), one(RealRotator{T}), #V, Vt
    one(RealRotator{T}), # W
    zeros(T, 2, 2),zeros(T, 3, 2), # A, R
    zeros(T,2), zeros(T,2),
    AMVW_Counter(0,1,N-1, 0, N-2)
    )
end


# ComplexReal Double Shift, no pencil, not twisted
mutable struct ComplexReal_SingleShift_NoPencil_NotTwisted{T} <: FactorizationType{T, Val{:SingleShift}, Val{:NoPencil}, Val{:NotTwisted}}

N::Int
POLY::Vector{Complex{T}}
Q::Vector{ComplexRealRotator{T}}
D::Vector{Complex{T}}
Ct::Vector{ComplexRealRotator{T}}  # We use C', not C here
B::Vector{ComplexRealRotator{T}}
#
REIGS::Vector{T}
IEIGS::Vector{T}
# reusable storage
U::ComplexRealRotator{T}
Ut::ComplexRealRotator{T}
A::Matrix{Complex{T}}    # for parts of A = QR
R::Matrix{Complex{T}}    # temp storage, sometimes R part of QR
e1::Vector{T}   # eigen values e1, e2, store as (re,imag)
e2::Vector{T}
ray::Bool
ctrs::AMVW_Counter
end

function Base.convert(::Type{FactorizationType{T, Val{:SingleShift}, Val{:NoPencil}, Val{:NotTwisted}}}, ps::Vector{Complex{T}}; ray=true) where {T}

    N = length(ps) - 1

    ComplexReal_SingleShift_NoPencil_NotTwisted(N, ps,
                                                Vector{ComplexRealRotator{T}}(undef,N), #Q
                                                ones(Complex{T}, N+1), # D
                                                Vector{ComplexRealRotator{T}}(undef,N), #Ct
                                                Vector{ComplexRealRotator{T}}(undef,N), #B
                                                zeros(T, N),  zeros(T, N), #EIGS
    one(ComplexRealRotator{T}), one(ComplexRealRotator{T}), #U, Ut
    zeros(Complex{T}, 2, 2),zeros(Complex{T}, 3, 2), # A R
    zeros(T,2), zeros(T,2),
    #    true,  # true for Wilkinson, false for Rayleigh.Make adjustable!
    ray,
    AMVW_Counter(0,1,N-1, 0, N-2)
    )
end



############## Has Pencil, Not twisted ####################################

## RDS, no pencil, not twisted
mutable struct Real_DoubleShift_HasPencil_NotTwisted{T} <: FactorizationType{T, Val{:DoubleShift}, Val{:HasPencil}, Val{:NotTwisted}}

N::Int
POLY::Vector{T}
##
Q::Vector{RealRotator{T}}
Ct::Vector{RealRotator{T}}  # We use C', not C here
B::Vector{RealRotator{T}}
#
Ct1::Vector{RealRotator{T}}  # W = Ct * B
B1::Vector{RealRotator{T}}   #
##
REIGS::Vector{T}
IEIGS::Vector{T}
## reusable storage
U::RealRotator{T}
Ut::RealRotator{T}
V::RealRotator{T}
Vt::RealRotator{T}
W::RealRotator{T}
#
A::Matrix{T}    # for parts of A = QR
R::Matrix{T}    # temp storage, sometimes R part of QR
e1::Vector{T}   # eigen values e1, e2
e2::Vector{T}
ctrs::AMVW_Counter
end

function Base.convert(::Type{FactorizationType{T, Val{:DoubleShift}, Val{:HasPencil}, Val{:NotTwisted}}}, ps::Vector{T}) where {T}

    N = length(ps) - 1

    Real_DoubleShift_HasPencil_NotTwisted(N, ps,
                                          Vector{RealRotator{T}}(undef, N), #Q
                                          Vector{RealRotator{T}}(undef, N), #Ct
                                          Vector{RealRotator{T}}(undef, N), #B
                                          Vector{RealRotator{T}}(undef, N), #Ct1
                                          Vector{RealRotator{T}}(undef, N), #B1
    zeros(T, N),  zeros(T, N), #EIGS
    one(RealRotator{T}), one(RealRotator{T}),
    one(RealRotator{T}), one(RealRotator{T}),
    one(RealRotator{T}), #U,U',V,V',W
    zeros(T, 2, 2), zeros(T, 3, 2), # A R
    zeros(T,2), zeros(T,2),
    AMVW_Counter(0,1,N-1, 0, N-2)
    )
end


# ComplexReal Double Shift, has pencil, not twisted

mutable struct ComplexReal_SingleShift_HasPencil_NotTwisted{T} <: FactorizationType{T, Val{:SingleShift}, Val{:HasPencil}, Val{:NotTwisted}}

N::Int
POLY::Vector{Complex{T}}
Q::Vector{ComplexRealRotator{T}}
D::Vector{Complex{T}}
Ct::Vector{ComplexRealRotator{T}}  # We use C', not C here
B::Vector{ComplexRealRotator{T}}
# pencil part
D1::Vector{Complex{T}}
Ct1::Vector{ComplexRealRotator{T}}  # not inverses
B1::Vector{ComplexRealRotator{T}}
#
REIGS::Vector{T}
IEIGS::Vector{T}
## reusable storage
U::ComplexRealRotator{T}
Ut::ComplexRealRotator{T}
#
A::Matrix{Complex{T}}    # for parts of A = QR
R::Matrix{Complex{T}}    # temp storage, sometimes R part of QR
e1::Vector{T}   # eigen values e1, e2, store as (re,imag)
e2::Vector{T}
#
ray::Bool
ctrs::AMVW_Counter
end

function Base.convert(::Type{FactorizationType{T, Val{:SingleShift}, Val{:HasPencil}, Val{:NotTwisted}}}, ps::Vector{Complex{T}}; ray=true) where {T}

    N = length(ps) - 1

    ComplexReal_SingleShift_HasPencil_NotTwisted(N, ps,
                                                 Vector{ComplexRealRotator{T}}(undef, N), #Q
                                                 ones(Complex{T}, N+1), # D
                                                 Vector{ComplexRealRotator{T}}(undef, N), #Ct
    Vector{ComplexRealRotator{T}}(undef, N), #B
    ones(Complex{T}, N+1), # D1
    Vector{ComplexRealRotator{T}}(undef, N), #Ct1
    Vector{ComplexRealRotator{T}}(undef, N), #B1
    zeros(T, N),  zeros(T, N), #EIGS
    one(ComplexRealRotator{T}), one(ComplexRealRotator{T}), #U, Ut
    zeros(Complex{T}, 2, 2),zeros(Complex{T}, 3, 2), # A , R
    zeros(T,2), zeros(T,2),
    #    true,  # true for Wilkinson, false for Rayleigh.Make adjustable!
    ray,
    AMVW_Counter(0,1,N-1, 0, N-2)
    )
end
