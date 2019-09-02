function add_split_with_step_function(array_of_funcs::Array, ind::Int, split_variable::Symbol, split_point::Float64, removeSplitFunction::Bool)
    basis_function1 = Piecewise_Function( vcat(Sum_Of_Functions([PE_Function(0.0)]), Sum_Of_Functions([PE_Function(1.0)])) , OrderedDict{Symbol,Array{Float64,1}}(split_variable .=> [[-Inf, split_point]]))
    basis_function2 = Piecewise_Function( vcat(Sum_Of_Functions([PE_Function(1.0)]), Sum_Of_Functions([PE_Function(0.0)])) , OrderedDict{Symbol,Array{Float64,1}}(split_variable .=> [[-Inf, split_point]]))
    other_functions = array_of_funcs[1:end .!= ind] # ind is the index of the function to split.
    split_function = array_of_funcs[ind]
    if removeSplitFunction
        return vcat(other_functions, basis_function1 * split_function, basis_function2 * split_function)
    else
        return vcat(array_of_funcs, basis_function1 * split_function, basis_function2 * split_function)
    end
end

function add_split_with_max_function(array_of_funcs::Array, ind::Int, split_variable::Symbol, split_point::Float64, removeSplitFunction::Bool)
    max_func = Sum_Of_Functions([PE_Function(1.0, Dict{Symbol,PE_Unit}(split_variable => PE_Unit(0.0,split_point,1)))])
    basis_function1 = Piecewise_Function( vcat(Sum_Of_Functions([PE_Function(0.0)]), max_func) , OrderedDict{Symbol,Array{Float64,1}}(split_variable .=> [[-Inf, split_point]]))
    basis_function2 = Piecewise_Function( vcat(-1 * max_func, Sum_Of_Functions([PE_Function(0.0)])) , OrderedDict{Symbol,Array{Float64,1}}(split_variable .=> [[-Inf, split_point]]))
    other_functions = array_of_funcs[1:end .!= ind] # ind is the index of the function to split.
    split_function = array_of_funcs[ind]
    if removeSplitFunction
        return vcat(other_functions, basis_function1 * split_function, basis_function2 * split_function)
    else
        return vcat(array_of_funcs, basis_function1 * split_function, basis_function2 * split_function)
    end
end

function optimise_given_specific_split(dd::DataFrame, y::Symbol, array_of_funcs::Array, ind::Int, split_variable::Symbol, split_point::Float64, SplitFunction::Function, removeSplitFunction::Bool)
    model = SplitFunction(array_of_funcs, ind, split_variable, split_point, removeSplitFunction)
    updated_model, reg = create_ols_approximation(dd, y, model)
    SSR = sum((reg.rr.mu .- reg.rr.y) .^ 2)
    return SSR
end

function optimise_split(dd::DataFrame, y::Symbol, array_of_funcs::Array, ind::Int, split_variable::Symbol, rel_tol::Float64, SplitFunction::Function, removeSplitFunction::Bool)
    lower_limit = minimum(dd[split_variable]) + eps()
    upper_limit = maximum(dd[split_variable]) - eps()
    opt = optimize( x ->  optimise_given_specific_split(dd, y, array_of_funcs, ind, split_variable, x, SplitFunction, removeSplitFunction), lower_limit, upper_limit; rel_tol = rel_tol)
    return (opt.minimum, opt.minimizer)
end

"""
    create_recursive_partitioning(dd::DataFrame, y::Symbol, x_variables::Set{Symbol}, MaxM::Int; rel_tol::Float64 = 1e-10)

This creates a recusive partitioning approximation. This seperates the space in to a series of hypercubes each of which has a constant
value within the hypercube. Each step of the algorithm divides a hypercube along some dimension so that the different parts of the hypercube
can recieve a different value.
The relative tolerance is used in a one-dimensional optimisation step to determine what points at which split values to place
a hypercube in a particular dimension. The default is intentionally set high because it generally doesnt matter
that much. For small scale data however you might want to decrease it and increase it for large scale data. You might also want to
decrease it if spline creation time doesnt matter much. Note that a small rel_tol only affects creation time for the spline and
not the evaluation time.
"""

