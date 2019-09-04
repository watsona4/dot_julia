function zoo_min(obj::Objective, par::Parameter)
    obj_clean_history(obj)
    if isnull(par.constraint)
        algorithm = asracos_opt!
    else
        algorithm = pposs_opt!
    end
    solution = algorithm(obj, par)
    return solution
end
