include("variable.jl")
include("constraint.jl")

function MOIU.allocate(optimizer::SOItoMOIBridge, ::MOI.ObjectiveSense, sense::MOI.OptimizationSense)
    # To be sure that it is done before load(optimizer, ::ObjectiveFunction, ...), we do it in allocate
    optimizer.objsign = sense == MOI.MIN_SENSE ? -1 : 1
end
function MOIU.allocate(::SOItoMOIBridge, ::MOI.ObjectiveFunction, ::Union{MOI.SingleVariable, MOI.ScalarAffineFunction}) end

function MOIU.load(::SOItoMOIBridge, ::MOI.ObjectiveSense, ::MOI.OptimizationSense) end
# Loads objective coefficient α * vi
function load_objective_term!(optimizer::SOItoMOIBridge, α, vi::MOI.VariableIndex)
    for (blk, i, j, coef, shift) in varmap(optimizer, vi)
        if !iszero(blk)
            # in SDP format, it is max and in MPB Conic format it is min
            setobjectivecoefficient!(optimizer.sdoptimizer, optimizer.objsign * coef * α, blk, i, j)
        end
        optimizer.objshift += α * shift
    end
end
function MOIU.load(optimizer::SOItoMOIBridge, ::MOI.ObjectiveFunction, f::MOI.ScalarAffineFunction)
    obj = MOIU.canonical(f)
    optimizer.objconstant = f.constant
    for t in obj.terms
        if !iszero(t.coefficient)
            load_objective_term!(optimizer, t.coefficient, t.variable_index)
        end
    end
end
function MOIU.load(optimizer::SOItoMOIBridge{T}, ::MOI.ObjectiveFunction, f::MOI.SingleVariable) where T
    load_objective_term!(optimizer, one(T), f.variable)
end

function MOIU.allocate_variables(optimizer::SOItoMOIBridge{T}, nvars) where T
    optimizer.free = BitSet(1:nvars)
    optimizer.varmap = Vector{Vector{Tuple{Int, Int, Int, T, T}}}(undef, nvars)
    VI.(1:nvars)
end

function MOIU.load_variables(optimizer::SOItoMOIBridge, nvars)
    @assert nvars == length(optimizer.varmap)
    loadfreevariables!(optimizer)
    init!(optimizer.sdoptimizer, optimizer.blockdims, optimizer.nconstrs)
end
