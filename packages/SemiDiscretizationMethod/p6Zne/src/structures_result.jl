struct CyclicVector{T} <: AbstractVector{T}
    s::Int64
    V::Vector{T}
end
CyclicVector(V::Vector{T}) where T = CyclicVector{T}(length(V),V)
Base.getindex(cV::CyclicVector, idx) = cV.V[((idx .- 1) .% cV.s .+ 1)]
Base.size(LV::CyclicVector) = (LV.s,)
Base.size(LV::CyclicVector, ::Integer) = LV.s

abstract type subArray{mT} end
struct SubMX{mT} <: subArray{mT}
    ranges::Vector{Tuple{UnitRange{Int64},UnitRange{Int64}}}
    MXs::Vector{mT}
end
SubMX(range::Tuple{<:AbstractVector,<:AbstractVector}, MX::SMatrix{<:Real}) = SubMX([range], [MX])
SubMX(range::Tuple{<:AbstractVector,<:AbstractVector}, MX::AbstractMatrix{<:Real}) = SubMX([range], [MX])
struct SubV{vT} <: subArray{vT}
    V::vT
end

abstract type AbstractResult{d} end
struct Result{d,lddepT<:AbstractLDDEProblem{d},mT,submxT,subvT,tT,AavgT} <: AbstractResult{d}
    LDDEP::lddepT
    method::mT #::DiscretizationMethod
    subMXs::Vector{Vector{submxT}} # [[A(t1),A(t2),...],[B1(t1),B1(t2),...],[B2(t1),B2(t2),...],...]
    subVs::Vector{subvT} # [c(t1),c(t2),...]
    #
    A_avgs::AavgT
    ts::Vector{tT} # [0,t1,t2,...]
    n_steps::Int64 # number of time steps
    n::Int64 # Large discretisation matrix size
    calculate_additive::Bool
    # d::Integer # state space dimension
end

calculate_Aavgs(A::ProportionalMX{d,<:Function}, ts::AbstractVector{<:Real},Δt::Real) where d = [(quadgk(A, ts[i], ts[i + 1])[1] ./ Δt) for i in 1:length(ts)-1]
calculate_Aavgs(A::ProportionalMX{d,<:mT}, ts::AbstractVector{<:Real},Δt::Real)  where d where mT <: AbstractMatrix{T} where T = CyclicVector([A.MX])

function Result(LDDEP::LDDEProblem{d,AT,BT, cT}, method::DiscretizationMethod{fT}, DiscretizationLength::Real; n_steps::Int64=nStepOfLength(DiscretizationLength, method.Δt), calculate_additive::Bool=false) where {d,AT,BT,cT,N,fT}
    # DiscretizationLength discretisated time interval length
    # n_steps: how many mapping matrix to calculate
    ts =  collect(fT,take(n_steps + 1, iterated(x -> method.Δt + x, zero(method.Δt))))
    n = (rOfDelay(DiscretizationLength, method) + 1) * d
    A_avgs = calculate_Aavgs(LDDEP.A, ts, method.Δt)
    subMXs = [Vector{SubMX{eltype(A_avgs)}}(undef, n_steps) for i in 1:(length(LDDEP.Bs) + 1)] # []
    if calculate_additive
        # subVs = Vector{SubV{eltype(LDDEP.cT.V)}}(undef, n_steps) # []
        subVs = Vector{SubV{SVector{d,eltype(eltype(A_avgs))}}}(undef, n_steps) # []
    else
        # subVs = Vector{SubV{eltype(LDDEP.cT.V)}}(undef, 0)
        subVs = Vector{SubV{SVector{d,eltype(eltype(A_avgs))}}}(undef, 0)
    end
    
    Result(LDDEP, method, subMXs, subVs, A_avgs, ts, n_steps, n, calculate_additive)
end

struct DiscreteMapping{tT,mxT,vT}
    ts::Vector{tT}
    mappingMXs::Vector{mxT}
    mappingVs::Vector{vT}
end

function initializeOneStepMapping(dm::DiscreteMapping{tT,mxT,vT}) where {tT,mxT,vT}
    DiscreteMapping(Vector{tT}(undef,2),Vector{mxT}(undef,1),Vector{vT}(undef,1))
end
