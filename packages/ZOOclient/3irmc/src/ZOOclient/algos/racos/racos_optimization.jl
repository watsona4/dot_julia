type RacosOptimization
    best_solution
    algorithm

    function RacosOptimization()
        return new(Nullable(), Nullable())
    end
end

# General optimization function, it will choose optimization algorithm according to parameter.get_sequential()
# If user hasn't define uncertain_bits in parameter, set_ub() will set uncertain_bits automatically according to dim
# in objective
function opt!(ro::RacosOptimization, objective, parameter)
    ro_clear!(ro)
    uncertain_bits = set_ub(objective)
    if parameter.sequential == true
        ro.algorithm = SRacos()
        ro.best_solution = sracos_opt!(ro.algorithm, objective, parameter, ub=uncertain_bits)
    else
        ro.algorithm = Racos()
        ro.best_solution = racos_opt!(ro.algorithm, objective, parameter, ub=uncertain_bits)
    end
    return ro.best_solution
end

function ro_clear!(ro::RacosOptimization)
    ro.best_solution = Nullable()
    ro.algorithm = Nullable()
end

# Set uncertain_bits
function set_ub(objective)
    dim = objective.dim
    dim_size = dim.size
    discrete = is_discrete(dim)
    if discrete==false
        if dim_size <= 100
            ub = 1
        elseif dim_size <= 1000
            ub = 2
        else
            ub = 3
        end
    else
        if dim_size <= 10
            ub = 1
        elseif dim_size <= 50
            ub = 2
        elseif dim_size <= 100
            ub = 3
        elseif dim_size <= 1000
            ub = 4
        else
            ub = 5
        end
    end
    return ub
end
