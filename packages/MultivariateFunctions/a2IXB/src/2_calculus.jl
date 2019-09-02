
function derivative_(u::PE_Unit)# Intentially changing name so this is not exported.
    if u.d_ == 0
        result_array = Array{Tuple{Float64,PE_Unit}}(undef,1)
        result_array[1] = (u.b_, PE_Unit(u.b_, u.base_, u.d_))
    else
        result_array = Array{Tuple{Float64,PE_Unit}}(undef,2)
        result_array[1] = (u.b_, PE_Unit(u.b_, u.base_, u.d_))
        result_array[2] = (u.d_, PE_Unit(u.b_, u.base_, u.d_ - 1))
    end
    return result_array
end
function derivative_(u::Array{Tuple{Float64,PE_Unit},1})# Intentially changing name so this is not exported.
    len = length(u)
    heap = Array{Tuple{Float64,PE_Unit},1}()
    for i in 1:len
        u_result = u[i]
        mult = u_result[1]
        output = derivative_(u_result[2])
        output_mults, output_units =  collect(zip(output...))
        output_mults = mult .* vcat(output_mults...)
        output_units = vcat(output_units...)
        zipped_output = collect(zip(output_mults,output_units))
        append!(heap, zipped_output)
    end
    return heap
end

"""
     derivative(f::MultivariateFunction, derivs::Dict{Symbol,Int})
This generates a function representing the derivative of function f. The derivative is
that specified by the derivs dict. So if derivs is Dict{[:x,:y] .=> [1,2]} then there
will be one derivative with respect to x and 2 with respect to y.
"""
function derivative(f::PE_Function, derivs::Dict{Symbol,Int})
    # Should always return a Sum_Of_Functions or a PE_Function.
    dims = keys(derivs)
    fdims = keys(f.units_)

    if (length(setdiff(dims,fdims)) > 0) && minimum(get.(Ref(derivs), [setdiff(dims,fdims)...],0)) < 1
        return PE_Function()
    end
    dims_dict = Dict{Symbol,Array{Tuple{Float64,PE_Unit},1}}()
    units = deepcopy(f.units_)
    for dimen in dims
        num_derivs = derivs[dimen]
        if num_derivs > 0
            if dimen in keys(units)
                unit = pop!(units, dimen)
                der = derivative_(unit)
                for i in 2:num_derivs
                    der = derivative_(der)
                end
                dims_dict[dimen] = der
            else
                dims_dict[dimen] = Array{Tuple{Float64,PE_Unit},1}([(0.0, PE_Unit())])
            end
        end
    end
    array_of_tups = [Dict(dims .=> val) for val in (collect(Iterators.product(getindex.((dims_dict,),dims)...))...,)]
    array_of_pes = PE_Function.(1.0, array_of_tups)
    remaining_dims = PE_Function(f.multiplier_, units)
    final_result = remaining_dims .* array_of_pes
    if length(final_result) == 0
        return PE_Function()
    elseif length(final_result) == 1
        return final_result[1]
    else
        return Sum_Of_Functions(final_result)
    end
end
function derivative(f::Sum_Of_Functions, derivs::Dict{Symbol,Int})
    # Should always return a Sum_Of_Functions or a PE_Function.
    deriv_funcs = derivative.(f.functions_, Ref(derivs))
    return Sum_Of_Functions(deriv_funcs)
end

function derivative(f::Piecewise_Function, derivs::Dict{Symbol,Int})
    max_order = maximum(values(derivs))
    if max_order > 0
        derivatives = derivative.(f.functions_, Ref(derivs))
        return Piecewise_Function(derivatives, f.thresholds_)
    elseif max_order == 0
        return f
    else
        error("Not possible to take a negative derivative. Try evaluating an integral instead.")
    end
end

function derivative(f::Sum_Of_Piecewise_Functions, derivs::Dict{Symbol,Int})
    return derivative(f.global_funcs_, derivs) + sum(derivative.(f.functions_, Ref(derivs)))
