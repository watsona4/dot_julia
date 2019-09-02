variabletype(m::LinearFractionalModel) = LinearFractionalVariable


function constructvariable!(m::LinearFractionalModel, _error::Function, lowerbound::Number, upperbound::Number, category::Symbol, objective::Number, inconstraints::Vector, coefficients::Vector{Float64}, basename::AbstractString, start::Number; extra_kwargs...)
    for (kwarg, _) in extra_kwargs
        _error("Unrecognized keyword argument $kwarg")
    end
    LinearFractionalVariable(m, lowerbound, upperbound, category == :Default ? :Cont : category, objective, inconstraints, coefficients, basename, start)
end

function constructvariable!(m::LinearFractionalModel, _error::Function, lowerbound::Number, upperbound::Number, category::Symbol, basename::AbstractString, start::Number; extra_kwargs...)
    for (kwarg, _) in extra_kwargs
        _error("Unrecognized keyword argument $kwarg")
    end
    LinearFractionalVariable(m, lowerbound, upperbound, category == :Default ? :Cont : category, basename, start)
end


macro objective(m, args...)
    m = esc(m)
    if length(args) != 2
        # Either just an objective sene, or just an expression.
        error("in @objective: needs three arguments: model, objective sense (Max or Min) and expression.")
    end
    sense, x = args
    if sense == :Min || sense == :Max
        sense = Expr(:quote,sense)
    end
    newaff, parsecode = JuMP.parseExprToplevel(x, :q)
    code = quote
        q = Val{false}()
        $parsecode
        setobjective($m, $(esc(sense)), $newaff)
    end
    return assert_validmodel(m, code)
end

macro numerator(m, args...)
    m = esc(m)
    if length(args) != 2
        # Either just an objective sense, or just an expression.
        error("in @objective: needs three arguments: model, objective sense (Max or Min) and expression.")
    end
    sense, numer = args
    if sense == :Min || sense == :Max
        sense = Expr(:quote, sense)
    end
    numeraff, numerparsecode = JuMP.parseExprToplevel(numer, :q)
    code = quote
        q = Val{false}()
        $numerparsecode
        setobjective($(m).transformedmodel, $(esc(sense)), $(numeraff).afftrans)
    end
    return JuMP.assert_validmodel(m, code)
end

macro denominator(m, denom)
    m = esc(m)
    denomaff, denomparsecode = JuMP.parseExprToplevel(denom, :q)
    code = quote
        q = Val{false}()
        $denomparsecode
        setdenominator!($(m), $(denomaff))
    end
    return code
end
