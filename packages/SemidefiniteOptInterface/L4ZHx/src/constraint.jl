nconstraints(f::Union{SVF, SAF}, s) = 1
nconstraints(f::VVF, s) = length(f.variables)

function _allocate_constraint(m::SOItoMOIBridge, f, s)
    ci = CI{typeof(f), typeof(s)}(m.nconstrs)
    n = nconstraints(f, s)
    # Fails on Julia v0.6
    #m.constrmap[ci] = m.nconstrs .+ (1:n)
    m.constrmap[ci] = (m.nconstrs + 1):(m.nconstrs + n)
    m.nconstrs += n
    return ci
end
function MOIU.allocate_constraint(m::SOItoMOIBridge, f::SAF, s::SupportedSets)
    _allocate_constraint(m::SOItoMOIBridge, f, s)
end

function loadcoefficients!(m::SOItoMOIBridge, cs::UnitRange,
                           f::MOI.ScalarAffineFunction, s)
    f = MOIU.canonical(f) # sum terms with same variables and same outputindex
    @assert length(cs) == 1
    c = first(cs)
    rhs = MOIU.getconstant(s) - MOI._constant(f)
    for t in f.terms
        if !iszero(t.coefficient)
            for (blk, i, j, coef, shift) in varmap(m, t.variable_index)
                if !iszero(blk)
                    @assert !iszero(coef)
                    setconstraintcoefficient!(m.sdoptimizer, t.coefficient*coef, c, blk, i, j)
                end
                rhs -= t.coefficient * shift
            end
        end
    end
    setconstraintconstant!(m.sdoptimizer, rhs, c)
end

function MOIU.load_constraint(m::SOItoMOIBridge, ci::CI, f::SAF, s::SupportedSets)
    setconstant!(m, ci, s)
    cs = m.constrmap[ci]
    @assert !isempty(cs)
    loadcoefficients!(m, cs, f, s)
end