end

function derivative(f::Missing, derivs::Dict{Symbol,Int})
    return Missing()
end

function derivative(f::MultivariateFunction)
    if length(setdiff(underlying_dimensions(f), Set([default_symbol]))) == 0
        derivs = Dict{Symbol,Int}(default_symbol => 1)
        return derivative(f, derivs)
    else
        error("It is not possible to take the derivative without inputting a dict specifying the desired derivative unless the only variable is the default one.")
    end
end

function add_to_dict(dic::Dict{Symbol,Int}, new_symbol::Symbol)
    dd = deepcopy(dic)
    if new_symbol in keys(dd)
        dd[new_symbol] = 1 + dd[new_symbol]
        return dd
    else
        dd[new_symbol] = 1
        return dd
    end
end


"""
     all_derivatives(f::MultivariateFunction, degree::Int = 2, dimensions::Set{Symbol} = underlying_dimensions(f))
This generates a dict containing functions representing all of the deriviates of a function up to the order of degree.
"""
function all_derivatives(f::MultivariateFunction, degree::Int = 2, dimensions::Set{Symbol} = underlying_dimensions(f))
    if typeof(f) == MultivariateFunctions.Piecewise_Function
        derivs = Dict{Dict{Symbol,Int},typeof(f)}()
    else
        derivs = Dict{Dict{Symbol,Int},Sum_Of_Functions}()
    end
    derivs[Dict{Symbol,Int}()] =  f
    previous_dicts = Set(collect(keys(derivs)))
    for deg in 1:degree
        for prev in previous_dicts
            for dimension in dimensions
                proposed_dict = add_to_dict(prev,dimension)
                if !(proposed_dict in keys(derivs))
                    derivs[proposed_dict] = derivative(derivs[prev], Dict{Symbol,Int}(dimension => 1))
                end
            end
        end
        previous_dicts = setdiff(keys(derivs), Set(previous_dicts))
    end
    return derivs
end

"""
    jacobian(derivs::Union{Dict{Dict{Symbol,Int},PE_Function},Dict{Dict{Symbol,Int},Sum_Of_Functions},Dict{Dict{Symbol,Int},Piecewise_Function}}, labels::Array{Symbol,1})
    jacobian(f::MultivariateFunction, dimensions::Array{Symbol,1})
This generates an array of MultivariateFunctions representing the derivatives of a function.
This array can be evaluated with evaluate.(jacobian, Ref(coordinates))  to give a vector of the derivative values at a point.
"""
function jacobian(derivs::Union{Dict{Dict{Symbol,Int},PE_Function},Dict{Dict{Symbol,Int},Sum_Of_Functions},Dict{Dict{Symbol,Int},Piecewise_Function}}, labels::Array{Symbol,1})
    ders = Array{MultivariateFunction,1}(undef,length(labels))
    for i in 1:length(labels)
        lookup_dict = Dict{Symbol,Int}(labels[i] => 1)
        ders[i] = derivs[lookup_dict]
    end
    return ders
end

function jacobian(f::MultivariateFunction, dimensions::Array{Symbol,1})
    derivs = all_derivatives(f, 1, Set(dimensions))
    return jacobian(derivs, dimensions)
end

"""
    Hessian(f::MultivariateFunction, dimensions::Array{Symbol,1})
    Hessian(derivs::Union{Dict{Dict{Symbol,Int},PE_Function},Dict{Dict{Symbol,Int},Sum_Of_Functions},Dict{Dict{Symbol,Int},Piecewise_Function}}, labels_::Array{Symbol,1})
This represents expressions for constructing a hessian matrix for a function. It can be evaluated
to get a symmetric matrix of the hessian at a particular location.
"""
struct Hessian
    derivs_::Union{Dict{Dict{Symbol,Int},PE_Function},Dict{Dict{Symbol,Int},Sum_Of_Functions},Dict{Dict{Symbol,Int},Piecewise_Function}}
    labels_::Array{Symbol,1}
    function Hessian(derivs::Union{Dict{Dict{Symbol,Int},PE_Function},Dict{Dict{Symbol,Int},Sum_Of_Functions},Dict{Dict{Symbol,Int},Piecewise_Function}}, labels_::Array{Symbol,1})
        new(derivs, labels_)
    end
    function Hessian(f::MultivariateFunction, dimensions::Array{Symbol,1})
        derivs = all_derivatives(f, 2, Set(dimensions))
        return Hessian(derivs, dimensions)
    end
