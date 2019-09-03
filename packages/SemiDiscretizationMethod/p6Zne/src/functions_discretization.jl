# Initialize results

function calculateResults(LDDEP::AbstractLDDEProblem, method::DiscretizationMethod, DiscretizationLength::Real; n_steps::Int64=nStepOfLength(DiscretizationLength, method.Δt), calculate_additive::Bool=false)
    result = Result(LDDEP, method, DiscretizationLength,n_steps=n_steps, calculate_additive=calculate_additive)
    calculateResults!(result)
    return (result)
end
function calculateResults!(result::AbstractResult)
    calculateProportionalResult!(result)
    calculateDelayResult!(result)
    if result.calculate_additive
        calculateAdditiveResult!(result)
    end
    # return (result)
end

function calculateProportionalResult!(rst::AbstractResult)
    registerProportionalResult!(rst,
        rst.method(rst.A_avgs, rst))
end
function calculateDelayResult!(rst::AbstractResult)
    registerDelayResult!(rst,
        rst.method.(rst.LDDEP.Bs, Ref(rst)))
end
function calculateAdditiveResult!(rst::AbstractResult)
    registerAdditiveResult!(rst,
        rst.method(rst.LDDEP.c, rst))
end
function registerProportionalResult!(rst::AbstractResult, submxs::Vector{<:SubMX})
    rst.subMXs[1] .= submxs
end

function registerDelayResult!(rst::AbstractResult, submxs::Vector{<:Vector{<:SubMX}})
    for (i,smx) in enumerate(submxs)
        rst.subMXs[i+1] .= smx
    end
end

function registerAdditiveResult!(rst::AbstractResult, subvs::Vector{<:SubV})
    rst.subVs[:] .= subvs;
end
###############################################################################
############################## Discrete Mapping ###############################
###############################################################################
# For every time step
function DiscreteMapping(LDDEP::AbstractLDDEProblem, method::DiscretizationMethod, DiscretizationLength::Real; n_steps::Int64=nStepOfLength(DiscretizationLength, method.Δt), calculate_additive::Bool=false)
    result = calculateResults(LDDEP, method, DiscretizationLength,n_steps = n_steps, calculate_additive = calculate_additive);
    DiscreteMapping(DiscreteMappingSteps(result)...)
end

function DiscreteMappingSteps(rst::AbstractResult{d}) where d
    mappingMXs = [spdiagm(-d => ones(rst.n-d)) for i in 1:rst.n_steps]
    mappingVs = [spzeros(rst.n) for i in rst.subVs]
    for smx_t in rst.subMXs
        addSubmatrixToResult!.(mappingMXs,smx_t)
    end
    addSubvectorToResults!.(mappingVs, rst.subVs)

    (rst.ts, mappingMXs, mappingVs)
end

# If not all state space values are needed
function DiscreteMapping(LDDEP::AbstractLDDEProblem, method::DiscretizationMethod, DiscretizationLength::Real, idxs::AbstractVector{<:Integer}; n_steps::Int64=nStepOfLength(DiscretizationLength, method.Δt), calculate_additive::Bool=false)
    result = calculateResults(LDDEP, method, DiscretizationLength,n_steps = n_steps, calculate_additive = calculate_additive);
    DiscreteMapping(DiscreteMappingSteps(result, idxs)...)
end
function DiscreteMappingSteps(rst::AbstractResult{d},idxs::AbstractVector{<:Integer}) where d
    mappingMXs = [spdiagm(-d => ones(rst.n-d)) for i in 1:rst.n_steps]
    mappingVs = [spzeros(rst.n) for i in rst.subVs]
    for smx_t in rst.subMXs
        addSubmatrixToResult!.(mappingMXs,smx_t)
    end
    addSubvectorToResults!.(mappingVs, rst.subVs)

    (rst.ts, getindex.(mappingMXs,Ref(idxs),Ref(idxs)), getindex.(mappingVs,Ref(idxs)))
end

###############################################################################
############################# Calculate Functions #############################
###############################################################################
function DiscreteMapping_1step(LDDEP::AbstractLDDEProblem, method::DiscretizationMethod, DiscretizationLength::Real; n_steps::Int64=nStepOfLength(DiscretizationLength, method.Δt), calculate_additive::Bool=false)
    mp=DiscreteMapping(LDDEP, method, DiscretizationLength,n_steps = n_steps, calculate_additive = calculate_additive);
    result = initializeOneStepMapping(mp);
    result.ts .= [mp.ts[1],mp.ts[end]];
    result.mappingMXs[1] = prodl(mp.mappingMXs);
    if calculate_additive
        result.mappingVs[1]=reduce_additive(mp.mappingMXs, mp.mappingVs);
    end
    return result
end

# If not all state space values are needed
function DiscreteMapping_1step(LDDEP::AbstractLDDEProblem, method::DiscretizationMethod, DiscretizationLength::Real, idxs::AbstractVector{<:Integer}; n_steps::Int64=nStepOfLength(DiscretizationLength, method.Δt), calculate_additive::Bool=false)
    mp=DiscreteMapping(LDDEP, method, DiscretizationLength,n_steps = n_steps, calculate_additive = calculate_additive);
    result = initializeOneStepMapping(mp);
    result.ts .= [mp.ts[1],mp.ts[end]];
    result.mappingMXs[1] = prodl(mp.mappingMXs,idxs);
    if calculate_additive
        result.mappingVs[1]=reduce_additive(mp.mappingMXs, mp.mappingVs, idxs);
    end
    return result
end

# Some attributes of the mappings
function fixPointOfMapping(dm::DiscreteMapping)
    (I - prodl(dm.mappingMXs)) \ Vector(reduce_additive(dm.mappingMXs, dm.mappingVs))
end
function fixPointOfMapping(dm::DiscreteMapping, idxs::AbstractVector{<:Integer})
    (I - prodl(dm.mappingMXs,idxs)) \ Vector(reduce_additive(dm.mappingMXs, dm.mappingVs, idxs))
end

function spectralRadiusOfMapping(dm::DiscreteMapping; args...)
    abs(eigs(prodl(dm.mappingMXs); args...)[1][1])
end
function spectralRadiusOfMapping(dm::DiscreteMapping, idxs::AbstractVector{<:Integer}; args...)
    abs(eigs(prodl(dm.mappingMXs, idxs); args...)[1][1])
end