function create_recursive_partitioning(dd::DataFrame, y::Symbol, x_variables::Set{Symbol}, MaxM::Int; rel_tol::Float64 = 1e-2)
    Arr = Array{Sum_Of_Functions,length(x_variables)}(undef, repeat([1], length(x_variables))...)
    Arr[repeat([1], length(x_variables))...] = Sum_Of_Functions([PE_Function(1.0)])
    pw_func = Piecewise_Function(Arr, OrderedDict{Symbol,Array{Float64,1}}(x_variables .=> repeat([[-Inf]],3)) )
    array_of_funcs = Array{Piecewise_Function,1}([pw_func])
    for M in 2:MaxM
        best_lof    = Inf
        best_m      = 1
        best_dimen  = collect(x_variables)[1]
        best_split  = 0.0
        for m in 1:length(array_of_funcs)
            for dimen in x_variables
                lof, spt = optimise_split(dd, y, array_of_funcs, m, dimen, rel_tol, add_split_with_step_function, true)
                if lof < best_lof
                    best_lof = lof
                    best_m = m
                    best_dimen = dimen
                    best_split = spt
                end
            end
        end
        array_of_funcs = add_split_with_step_function(array_of_funcs, best_m, best_dimen, best_split, true)
    end
    updated_model, reg = create_ols_approximation(dd, y, array_of_funcs)
    return (model = updated_model, regression = reg)
end

"""
    create_mars_spline(dd::DataFrame, y::Symbol, x_variables::Set{Symbol}, MaxM::Int; rel_tol::Float64 = 1e-2)

This creates a mars spline given a dataframe, response variable and a set of x_variables from the dataframe.
The relative tolerance is used in a one-dimensional optimisation step to determine what points at which split values to place
a max(0,x-split) function in a particular dimension. The default is intentionally set high because precision is generally not the
not that important. For small scale data however you might want to decrease it and increase it for large scale data. You might also want to
decrease it if spline creation time doesnt matter much. Note that a small rel_tol only affects creation time for the spline and
not the evaluation time.
"""
function create_mars_spline(dd::DataFrame, y::Symbol, x_variables::Set{Symbol}, MaxM::Int; rel_tol::Float64 = 1e-2)
    # This should be made more efficient using FAST MARS. https://statistics.stanford.edu/sites/default/files/LCS%20110.pdf
    Arr = Array{Sum_Of_Functions,length(x_variables)}(undef, repeat([1], length(x_variables))...)
    Arr[repeat([1], length(x_variables))...] = Sum_Of_Functions([PE_Function(1.0)])
    pw_func = Piecewise_Function(Arr, OrderedDict{Symbol,Array{Float64,1}}(x_variables .=> repeat([[-Inf]],3)) )
    array_of_funcs = Array{Piecewise_Function,1}([pw_func])
    for M in 2:MaxM
        best_lof    = Inf
        best_m      = 1
        best_dimen  = collect(x_variables)[1]
        best_split  = 0.0
        for m in 1:length(array_of_funcs)
            underlying = underlying_dimensions(array_of_funcs[m])
            for dimen in setdiff(x_variables, underlying)
                lof, spt = optimise_split(dd, y, array_of_funcs, m, dimen, rel_tol, add_split_with_max_function, false)
                if lof < best_lof
                    best_lof = lof
                    best_m = m
                    best_dimen = dimen
                    best_split = spt
                end
            end
        end
        array_of_funcs = add_split_with_max_function(array_of_funcs, best_m, best_dimen, best_split, false)
    end
    updated_model, reg = create_ols_approximation(dd, y, array_of_funcs)
    return (model = updated_model, regression = reg)
end

function trim_mars_spline_final_number_of_functions(dd::DataFrame, y::Symbol, model::Sum_Of_Piecewise_Functions, final_number_of_functions::Int)
    if final_number_of_functions < 2
        error("Cannot trim the number of functions to less than 2")
    end
    array_of_funcs = deepcopy(model.functions_)
    functions_to_delete = length(model.functions_) - final_number_of_functions
    for M in 1:functions_to_delete
        best_lof = Inf
        best_m = 2
        len = length(array_of_funcs)
        for m in 2:len
            reduced_array_of_functions = array_of_funcs[1:end .!= m]
            mod2, reg = create_ols_approximation(dd, y, reduced_array_of_functions)
            new_lof = sum((reg.rr.mu .- reg.rr.y) .^ 2)
            if new_lof < best_lof
                best_lof = new_lof
                best_m = m
            end

        end
        array_of_funcs = array_of_funcs[1:end .!= best_m]
    end
    updated_model, reg = create_ols_approximation(dd, y, array_of_funcs)
    return (model = updated_model, regression = reg)