end

"""
    evaluate(hess::Hessian, coordinates::Dict{Symbol,Float64})
This evaluates a Hessian object to create a Symmetric matrix representing the hessian
at a point.
"""
function evaluate(hess::Hessian, coordinates::Dict{Symbol,Float64})
    len = length(hess.labels_)
    second_derivs = Array{Float64,2}(undef,len,len)
    for c in 1:len
        for r in c:len
            lookup_dict = Dict{Symbol,Int}([hess.labels_[r],hess.labels_[c]] .=> [1,1])
            func = hess.derivs_[lookup_dict]
            val = evaluate(func, coordinates)
            second_derivs[r,c] = val
        end
    end
    return Symmetric(second_derivs, :L)
end

"""
    find_local_optima(func::MultivariateFunction, initial_guess::Dict{Symbol,Float64}; step_size::Float64 = 1.0, max_iters::Int = 40, convergence_tol::Float64 = 1e-10, print_reports::Bool = false)
This takes the analytical jacobian and hessian of a function and uses them to find a nearby
optima. The optima it will find are based on Newton's method. There is no way to specify whether
a minimum or a maximum is sought in Newton's method (at least the pure version of it) and thus
this function cannot selectively search for a maximum or minimum. It simply searches for a stationary point.
"""
function find_local_optima(func::MultivariateFunction, initial_guess::Dict{Symbol,Float64}; step_size::Float64 = 1.0, max_iters::Int = 40, convergence_tol::Float64 = 1e-10, print_reports::Bool = false)
    dimensions = collect(keys(initial_guess))
    dimensions_without_guess = setdiff(underlying_dimensions(func), Set(dimensions))
    if length(dimensions_without_guess) > 0
        error(string("A guess value must be input for all dimensions in the function for which a root is sought. But ", collect(dimensions_without_guess), " has/have no guess values."))
    end
    derivs = all_derivatives(func, 2, Set(dimensions))
    jacob = jacobian(derivs, dimensions)
    hess  = Hessian(derivs, dimensions)
    guess = initial_guess
    iter = 1
    while iter <= max_iters
        hessn = evaluate(hess, guess)
        inverse_hessian = inv(hessn)
        evaluated_jacobian = evaluate.(jacob, Ref(guess))
        if all(abs.(evaluated_jacobian) .< convergence_tol)
            val = evaluate(func,guess)
            if print_reports
                println(string("Converged. The converged value of f is ", val, "."))
            end
            hessian_det_sign = det(hessn) > 0
            return NamedTuple{(:coordinates, :value, :convergence, :positive_definite_hessian)}((guess, val, true, hessian_det_sign))
        end
        step_ = inverse_hessian * evaluated_jacobian
        x = get.(Ref(guess), dimensions, 0)
        x_prime = x - step_size * step_
        guess = Dict{Symbol,Float64}(dimensions .=> x_prime)
        iter = iter + 1
    end
    val = evaluate(func,guess)
    if print_reports
        println(string("Did not converge. The value of the function is ", val, "."))
    end
    return NamedTuple{(:coordinates, :value, :convergence)}((guess, val, false))
#    x - step_size * (hessian^{-1}) * jacobian.
end

