# wrapper to convert Nonlinear solver into Conic solver
# The translation is lossy...
# Authors: Emre Yamangil and Miles Lubin

mutable struct NonlinearToConicBridge <: MathProgBase.AbstractConicModel
    # SOLUTION DATA
    solution::Vector{Float64}                       # Vector containing solution
    status                                          # Termination status of the nlp_solver
    objval::Float64                                 # Objective value of optimal solution

    # SOLVER DATA
    nlp_solver::MathProgBase.AbstractMathProgSolver # Choice of nonlinear solver
    remove_single_rows::Bool                        # Preprocessing singleton rows flag
    disaggregate_soc::Bool                          # Disaggregate SOC into 3-dim cones (experimental)
    soc_as_quadratic::Bool                          # Encode SOC constraints in (non-convex) quadratic form

    # PROBLEM DATA
    x                                               # Variables in nonlinear model
    numVar                                          # Number of variables in nonlinear model
    numConstr                                       # Number of constraints in nonlinear model
    nlp_model                                       # Reference to nonlinear model
    A_ini                                           # Initial constraint matrix
    b                                               # Right hand side vector
    constr_cones_ini                                # Initial constraint cones
    var_cones_ini                                   # Initial variable cones

    # CONSTRUCTOR
    function NonlinearToConicBridge(nlp_solver,remove_single_rows,disaggregate_soc,soc_as_quadratic)
        m = new()
        m.nlp_solver = nlp_solver
        m.remove_single_rows = remove_single_rows
        m.disaggregate_soc = disaggregate_soc
        m.soc_as_quadratic = soc_as_quadratic
        return m
    end
end

export ConicNLPWrapper
struct ConicNLPWrapper <: MathProgBase.AbstractMathProgSolver
    nlp_solver::MathProgBase.AbstractMathProgSolver
    remove_single_rows
    disaggregate_soc
    soc_as_quadratic
end

ConicNLPWrapper(;nlp_solver=nothing,remove_single_rows=false,disaggregate_soc=false,soc_as_quadratic=false) = ConicNLPWrapper(nlp_solver,remove_single_rows,disaggregate_soc,soc_as_quadratic)

MathProgBase.ConicModel(s::ConicNLPWrapper) = NonlinearToConicBridge(s.nlp_solver,s.remove_single_rows,s.disaggregate_soc,s.soc_as_quadratic)

