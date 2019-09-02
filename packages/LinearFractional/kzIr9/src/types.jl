@with_kw mutable struct LinearFractionalModel <: JuMP.AbstractModel
    solver
    transformedmodel=JuMP.Model(solver=solver)
    t=@variable(transformedmodel, lowerbound=1e3*eps(Float64), basename="t")
    denom=AffExpr()
    dictList=Any[]
end


struct LinearFractionalVariable <: JuMP.AbstractJuMPScalar
    ## Variable in the untransformed space
    model::LinearFractionalModel
    var::JuMP.Variable ## Internal variable in the transformed space
end


struct LinearFractionalAffExpr <: JuMP.AbstractJuMPScalar
    afftrans::AffExpr
    t::JuMP.Variable
end


function LinearFractionalVariable(m::LinearFractionalModel, lower::Number, upper::Number, cat::Symbol, name::AbstractString="", value::Number=NaN)
    var = JuMP.Variable(m.transformedmodel, -Inf, Inf, cat, name, value)
    lfvar = LinearFractionalVariable(m, var)
    if !isinf(lower)
        setlowerbound(lfvar, lower)
    end
    if !isinf(upper)
        setupperbound(lfvar, upper)
    end
    return lfvar
end

LinearFractionalVariable(m::Model,lower::Number,upper::Number,cat::Symbol,objcoef::Number,
    constraints::JuMPArray,coefficients::Vector{Float64}, name::AbstractString="", value::Number=NaN) =
    LinearFractionalVariable(m, lower, upper, cat, objcoef, constraints.innerArray, coefficients, name, value)