"""
    uniroot(f::MultivariateFunction, initial_guess::Dict{Symbol,Float64}; step_size::Float64 = 1.0, max_iters::Int = 40, convergence_tol::Float64 = 1e-10, print_reports::Bool = false)
This takes the analytical jacobian and hessian of a function and uses them to find a nearby
root. It finds a root using Newton's method.
"""
function uniroot(f::MultivariateFunction, initial_guess::Dict{Symbol,Float64}; step_size::Float64 = 1.0, max_iters::Int = 40, convergence_tol::Float64 = 1e-10, print_reports::Bool = false)
    dimensions = collect(keys(initial_guess))
    dimensions_without_guess = setdiff(underlying_dimensions(f), Set(dimensions))
    if length(dimensions_without_guess) > 0
        error(string("A guess value must be input for all dimensions in the function for which a root is sought. But ", collect(dimensions_without_guess), " has/have no guess values."))
    end
    derivs = all_derivatives(f, 1, Set(dimensions))
    jacob = jacobian(derivs, dimensions)
    guess = initial_guess
    iter = 1
    while iter <= max_iters
        val = evaluate(f,guess)
        if abs(val) < convergence_tol
            if print_reports
                println(string("Converged. The converged value of f is ", val, "."))
            end
            return NamedTuple{(:coordinates, :value, :convergence)}((guess,val, true))
        end
        step_ = val ./ evaluate.(jacob, Ref(guess))
        if print_reports
            println(string("Iterate: ",iter,"  The value of f is ", val, " and the next step's Euclidean distance is (excluding step_size multiplier) ", sqrt(sum(step_ .^ 2))))
        end
        x = get.(Ref(guess), dimensions, 0)
        x_prime = x - step_size * step_
        guess = Dict{Symbol,Float64}(dimensions .=> x_prime)
        iter = iter + 1
    end
    val = evaluate(f,guess)
    if print_reports
        println(string("Did not converge. The value of f is ", val, "."))
    end
    return NamedTuple{(:coordinates, :value, :convergence)}((guess, val, false))
end




## Integration
function indefinite_integral(u::PE_Unit, incoming_multiplier::Float64 = 1.0)# Intentially changing name so this is not exported.
    result_array = Array{Tuple{Float64,PE_Unit}}(undef,1)
    if u.b_ ≂ 0.0
        result_array[1] = (incoming_multiplier/(u.d_+1), PE_Unit(u.b_, u.base_, u.d_+1)) # Note (u.d_+1) > 0 because u.d_ \geq 0
        return result_array
    else
        result_array[1] = (incoming_multiplier/u.b_, PE_Unit(u.b_, u.base_, u.d_))
        if u.d_ > 0
            other_pieces_multiplier = -incoming_multiplier * (u.d_ / u.b_)
            other_pieces_unit = PE_Unit(u.b_, u.base_, u.d_ - 1)
            other_pieces = indefinite_integral(other_pieces_unit, other_pieces_multiplier)
            append!(result_array, other_pieces)
        end
        return result_array
    end
end

function apply_limits(mult::Float64, indef::Array{Tuple{Float64,PE_Unit}}, left::Symbol, right::Symbol)# Intentially changing name so this is not exported.
    converted = (collect(Iterators.product(((indef,))...))...,)
    rights = [Dict{Symbol,Tuple{Float64,PE_Unit}}([right] .=> val) for val in converted]
    lefts  = [Dict{Symbol,Tuple{Float64,PE_Unit}}([left] .=> val) for val in converted]
    return Sum_Of_Functions(PE_Function.(mult, rights)) - Sum_Of_Functions(PE_Function.(mult, lefts))
end
function apply_limits(mult::Float64, indef::Array{Tuple{Float64,PE_Unit}}, left::Float64, right::Symbol)# Intentially changing name so this is not exported.
    converted = (collect(Iterators.product(((indef,))...))...,)
    rights = [Dict{Symbol,Tuple{Float64,PE_Unit}}([right] .=> val) for val in converted]
    lefts  = [Dict{Symbol,Tuple{Float64,PE_Unit}}([:left] .=> val) for val in converted]
    return Sum_Of_Functions(PE_Function.(mult, rights)) - sum(evaluate.(PE_Function.(mult, lefts), Ref(Dict{Symbol,Float64}(:left => left))))
