type Objective
    func
    args
    dim
    inherit
    constraint
    history

    function Objective(dim; func= Nullable(), args=Nullable(),
        inherit=obj_default_inherit, constraint=Nullable())
        return new(func, args, dim, obj_default_inherit, constraint, Float64[])
    end
end

function obj_construct_solution(objective::Objective, x; parent=Nullable())
    sol = Solution()
    sol.x = x
    sol.attach = objective.inherit(parent=parent)
    return sol
end

# evaluate the objective function of a solution
function obj_eval(objective, solution)
    solution.value = objective.func(solution, objective.args)
    push!(objective.history, solution.value)
    return solution.value
end

function obj_eval_constraint(objective, solution)
  #Todo
end

function obj_default_inherit(; parent=Nullable())
    return Nullable()
end

function get_history_bestsofar(objective)
    history_bestsofar = Float64[]
    bestsofar = Inf
    for i in 1:length(objective.history)
        if objective.history[i] < bestsofar
            bestsofar = objective.history[i]
        end
        push!(history_bestsofar, bestsofar)
    end
    return history_bestsofar
end

function obj_clean_history(objective::Objective)
    objective.history = []
end
