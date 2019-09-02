__precompile__()

module LinearFractional

using JuMP
import JuMP:
    getobjectivevalue,
    getvalue,
    addconstraint,
    solve,
    validmodel,
    constructvariable!,
    constructconstraint!,
    variabletype,
    JuMPArray,
    JuMPContainerData,
    setlowerbound,
    setupperbound,
    addtoexpr_reorder,
    assert_validmodel,
    setobjective,
    storecontainerdata
import MathProgBase.AbstractMathProgSolver
import Base:+, -, *, /
using Parameters

export LinearFractionalModel,
    @denominator,
    @numerator


include("types.jl")
include("operators.jl")
include("constraints.jl")
include("macros.jl")
include("parseexpr.jl")


getvalue(x::LinearFractionalVariable) = getvalue(x.var)/getvalue(x.model.t)
getvalue(aff::LinearFractionalAffExpr) = getvalue(aff.afftrans)/getvalue(aff.t)

Base.one(::Type{LinearFractionalVariable}) = 1.0
Base.one(::LinearFractionalVariable) = one(LinearFractionalVariable)
Base.sum(xs::Array{LinearFractionalAffExpr}) = LinearFractionalAffExpr(sum(x.afftrans for x in xs), xs[1].t)
function Base.sum(xs::Array{LinearFractionalAffExpr}, dim)
    s = sum(collect(x.afftrans for x in xs), dim)
    if ndims == 0
        return LinearFractionalAffExpr(s, xs[1].t)
    else
        return [LinearFractionalAffExpr(aff, xs[1].t) for aff in s]
    end
end


storecontainerdata(m::LinearFractionalModel, variable, varname, idxsets, idxpairs, condition) =
    m.transformedmodel.varData[variable] = JuMPContainerData(varname, map(collect,idxsets), idxpairs, condition)


function AffExpr(vars::Vector{LinearFractionalVariable}, coeffs, constant)
    t = vars[1].model.t
    ys = [var.var for var in vars]
    return LinearFractionalAffExpr(AffExpr(ys, coeffs, 0) + constant * t, t)
end


function addvariable(model::LinearFractionalModel, lb::Number, ub::Number, basename::String)
    var = @variable(model.transformedmodel, basename=basename)
    if !isinf(lb)# || !isinf(ub)
        con = LinearConstraint(LinearFractionalAffExpr([var], [1], [0]), lb, ub)
        addconstraint(model, con)
    end
    return LinearFractionalVariable(model, var)
end


addvariable(model::LinearFractionalModel, basename::String) = addvariable(model, -Inf, Inf, basename)


function setdenominator!(m::LinearFractionalModel, aff::LinearFractionalAffExpr)
    addconstraint(m.transformedmodel, LinearConstraint(aff.afftrans, 1, 1))
    m.denom = aff.afftrans
end


function setdenominator!(m::LinearFractionalModel, x::Float64)
    @constraint(m.transformedmodel, m.t == 1/x)
    m.denom = x
end


function solve(model::LinearFractionalModel)
    JuMP.solve(model.transformedmodel)
end


getobjectivevalue(model::LinearFractionalModel) = getobjectivevalue(model.transformedmodel)


validmodel(model::LinearFractionalModel, name) = nothing


function setlowerbound(v::LinearFractionalVariable, lb)
    if iszero(lb)
        setlowerbound(v.var, 0.0)
    else
        addconstraint(v.model, LinearConstraint(AffExpr([v], [1], 0), lb, Inf))
    end
end


function setupperbound(v::LinearFractionalVariable, ub)
    if iszero(ub)
        setupperbound(v.var, 0.0)
    else
        addconstraint(v.model, LinearConstraint(AffExpr([v], [1], 0), -Inf, ub))
    end
end


setname(v::LinearFractionalVariable, name) = setname(v.var, name)


function setobjective(m::LinearFractionalModel, sense::Symbol, numer::LinearFractionalAffExpr, denom::LinearFractionalAffExpr)
    JuMP.setobjective(m.transformedmodel, sense, numer.afftrans)
    setdenominator!(m, denom)
end


end