end
function apply_limits(mult::Float64, indef::Array{Tuple{Float64,PE_Unit}}, left::Symbol, right::Float64)# Intentially changing name so this is not exported.
    converted = (collect(Iterators.product(((indef,))...))...,)
    rights = [Dict{Symbol,Tuple{Float64,PE_Unit}}([:right] .=> val) for val in converted]
    lefts  = [Dict{Symbol,Tuple{Float64,PE_Unit}}([left] .=> val) for val in converted]
    return evaluate.(Sum_Of_Functions(PE_Function.(mult, rights)), Ref(Dict{Symbol,Float64}(:right => right))   ) - Sum_Of_Functions(PE_Function.(mult, lefts))
end
function apply_limits(mult::Float64, indef::Array{Tuple{Float64,PE_Unit}}, left::Float64, right::Float64)# Intentially changing name so this is not exported.
    converted = (collect(Iterators.product(((indef,))...))...,)
    converted_again = [Dict{Symbol,Tuple{Float64,PE_Unit}}([default_symbol] .=> val) for val in converted]
    funcs = Sum_Of_Functions(PE_Function.(mult, converted_again))
    return evaluate.(funcs, right) - evaluate.(funcs, left)
end

const IntegrationLimitDict = Union{Dict{Symbol,Tuple{Union{Symbol,Float64},Union{Symbol,Float64}}},Dict{Symbol,Tuple{Symbol,Symbol}},Dict{Symbol,Tuple{Float64,Float64}},Dict{Symbol,Tuple{Symbol,Float64}},Dict{Symbol,Tuple{Float64,Symbol}}}

"""
     integral(f::PE_Function, limits::Dict{Symbol,Tuple{Union{Symbol,Float64},Union{Symbol,Float64}}})
     integral(f::Sum_Of_Functions, limits::Dict{Symbol,Tuple{Union{Symbol,Float64},Union{Symbol,Float64}}})
This gives a function representing the integral of a function, f, with limits in each dimension given by a dict. The dict should
contain a tuple for each variable in the function. The left member of the tuple contains the lower limit
and the right member the upper limite. Each can be a Float64 or a symbol. If a symbol is input then
this will get incorporated as a dimension in the MultivariateFunction created by the integral function.
"""
function integral(f::PE_Function, limits::IntegrationLimitDict)
    if length(f.units_) == 0
        volume_of_cube = 1.0
        for dimen in keys(limits)
            volume_of_cube = volume_of_cube * (limits[dimen][2] - limits[dimen][1])
        end
        return volume_of_cube * f.multiplier_
    end
    units = deepcopy(f.units_)
    result_by_dimension = Array{Union{Float64,Sum_Of_Functions,PE_Function},1}()
    for dimen in keys(limits)
        left_  = limits[dimen][1]
        right_ = limits[dimen][2]
        f_unit = Array{PE_Unit,1}(undef,1)
        if haskey(f.units_, dimen)
            f_unit = pop!(units, dimen)
        else
            f_unit = PE_Unit()
        end
        indef  = indefinite_integral(f_unit)
        result_of_applying_limits = apply_limits(1.0, indef, left_, right_)
        append!(result_by_dimension, [result_of_applying_limits])
    end
    if length(units) == 0
        return f.multiplier_ * prod(result_by_dimension)
    else
        return PE_Function(f.multiplier_, units) * prod(result_by_dimension)
    end
end

function integral(f::Sum_Of_Functions, limits::IntegrationLimitDict)
    if length(f.functions_) == 0
        return 0.0
    else
        funcs = integral.(f.functions_, Ref(limits))
        return sum(funcs)
    end
end