function MathProgBase.loadproblem!(m::NonlinearToConicBridge, c, A, b, constr_cones, var_cones)
    if m.nlp_solver == nothing
        error("NLP solver is not specified.")
    end

    nlp_model = Model(solver=m.nlp_solver)
    numVar = length(c) # number of variables
    numConstr = length(b) # number of constraints
    m.A_ini = A
    m.b = b
    m.constr_cones_ini = constr_cones
    m.var_cones_ini = var_cones

    # b - Ax \in K => b - Ax = s, s \in K
    new_var_cones = Any[x for x in var_cones]
    new_constr_cones = Any[]
    copy_constr_cones = copy(constr_cones)
    lengthSpecCones = 0

    # ADD SLACKS FOR ONLY SOC AND EXP
    A_I, A_J, A_V = findnz(A)
    slack_count = numVar+1
    for (cone, ind) in copy_constr_cones
        if cone == :SOC || cone == :ExpPrimal || cone == :SOCRotated
            lengthSpecCones += length(ind)
            slack_vars = slack_count:(slack_count+length(ind)-1)
            append!(A_I, ind)
            append!(A_J, slack_vars)
            append!(A_V, ones(length(ind)))

            push!(new_var_cones, (cone, slack_vars))
            push!(new_constr_cones, (:Zero, ind))
            slack_count += length(ind)
        else
            push!(new_constr_cones, (cone, ind))
        end
    end
    A = sparse(A_I,A_J,A_V, numConstr, numVar + lengthSpecCones)

    m.numVar = size(A,2)
    m.numConstr = numConstr
    c = [c;zeros(m.numVar-numVar)]

    # LOAD NLP MODEL
    @variable(nlp_model, x[i=1:m.numVar], start = 1)

    @objective(nlp_model, Min, dot(c,x))

    for (cone, ind) in new_var_cones
        if cone == :Zero
            for i in ind
                setlowerbound(x[i], 0.0)
                setupperbound(x[i], 0.0)
            end
        elseif cone == :Free
            # do nothing
        elseif cone == :NonNeg
            for i in ind
                setlowerbound(x[i], 0.0)
            end
        elseif cone == :NonPos
            for i in ind
                setupperbound(x[i], 0.0)
            end
        elseif cone == :SOC
            setlowerbound(x[ind[1]], 0.0)
            if m.disaggregate_soc && length(ind) >= 3
                socvar = @variable(nlp_model, [2:length(ind)], lowerbound = 0)
                for k in 2:length(ind)
                    if m.soc_as_quadratic
                        @NLconstraint(nlp_model, x[ind[k]]^2 <= socvar[k]*x[ind[1]])
                    else
                        @NLconstraint(nlp_model, x[ind[k]]^2/x[ind[1]] <= socvar[k])
                    end
                end
                @constraint(nlp_model, sum(socvar) <= x[ind[1]])
            else
                if m.soc_as_quadratic
                    @NLconstraint(nlp_model, sum(x[i]^2 for i in ind[2:length(ind)]) <= x[ind[1]]^2)
                else
                    @NLconstraint(nlp_model, sqrt(sum(x[i]^2 for i in ind[2:length(ind)])) <= x[ind[1]])
                end
            end
        elseif cone == :SOCRotated
            if m.soc_as_quadratic
                @NLconstraint(nlp_model, 2*x[ind[1]]*x[ind[2]] >= sum(x[i]^2 for i in ind[3:length(ind)]))
            else
                @NLconstraint(nlp_model, 2*x[ind[1]] >= sum(x[i]^2 for i in ind[3:length(ind)])/x[ind[2]])
            end
            setlowerbound(x[ind[1]], 0.0)
            setlowerbound(x[ind[2]], 0.0)
        elseif cone == :ExpPrimal
            @NLconstraint(nlp_model, x[ind[2]] * exp(x[ind[1]]/x[ind[2]]) <= x[ind[3]])
            setlowerbound(x[ind[2]], 0.0)
            setlowerbound(x[ind[3]], 0.0)
        end
    end

    # *************** PREPROCESS *******************
    constr_cones_map = [:NoCone for i in 1:numConstr]
    for (cone, ind) in new_constr_cones
        for i in ind
            constr_cones_map[i] = cone
        end
    end

    nonZeroElements = [Any[] for i in 1:numConstr] # by row
    for i in 1:length(A_I)
        push!(nonZeroElements[A_I[i]], (A_J[i], A_V[i]))
    end
    rowIndicator = [true for i in 1:numConstr]
    if m.remove_single_rows
        for i in 1:numConstr
            if length(nonZeroElements[i]) == 1
                (ind, val) = nonZeroElements[i][1]
                if constr_cones_map[i] == :Zero
                    setlowerbound(x[ind], b[i]/val)
                    setupperbound(x[ind], b[i]/val)
                elseif constr_cones_map[i] == :NonNeg
                    if val < 0.0
                        setlowerbound(x[ind], b[i]/val)
                    else
                        setupperbound(x[ind], b[i]/val)
                    end
                elseif constr_cones_map[i] == :NonPos
                    if val < 0.0
                        setupperbound(x[ind], b[i]/val)
                    else
                        setlowerbound(x[ind], b[i]/val)
                    end
                else
                    error("special cone $(constr_cones_map[i]) in constraint cones after preprocess.")
                end
                rowIndicator[i] = false
            end
        end
    end

    rowIndicator = [true for i in 1:numConstr]
    A_byrow = copy(A')
    A_colidx = rowvals(A_byrow)
    A_vals = nonzeros(A_byrow)
    for (cone,ind) in new_constr_cones
        for i in 1:length(ind)
            if rowIndicator[ind[i]]
                if cone == :Zero
                    @constraint(nlp_model, sum( A_vals[k]*x[A_colidx[k]] for k in nzrange(A_byrow, ind[i]) ) == b[ind[i]])
                elseif cone == :NonNeg
                    @constraint(nlp_model, sum( A_vals[k]*x[A_colidx[k]] for k in nzrange(A_byrow, ind[i]) ) <= b[ind[i]])
                elseif cone == :NonPos
                    @constraint(nlp_model, sum( A_vals[k]*x[A_colidx[k]] for k in nzrange(A_byrow, ind[i]) ) >= b[ind[i]])
                else
                    error("unrecognized cone $cone")
                end
            end
        end
    end

    m.x = x
    m.numVar = numVar
    m.nlp_model = nlp_model
end

function MathProgBase.optimize!(m::NonlinearToConicBridge)
    m.status = solve(m.nlp_model, suppress_warnings=true)
    m.objval = getobjectivevalue(m.nlp_model)
    m.solution = getvalue(m.x)
end

MathProgBase.supportedcones(s::ConicNLPWrapper) = [:Free,:Zero,:NonNeg,:NonPos,:SOC,:SOCRotated,:ExpPrimal]

function MathProgBase.setwarmstart!(m::NonlinearToConicBridge, x)
    x_expanded = copy(x)
    val = m.b - m.A_ini*x
    nonlinear_cones = 0
    for (cone, ind) in m.constr_cones_ini
        if cone == :SOC || cone == :ExpPrimal || cone == :SOCRotated
            append!(x_expanded, val[ind])
            nonlinear_cones += 1
        end
    end
    m.solution = x_expanded
    setvalue(m.x, m.solution)
end

function MathProgBase.freemodel!(m::NonlinearToConicBridge)
    if applicable(MathProgBase.freemodel!,m.nlp_model.internalModel)
        MathProgBase.freemodel!(m.nlp_model.internalModel)
    end
end

function MathProgBase.setvartype!(m::NonlinearToConicBridge, v::Vector{Symbol})
    @assert length(v) <= m.numVar
    for i in 1:length(v)
        setcategory(m.x[i], v[i])
    end
end

MathProgBase.status(m::NonlinearToConicBridge) = m.status
MathProgBase.getobjval(m::NonlinearToConicBridge) = m.objval
MathProgBase.getobjbound(m::NonlinearToConicBridge) = getobjbound(m.nlp_model)
MathProgBase.getsolution(m::NonlinearToConicBridge) = m.solution[1:size(m.A_ini,2)]
MathProgBase.getsolvetime(m::NonlinearToConicBridge) = getsolvetime(m.nlp_model)

MathProgBase.numvar(m::NonlinearToConicBridge) = m.numVar
# is numconstr well-defined for conic models?
MathProgBase.numconstr(m::NonlinearToConicBridge) = m.numConstr
