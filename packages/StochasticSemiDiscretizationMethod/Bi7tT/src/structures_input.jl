struct stCoeffMX{d,mt<:CoefficientMatrix{d}} <: CoefficientMatrix{d}
    nID::Int64
    cMX::mt
end
(stcm::stCoeffMX)(t) = stcm.cMX(t)

struct stAdditive{d,T<:AdditiveVector{d}} <: AdditiveVector{d}
    nID::Int64
    V::T
end
(stV::stAdditive)(t) = stV.V(t)

# Linear Delay Differential Equation Problem
struct LDDEProblem{d,AT <: ProportionalMX{d,<:MatrixOrFunction},BT <: DelayMX{d,<:Any,<:Any}, cT <: Additive{d,<:VectorOrFunction}, αT<:stCoeffMX{d,<:ProportionalMX{d,<:Any}}, βT<:stCoeffMX{d,<:DelayMX{d,<:Any,<:Any}}, σT<:AdditiveVector{d}} <: AbstractLDDEProblem{d}
    A::AT # Coefficient of the proportional term (present /non-discretised term)
    Bs::Vector{BT} # Coefficient of the delayed terms
    αs::Vector{αT} # Noise from the delay matrix (only single delay!!!)
    βs::Vector{βT} # Noise from the delay matrix (only single delay!!!)
    c::cT # Additive vector
    σs::Vector{σT} # Additive vectors for the noises
    w::Int64 # Number of noise sources
end

function LDDEProblem(A::ProportionalMX, Bs::Vector{<:DelayMX}, αs::Vector{<:stCoeffMX}, βs::Vector{<:stCoeffMX}, c::Additive=Additive(size(A, 2)), σs::Vector{<:stAdditive}=Vector{AdditiveVector}(undef,0))
    w::Int64 = all(isempty.((αs,βs,σs))) ? 0 : maximum(αβ.nID for αβ in (αs...,βs...,σs...))
    LDDEProblem(A, Bs, αs, βs, c, σs, w)
end