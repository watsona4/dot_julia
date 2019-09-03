MatrixOrFunction = Union{AbstractMatrix,Function}
VectorOrFunction = Union{AbstractVector,Function}
ArrayOrFunction = Union{AbstractArray,Function}
RealOrFunction = Union{Real,Function}

#Delay behavoiur: stochastic or deterministic / Zero order holders or continuous delay

struct Delay{T}
    τ::T
end
(τ::Delay{<:Real})(t) = τ.τ
(τ::Delay{<:Function})(t) = τ.τ(t)
Delay(τ::T1, holdT::T1) where {T1 <: Real} = Delay(t->τ + t % holdT)
Base.convert(::Type{Delay}, τ::RealOrFunction) = Delay(τ)
Base.convert(::Type{Vector{<:Delay}}, τs::Vector{<:RealOrFunction}) = Delay.(τs)

abstract type Coefficients{d} end
abstract type CoefficientMatrix{d} <: Coefficients{d} end
abstract type AdditiveVector{d} <: Coefficients{d} end

Base.size(cs::T) where T<:CoefficientMatrix{d} where d = (d, d)
Base.size(cs::T) where T<:AdditiveVector{d} where d = (d,)
Base.size(cs::T, ::Integer) where T<:Coefficients{d} where d = d
Base.length(cs::T) where T<:AdditiveVector{d} where d = d
Base.length(cs::T) where T<:CoefficientMatrix{d} where d = d^2

struct ProportionalMX{d,T} <: CoefficientMatrix{d}
    MX::T # matrix
end
ProportionalMX(mx::mxT) where mxT <: Function = ProportionalMX{size(mx(0.), 1),mxT}(mx)
ProportionalMX(mx::mxT) where mxT <: SMatrix = ProportionalMX{size(mx, 1),mxT}(mx)
ProportionalMX(mx::mxT) where mxT <: AbstractMatrix{<:Real} = ProportionalMX(SMatrix{size(mx)...}(mx))
(PMX::ProportionalMX{d,<:Function})(t) where d = PMX.MX(t)
(PMX::ProportionalMX{d,<:AbstractMatrix{<:Real}})(t) where d = PMX.MX
Base.convert(::Type{ProportionalMX}, mx::mT) where mT <: AbstractMatrix{<:Real} = ProportionalMX(mx)

struct DelayMX{d,dT,bT} <: CoefficientMatrix{d}
    τ::Delay{dT} # delay
    MX::bT # matrix
end

DelayMX(τ::RealOrFunction, MX::MatrixOrFunction) = DelayMX(Delay(τ), MX)
DelayMX(τ::Delay{dT}, MX::mxT) where {dT,mxT<:Function} = DelayMX{size(MX(0.),1),dT,mxT}(τ, MX)
DelayMX(τ::Delay{dT}, MX::mxT) where {dT,mxT <: SMatrix} = DelayMX{size(MX, 1),dT,mxT}(τ, MX)

DelayMX(τ::Delay{dT}, MX::mxT) where {dT,mxT<:AbstractMatrix{<:Real}} = DelayMX(τ,SMatrix{size(MX)...}(MX))
(DMX::DelayMX{d,<:dT,<:AbstractMatrix{<:Real}})(t) where {d,dT} = DMX.MX
(DMX::DelayMX{d,<:dT,<:Function})(t) where {d,dT} = DMX.MX(t)

struct Additive{d,T} <: AdditiveVector{d}
    V::T
end
Additive(v::vT) where vT <: Function = Additive{length(v(0.)),vT}(v)
Additive(v::vT) where vT <: SVector{d} where d = Additive{d,vT}(v)
Additive(v::vT) where vT <: AbstractVector{<:Real} = Additive(SVector(v...))
Additive(d::Integer) = Additive{d,Vector{Nothing}}(Vector{Nothing}(undef, d))
(AV::Additive{d,<:AbstractVector{<:Real}})(t) where d = AV.V
(AV::Additive{d,<:Function})(t) where d = AV.V(t)
(AV::Additive{d,<:Array{<:Nothing}})(t) where d = zeros(d) # TODO check the effect on performance
Base.convert(::Type{Additive}, v::vT) where vT <: AbstractVector{<:Real} = Additive(v)


# Linear Delay Differential Equation Problem
abstract type AbstractLDDEProblem{d} end
struct LDDEProblem{d,AT <: ProportionalMX{d,<:MatrixOrFunction},BT <: DelayMX{d,<:Any,<:Any}, cT <: Additive{d,<:VectorOrFunction}} <: AbstractLDDEProblem{d} 
    A::AT # Coefficient of the proportional term (present /non-discretised term)
    Bs::Vector{BT} # Coefficient of the delayed terms
    c::cT # Additive vector
    # d::Int64 # dimension of the state space
end
_problemsize(::LDDEProblem{d,AT,BT,cT}) where {d,AT,BT,cT} = d # size of the state space

LDDEProblem(A::AT, Bs::Vector{<:BT}, c::cT = Additive(size(A, 2))) where {AT <: ProportionalMX,BT <: DelayMX,cT <: Additive} = LDDEProblem{size(A, 2),AT,BT,cT}(A, Bs, c)
LDDEProblem(A::AT, B::BT, c::cT = Additive(size(A, 2))) where {AT <: ProportionalMX,BT <: DelayMX,cT <: Additive} = LDDEProblem{size(A, 2),AT,BT,cT}(A, [B], c)

