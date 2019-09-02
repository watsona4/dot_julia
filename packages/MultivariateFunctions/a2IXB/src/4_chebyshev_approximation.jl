

function evaluate_function_at_nodes(func::Function, unnormalised_nodes::Array{Float64,1}, limits::OrderedDict{Symbol,Tuple{Float64,Float64}}, function_takes_Dict::Bool)
    nodes = length(unnormalised_nodes)
    dimensions = length(limits)
    labels = collect(keys(limits))
    normalised_node_array = Array{Float64,2}(undef,nodes, dimensions)
    for i in 1:length(labels)
        dimen = labels[i]
        normalised_nodes = ((unnormalised_nodes .+ 1) .* ((limits[dimen][2]-limits[dimen][1])/2)) .+ limits[dimen][1]
        normalised_node_array[:,i] = normalised_nodes
    end
    y = Array{Float64,dimensions}(undef,repeat([nodes],dimensions)...)
    y_indicies = CartesianIndices(y)
    for i in y_indicies
        index = Tuple(i)
        coords = Array{Float64,1}()
        for j in 1:length(index)
            append!(coords, normalised_node_array[index[j],j])
        end
        if function_takes_Dict
            coordsDict = Dict{Symbol,Float64}(labels .=> coords)
            y[i] = func(coordsDict)
        else
            y[i] = func(coords...)
        end
    end
    return y
end

# The operations of the next two functions are not optimal. If we have the same
# vector in two columns then we could more efficiently multiply them by noting that
# the outer product will be symmetric.
# At some stage it would be good to make better use of symmetry. Come back to this
# wehn the tensor
function expand_array(arr::Array{T} where T, vecc::Array{T,1} where T)
    sze = size(arr)
    dim = length(sze)
    new_arr = Array{typeof(vecc[1]),dim + 1}(undef, vcat(sze..., sze[1])...)
    for i in 1:length(vecc)
        new_arr[repeat([:],dim)...,i] = arr .* vecc[i]
    end
    return new_arr
end
function tensor_outer_product(arr::Array{T,2} where T)
    dim = size(arr)[2]
    if dim == 1
        return Array{typeof(arr[1,1]),1}(arr[:,1])
    end
    big_array = arr[:,1] #* hcat(arr[:,2]...) #transpose(arr[:,2]) as transpose doesnt work with nonnumeric types for T.
    for i in 2:dim
        big_array = expand_array(big_array, arr[:,i])
    end
    return big_array
end

function get_cholesky_coefficients(evaluated_chebyshevs_on_sum_squared::Array{Float64,2}, y::Array{Float64})
    degree = size(evaluated_chebyshevs_on_sum_squared)[2]
    nodes = size(evaluated_chebyshevs_on_sum_squared)[1]
    dimensions = length(size(y))
    coefficients = zeros(repeat([degree], dimensions)...)
    perms = unique(collect(permutations(1:dimensions)))
    indices = CartesianIndices(coefficients)
    for i in indices
        if (coefficients[i] ≂ 0.0)
            reduced_chebs = evaluated_chebyshevs_on_sum_squared[:,[Tuple(i)...]]
            chebs_mat = tensor_outer_product(reduced_chebs) # This will return a nodes^dim size array like y.
            # We coudl get the coefficient by immediately elementwise multiplying by y and then summing but note
            # that if we permute chebs_mat we get the correct chebs_mat for other parts. So we do that first.
            for j in perms
                ind = Tuple(i)[j]
                if (coefficients[CartesianIndex(ind...)] ≂ 0.0)
                    permuted_chevs = Base.permutedims(chebs_mat, j)
                    coefficients[CartesianIndex(ind...)] = sum(permuted_chevs .* y)
                end
            end
        end
    end
    return coefficients
end

function convert_chebyshevs(chebyshevs::Array{Sum_Of_Functions,1}, limits::OrderedDict{Symbol,Tuple{Float64,Float64}})
    dimensions = length(limits)
    degree = length(chebyshevs)
    ks     = collect(keys(limits))
    rescaled_chebs = Array{Sum_Of_Functions,2}(undef, degree, dimensions)
    for i in 1:dimensions
        k = ks[i]
        left, right = limits[k]
        transformed_chebyshevs = convert_to_linearly_rescale_inputs.(chebyshevs, (right-left)/2, +(right+left)/2)
        conversion_dict        = Dict{Symbol,Symbol}([default_symbol] .=> k)
        rescaled_chebs[:,i]    = rebadge.(transformed_chebyshevs, Ref(conversion_dict))
    end
    rescaled_chebs_outer_product = tensor_outer_product(rescaled_chebs)
    return rescaled_chebs_outer_product
end

"""
    create_chebyshev_approximation(f::Function, nodes::Int, degree::Int, limits::OrderedDict{Symbol,Tuple{Float64,Float64}}, function_takes_Dict::Bool = false)
Creates a Sum_Of_Functions that approximates a function, f, with a set of chebyshevs of a particular degree. The nodes input specifies at how many locations the
function is to be evaluated for approximation purposes in each dimension. The limits OrderedDict specifies the domain of where the function is to be approximated.

If function_takes_Dict is true then the function will be evaluated by inputting a  Dict{Symbol,Float64}. Otherwise the function will be evaluated with f(values(limits)...)
Note that the order of the OrderedDict specifies the order of inputs to the function in this case.
"""
function create_chebyshev_approximation(f::Function, nodes::Int, degree::Int, limits::OrderedDict{Symbol,Tuple{Float64,Float64}}, function_takes_Dict::Bool = false)
    # This is all after Algorithm 6.2 from Judd (1998) Numerical Methods in Economics.
    if nodes <= degree
        error("Need to have more nodes than degree to use a chebyshev approximation")
    end
    k = 1:nodes
    unnormalised_nodes = -cos.( (((2 .* k) .- 1) ./ (2 * nodes)) .* pi    )

    chebyshevs = get_chevyshevs_up_to(degree, true)
    evaluated_chebyshevs_on_sum_squared = Array{Float64,2}(undef,nodes, degree)
    for i in 1:degree
        cheb_evaluated_at_each_node = evaluate.(Ref(chebyshevs[i]),unnormalised_nodes)
        evaluated_chebyshevs_on_sum_squared[:,i] = cheb_evaluated_at_each_node ./ sum( cheb_evaluated_at_each_node .^ 2 )
    end
    y = evaluate_function_at_nodes(f, unnormalised_nodes, limits, function_takes_Dict)
    a = get_cholesky_coefficients(evaluated_chebyshevs_on_sum_squared, y)
    transformed_chebyshevs = convert_chebyshevs(chebyshevs, limits)

    all_terms = a .* transformed_chebyshevs
    final_func = Sum_Of_Functions([all_terms...])
    return final_func
end
