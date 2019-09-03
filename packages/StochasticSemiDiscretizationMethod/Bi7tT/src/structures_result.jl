struct stSubMX{T} <: subArray{T}
    nID::Int64
    ranges::Vector{Tuple{UnitRange{Int64},UnitRange{Int64}}}
    MXfun::Vector{T} # [R^k][i,j] # T<:AbstractMatrix{<:AbstractVector{<:Real}}
end
struct stSubV{T} <: subArray{T}
    nID::Int64
    Vfun::T # T<:AbstractVector{<:Real}
end
stSubV() = stSubV(Vector{Float64}(undef,0),Vector{Vector{SubV}}(undef,0))

struct Result{d,lddepT<:AbstractLDDEProblem{d},mT,submxT,stsubmxT,subvT,stsubvT,tT,AavgT} <: AbstractResult{d}
    LDDEP::lddepT
    method::mT
    itoisometrymethod::ItoIsometryMethod
    subMXs::Vector{Vector{submxT}} # [[A(t1),A(t2),...],[B1(t1),B1(t2),...],[B2(t1),B2(t2),...],...]
    stsubMXs::Vector{Vector{stsubmxT}} # [[A(t1),A(t2),...],[B1(t1),B1(t2),...],[B2(t1),B2(t2),...],...]
    #
    subVs::Vector{subvT} # [c(t1),c(t2),...]
    stsubVs::Vector{Vector{stsubvT}} # [[σ1(t1),σ1(t2),...], [σ2(t1),σ2(t2),...],...]
    #
    A_avgs::AavgT
    ts::Vector{tT} # [0,t1,t2,...]
    n_steps::Int64 # number of time steps
    n::Int64 # Large discretisation matrix size
    calculate_additive::Bool
end

function Result(LDDEP::LDDEProblem{d,AT,BT, cT}, method::DiscretizationMethod{fT}, DiscretizationLength::Real; n_steps::Int64=nStepOfLength(DiscretizationLength, method.Δt), calculate_additive::Bool=false,im::ItoIsometryMethod{K} = Trapezoidal(20,method)) where {d,AT,BT,cT,N,fT,K}
    # DiscretizationLength discretisated time interval length
    # n_steps: how many mapping matrix to calculate
    ts =  collect(fT,take(n_steps + 1, iterated(x -> method.Δt + x, zero(method.Δt))))
    n = (rOfDelay(DiscretizationLength, method) + 1) * d
    A_avgs = calculate_Aavgs(LDDEP.A, ts, method.Δt)


    subMXs = [Vector{SubMX{eltype(A_avgs)}}(undef, n_steps) for i in 1:(length(LDDEP.Bs) + 1)] # []
    stsubMXs = [Vector{stSubMX{SizedArray{Tuple{d,d},SArray{Tuple{K},eltype(eltype(A_avgs)),1,K},2,2}}}(undef,n_steps) for i in 1:(length(LDDEP.αs)+length(LDDEP.βs))]

    if calculate_additive
        subVs = Vector{SubV{SVector{d,eltype(eltype(A_avgs))}}}(undef, n_steps) # []
        stsubVs = Vector{Vector{stSubV{SizedArray{Tuple{d},SArray{Tuple{K},Float64,1,K},1,1}}}}(undef, LDDEP.w);
        # stSubV(LDDEP.dnoise.delayMX.τ.τ.ws, [Vector{SubV}(undef,n_steps) for i in LDDEP.dnoise.delayMX.τ.τ.ws]) # []
    else
        subVs = Vector{SubV{SVector{d,eltype(eltype(A_avgs))}}}(undef, 0)
        stsubVs = Vector{Vector{stSubV{SizedArray{Tuple{d},SArray{Tuple{K},Float64,1,K},1,1}}}}(undef, 0)
    end
    Result(LDDEP, method, im, subMXs, stsubMXs, subVs, stsubVs, A_avgs, ts, n_steps, n,calculate_additive)
end

struct stDiscreteMapping{tT,dmxT,stmxT,dvT,stvT}
    ts::Vector{tT}
    detMXs::Vector{dmxT} # F [time]
    detVs::Vector{dvT} # f [time]
    stMXs::Vector{Vector{stmxT}} # G [time][noiseID]
    stVs::Vector{Vector{stvT}} # g [time][noiseID]
end


struct DiscreteMapping_M1{tT,mxT,vT}
    ts::Vector{tT}
    M1_MXs::Vector{mxT}
    M1_Vs::Vector{vT}
end

struct DiscreteMapping_M2{tT,mx1T,mx2T,mx12T,v1T,v2T}#,mx12T,v2T
    ts::Vector{tT}
    M1_MXs::Vector{mx1T} # F [time]
    M1_Vs::Vector{v1T} # c_1 [time]
    M2_MXs::Vector{mx2T} # H [time]
    M1toM2_MXs::Vector{mx12T} # C [time]
    M2_Vs::Vector{v2T} # c_2 [time]
end
