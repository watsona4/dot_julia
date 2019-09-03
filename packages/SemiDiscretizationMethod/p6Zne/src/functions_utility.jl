@doc """
    rOfDelay(τ::Float64,dt::Float64,ord::Int64)  
    rOfDelay(τ::Float64,dt::Float64,ord::ORDER)

Calculate the delay resolution for given delay `τ`, time resolution `dt` and order `ord` defined by an integer or `ORDER` type.

## Arguments
- `τ::Float64`: time delay to discretise
- `dt::Float64`: time resolution (length)
- `ord::Int64`/`ord::ORDER`: order of the discretisation
""" rOfDelay
function rOfDelay(τ::Real, dt::Real, ord::Integer)
    Int64((τ + 100eps(τ)) ÷ dt + ord ÷ 2)
  # trunc(Int64,τ/dt+ord/2.+1000*eps())
end
function rOfDelay(τ::Real, ord::Union{FullDiscretization,SemiDiscretization})
    rOfDelay(τ, ord.Δt, methodorder(ord))
end
function nStepOfLength(τ::Real,dt::Real)
    Int64((τ + 100eps(τ)) ÷ dt)
end
@doc """
    subMXrange(i::Int64,d::Int64)

Return the index range of the submatrix in the large discretisation matrix (used for constructing the deterministic matrix)

## Arguments
- `i::Int64`: the index of the state space vector the submatrix is multiplied with
- `d::Int64`: dimension of the state space
""" subMxRange
function subMxRange(i::Int64, d::Int64)
    (1:d, i * d + 1:(i + 1) * d)
end
@doc """
    subMXArray(i::Int64,d::Int64)

Return the index range of the submatrix in the large discretisation matrix as a 1 dimensional array (used for constructing the stochastic matrix)

## Arguments
- `i::Int64`: the index of the state space vector the submatrix is multiplied with
- `d::Int64`: dimension of the state space
""" subMXArray
function subMXArray(i::Int64, d::Int64)
    sMXrng = subMxRange(i, d);
    [(i, j) for i in sMXrng[1],j in sMXrng[2]]
end

@doc """
    subVecRange(d::Int64)

Return the index range of the subvector in the large discretised additive vector (it is always added to the present state)

## Arguments
- `d::Int64`: dimension of the state space
""" subVecRange
function subVecRange(d::Int64)
    (1:nDim, 1:1)
end
@doc """
    subVecArray(d::Int64)

Return the index range of the subvector in the large discretised additive vector as a 1 dimensional array (it is always added to the present state)

## Arguments
- `d::Int64`: dimension of the state space
""" subVecArray
function subVecArray(d::Int64)
    sMXrng = subVecRange(d);
    [(i, j) for i in sMXrng[1],j in sMXrng[2]]
end

@doc """
    addSubmatrixToResult!(result::AbstractArray,subMX::detSubMX)

Add the deterministic submatrix `subMX` to the deterministic mapping matrix
Return the index range of the subvector in the large discretised additive vector as a 1 dimensional array (it is always added to the present state)

## Arguments
- `result::AbstractArray`: mapping matrix to add the subMX to
- `subMX::detSubMX`: submatrix to add to the mapping matrix
""" addSubmatrixToResult!
function addSubmatrixToResult!(result::AbstractArray, subMX::SubMX)
    for i in eachindex(subMX.ranges, subMX.MXs)
        result[subMX.ranges[i]...] .+= subMX.MXs[i]
    end
end
function addSubvectorToResults!(results::AbstractArray, subV::SubV)
    results[1:size(subV.V, 1)] .+= subV.V
end
# function addSubvectorToResults!(results::AbstractArray, subV::SubV)
#     d = size(subV.Vs[1], 1)
#     for j in eachindex(subV.Vs, results)
#         for i in eachindex(subV.Vs[j])
#             results[j][1:d] .+= subV.Vs[j][:]
#         end
#     end
# end

# Towards higher order ############################################################
# Building the Lagrangian polynomial for higher order methods
function lagr_atom(i::Real, k::Real, l::Real, τ::Real, r::Real, h::Real, t::Real)
    ((t - τ) - (i - r) * h - l * h) / ((k - l) * h)
end

function lagr_el(q::Real, i::Real, k::Real, τ::Real, r::Real, h::Real, t::Real)
    range = [0:k - 1; k + 1:q]
    prod([lagr_atom(i, k, l, τ, r, h, t) for l in range])
end

function lagr_atom0(k::Real, l::Real, τerr::Real, h::Real, t::Real)
    (t - l * h - τerr) / ((k - l) * h)
  #((t-τ)-(l-r)*h)/((k-l)*h)
end

function lagr_el0(q::Real, k::Real, τerr::Real, h::Real, t::Real)
    range = [0:(k - 1); (k + 1):q]
    prod([lagr_atom0(k, l, τerr, h, t) for l in range])
end

# Handling multiple time-steps
# Reduction of the mapping matrices and -vectors on a time interval 
function prodl(mappingMXs::Vector{TM}) where TM<:AbstractMatrix
    mx0 = deepcopy(mappingMXs[1])
    for i in 2:length(mappingMXs)
        mx0 .= mappingMXs[i] * mx0
    end
    return mx0
end
function prodl(mappingMXs::Vector{TM},idxs::AbstractVector{<:Integer}) where TM<:AbstractMatrix
    mx0 = deepcopy(mappingMXs[1][idxs,idxs])
    for i in 2:length(mappingMXs)
        mx0 .= mappingMXs[i][idxs,idxs] * mx0
    end
    return mx0
end
# function prodl(mappingMXs::Vector{TM}) where TM<:AbstractMatrix
#     prod(reverse(mappingMXs))
# end
function reduce_additive(mappingMXs::Vector{TM}, mappingVs::Vector{TV}) where {TM<:AbstractMatrix,TV<:AbstractVector}
    mappingV = deepcopy(mappingVs[1]);
    for i in 2:length(mappingVs)
        mappingV .= mappingMXs[i] * mappingV .+ mappingVs[i]
    end
    return mappingV
end
function reduce_additive(mappingMXs::Vector{TM}, mappingVs::Vector{TV}, idxs::AbstractVector{<:Integer}) where {TM<:AbstractMatrix,TV<:AbstractVector}
    mappingV = mappingVs[1][idxs];
    for i in 2:length(mappingVs)
        mappingV .= mappingMXs[i][idxs,idxs] * mappingV .+ mappingVs[i][idxs]
    end
    return mappingV
end


function reduce_additive(mappingMX0::TM, mappingV0::TV, q::Int) where {TM<:AbstractMatrix,TV<:AbstractVector}
    mappingV = deepcopy(mappingV0);
    for i in 2:q
        mappingV .= mappingMX0 * mappingV .+ mappingV0
    end
    return mappingV
end