"""
     integral(f::Piecewise_Function, limits::Dict{Symbol,Tuple{Float64,Float64}})
     integral(f::Sum_Of_Piecewise_Functions, limits::Dict{Symbol,Tuple{Float64,Float64}})
This gives a function representing the integral of a function, f, with limits in each dimension given by a dict. The dict should
contain a tuple for each variable in the function. The left member of the tuple contains the lower limit
and the right member the upper limite. Each must be a Float64 (Support for inputting a symbol is planned but not yet implemented).
"""
function hypercubes_to_integrate(f::Piecewise_Function, lims::Dict{Symbol,Tuple{Float64,Float64}})
    limits = Dict{Symbol,Tuple{Float64,Float64}}()
    for kk in keys(f.thresholds_)
        limits[kk] = lims[kk]
    end
    ks= sort(collect(keys(limits)))
    new_dict = Dict{Symbol,Array{Float64}}()
    for dimen in ks
        lower = limits[dimen][1]
        upper = limits[dimen][2]
        if lower >= upper
            error(string("The lower limit of integration is higher than the upper for dimension ", dim))
        end
        thresholds = f.thresholds_[dimen]
        censored_thresholds = vcat(lower, thresholds[thresholds .> lower])
        censored_thresholds2 = vcat(censored_thresholds[censored_thresholds .< upper] , upper)
        new_dict[dimen] = censored_thresholds2
    end
    lengths_minus_one = length.(get.(Ref(new_dict),ks,0)) .- 1
    index_combinations = vcat.(collect(collect(Iterators.product(range.(1,lengths_minus_one; step = 1)...))))
    indices = (collect(collect(Iterators.product(range.(1,lengths_minus_one; step = 1)...)))...,)
    indices = collect(collect.(indices))
    total_len = length(indices)
    new_cubes = Array{Dict{Symbol,Tuple{Float64,Float64}},1}(undef,total_len)
    for i in range(1, total_len; step = 1)
        new_cube = Dict{Symbol,Tuple{Float64,Float64}}()
        ind = indices[i]
        for j in 1:length(ks)
            key = ks[j]
            indd = ind[j]
            new_cube[key]  =  (new_dict[key][indd], new_dict[key][indd+1])
        end
        new_cubes[i] = new_cube
    end
    return new_cubes
end

function integral(f::Piecewise_Function, limits::Dict{Symbol,Tuple{Float64,Float64}})
    cubes_to_integrate = hypercubes_to_integrate(f, limits)
    ints = Array{Any,1}(undef,length(cubes_to_integrate))
    for i in 1:length(ints)
        piece_func = get_correct_function_from_piecewise(f, cubes_to_integrate[i])
        ints[i] = integral(piece_func, cubes_to_integrate[i])
    end
    return sum(ints)
end

function integral(f::Sum_Of_Piecewise_Functions, limits::Dict{Symbol,Tuple{Float64,Float64}})
    return integral(f.global_funcs_, limits) + sum(integral.(f.functions_, Ref(limits)))
end

function integral(f::MultivariateFunction, left_limit::Float64, right_limit::Float64)
    underlyingDims = underlying_dimensions(f)
    if length(underlyingDims) == 0
        return f.multiplier_ * (right_limit-left_limit)
    elseif underlyingDims == Set([default_symbol])
        limits_ = Dict{Symbol,Tuple{Float64,Float64}}(default_symbol => Tuple{Float64,Float64}((left_limit,right_limit)))
        return integral(f, limits_)
    else
        error("Cannot evaluate the integral of a Multivariate function without a dictionary set of coordinates unless it is a MultivariateFunction with only the default dimension being used.")
    end
end

function integral(f::MultivariateFunction, left_limit::Date, right_limit::Date)
    if underlying_dimensions(f) == Set([default_symbol])
        limits_ = Dict{Symbol,Tuple{Float64,Float64}}(default_symbol => Tuple{Float64,Float64}((years_from_global_base(left_limit),years_from_global_base(right_limit))))
        return integral(f, limits_)
    else
        error("Cannot evaluate the integral of a Multivariate function without a dictionary set of coordinates unless it is a MultivariateFunction with only the default dimension being used.")
    end
end