end
function trim_mars_spline_maximum_increase_in_RSS(dd::DataFrame, y::Symbol, model::Sum_Of_Piecewise_Functions, maximum_increase_in_RSS::Float64)
    array_of_funcs = deepcopy(model.functions_)
    updated_model, reg = create_ols_approximation(dd, y, array_of_funcs)
    previous_best_lof = sum((reg.rr.mu .- reg.rr.y) .^ 2)
    ender = false
    while (ender = true) & (length(array_of_funcs) > 1)
        best_m = 2
        best_lof = Inf
        len = length(array_of_funcs)
        for m in 2:len
            reduced_array_of_functions = array_of_funcs[1:end .!= m]
            mod2, reg = create_ols_approximation(dd, y, reduced_array_of_functions)
            new_lof = sum((reg.rr.mu .- reg.rr.y) .^ 2)
            if new_lof < best_lof
                best_lof = new_lof
                best_m = m
            end

        end
        if best_lof - previous_best_lof < maximum_increase_in_RSS
            array_of_funcs = array_of_funcs[1:end .!= best_m]
            previous_best_lof = best_lof
        else
            ender = true
            updated_model, reg = create_ols_approximation(dd, y, array_of_funcs)
            return (model = updated_model, regression = reg)
        end
    end
    updated_model, reg = create_ols_approximation(dd, y, array_of_funcs)
    return (model = updated_model, regression = reg)
end
function trim_mars_spline_maximum_RSS(dd::DataFrame, y::Symbol, model::Sum_Of_Piecewise_Functions, maximum_RSS::Float64)
    array_of_funcs = deepcopy(model.functions_)
    ender = false
    while (ender = true) & (length(array_of_funcs) > 1)
        best_lof = Inf
        best_m = 2
        len = length(array_of_funcs)
        for m in 2:len
            reduced_array_of_functions = array_of_funcs[1:end .!= m]
            mod2, reg = create_ols_approximation(dd, y, reduced_array_of_functions)
            new_lof = sum((reg.rr.mu .- reg.rr.y) .^ 2)
            if new_lof < best_lof
                best_lof = new_lof
                best_m = m
            end

        end
        if best_lof < maximum_RSS
            array_of_funcs = array_of_funcs[1:end .!= best_m]
        else
            ender = true
            updated_model, reg = create_ols_approximation(dd, y, array_of_funcs)
            return (model = updated_model, regression = reg)
        end
    end
    updated_model, reg = create_ols_approximation(dd, y, array_of_funcs)
    return (model = updated_model, regression = reg)
end
"""
trim_mars_spline(dd::DataFrame, y::Symbol, model::Sum_Of_Piecewise_Functions;
                   maximum_RSS::Float64 = -1.0, maximum_increase_in_RSS::Float64 = -1.0, final_number_of_functions::Int = -1)

This trims a mars spline created in the create_mars_spline function. This algorithm goes through
each piecewise function in the mars spline and deletes the one that contributes least to the fit.
A termination criterion must be set. There are three possible termination criterions. The first is
the maximum_RSS that can be tolerated. If this is set then functions will be deleted until the deletion of an
additional function would push RSS over this amount. The second is maximum_increase_in_RSS which will delete
functions until a deletion increases RSS by more than this amount. The final is final_number_of_functions
which reduces the number of fucntions to this number.
"""
function trim_mars_spline(dd::DataFrame, y::Symbol, model::Sum_Of_Piecewise_Functions;
                   maximum_RSS::Float64 = -1.0, maximum_increase_in_RSS::Float64 = -1.0, final_number_of_functions::Int = -1)
    if ((maximum_RSS > 0.0) & (maximum_increase_in_RSS > 0.0)) |
       ((maximum_RSS > 0.0) & (final_number_of_functions > 0)) |
       ((maximum_increase_in_RSS > 0.0) & (final_number_of_functions > 0))
        error("You cannot specify more than one condition for trimming the mars spline.")
    elseif (maximum_RSS < 0.0) & (maximum_increase_in_RSS < 0.0) & (final_number_of_functions < 0)
        error("You must specify at least one condition for trimming. The final number of functions to trim to, the maximum increase in RSS or the maximum RSS.")
    elseif (maximum_RSS > 0.0)
        return trim_mars_spline_maximum_RSS(dd, y, model, maximum_RSS)
    elseif (maximum_increase_in_RSS > 0.0)
        return trim_mars_spline_maximum_increase_in_RSS(dd, y, model, maximum_increase_in_RSS)
    elseif (final_number_of_functions > 0)
        return trim_mars_spline_final_number_of_functions(dd, y, model, final_number_of_functions)
    else
        error("This should be unreachable code. Please let the developer know if you get this.")
    end
end
