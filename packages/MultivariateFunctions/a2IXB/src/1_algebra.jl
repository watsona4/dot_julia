import Base.+, Base.-, Base./, Base.*, Base.^

# PE_Units
function change_base_(u::PE_Unit, new_base::Float64) # Intentially changing name so this is not exported.
    old_base = u.base_
    diff = new_base - old_base
    if diff  ≂ 0.0
        return Array{Tuple{Float64,PE_Unit},1}([(1.0, u)])
    end
    # First the exponential part.
    mult = exp(u.b_*diff)
    if mult ≂ 0.0
        error("Underflow problem. Changing to this base cannot be done")
    end
    # Now the polynomial part.
    if u.d_ == 0
        new_unit = PE_Unit(u.b_, new_base, 0)
        return Array{Tuple{Float64,PE_Unit},1}([(mult, new_unit)])
    else
        n = u.d_
        funcs = Array{Tuple{Float64,PE_Unit},1}(undef,n+1)
        for r in 0:n
            binom_coeff = factorial(n) / (factorial(r) * factorial(n-r))
            new_multiplier = binom_coeff * mult * diff^r
            new_unit = PE_Unit(u.b_, new_base, n-r)
            new_func = (new_multiplier, new_unit)
            funcs[r+1] = new_func
        end
        return funcs
    end
end

"""
    change_base(f::PE_Function, new_bases::Dict{Symbol,Float64})
This function changes the bases in the PE_Units of a PE_Function. This is useful for getting two
PE_Functions comformable for simpler multiplication. Often a base change means that an array of
PE_Functions are needed to represent a function. So an Array{PE_Function,1} is returned.
"""
function change_base(f::PE_Function, new_bases::Dict{Symbol,Float64})
    dims_dict = Dict{Symbol,Array{Tuple{Float64,PE_Unit},1}}()
    dims = keys(f.units_)
    for dim in dims
        if haskey(new_bases, dim)
            desired_base = new_bases[dim]
            f_unit = f.units_[dim]
            f_base = f_unit.base_
            changed_pes = change_base_(f_unit, desired_base)
            dims_dict[dim] = changed_pes
        else
            dims_dict[dim] = [(1.0,f.units_[dim])]
        end
    end
    array_of_tups = [Dict{Symbol,Tuple{Float64,PE_Unit}}(dims .=> val) for val in (collect(Iterators.product(getindex.((dims_dict,),dims)...))...,)]
    array_of_pes = PE_Function.(f.multiplier_, array_of_tups)
    return array_of_pes
end

function *(u1::PE_Unit,u2::PE_Unit)
    if u1.base_ ≂ u2.base_
        return PE_Unit(u1.b_ + u2.b_, u1.base_, u1.d_ + u2.d_)
    else
        error("Cannot multiply PE_Units without reconciling the bases first.")
    end
end

# PE_Functions
"""
   +(f::MultivariateFunction,number::Float64)
   +(f::MultivariateFunction,number::Int)

   A Multivariate Function can be added to an scalar to from a new MultivariateFunction. This action promotes a
   PE_Function to a Sum_Of_Functions. The type of all other MultivariateFunctions is unchanged.
"""
function +(f::PE_Function,number::Float64)
    constant_function = PE_Function(number, 0.0,0.0,0)
    return Sum_Of_Functions([f, constant_function])
end
"""
   -(f::MultivariateFunction,number::Float64)
   -(f::MultivariateFunction,number::Int)

   A scalar can be subtracted from a Multivariate Function. This action promotes a
   PE_Function to a Sum_Of_Functions. The type of all other MultivariateFunctions is unchanged.
"""
function -(f::PE_Function, number::Float64)
    return +(f, -number)
end
"""
   *(f::MultivariateFunction,number::Float64)
   *(f::MultivariateFunction,number::Int)

   A Multivariate can be multiplied by a scalar. This does not change the type of any MultivariateFunction.
"""
function *(f::PE_Function, number::Float64)
    return PE_Function(f.multiplier_*number, f.units_)
end
"""
   /(f::MultivariateFunction,number::Float64)
   /(f::MultivariateFunction,number::Int)

   A Multivariate can be divided by a scalar. This does not change the type of any MultivariateFunction.
   Note that the opposite operation cannot be done. While f / 5 is permitted 5 / f is not supported by this package.
   It is not possible to divide by a function.
"""
function /(f::PE_Function, number::Float64)
    return *(f, 1/number )
end

function +(f::PE_Function, number::Int)
    number_as_float = convert(Float64, number)
    return +(f, number_as_float)
end
function -(f::PE_Function, number::Int)
    number_as_float = convert(Float64, number)
    return -(f, number_as_float)
end
function *(f::PE_Function, number::Int)
    number_as_float = convert(Float64, number)
    return *(f, number_as_float)
end
function /(f::PE_Function, number::Int)
    number_as_float = convert(Float64, number)
    return /(f, number_as_float)
end
"""
   ^(f::MultivariateFunction,number::Int)

   A Multivariate can be raised by a positive Integer power. This will generally promote a PE_Function to a Sum_Of_Functions.
   Note that the opposite operation cannot be done. While f ^ 5 is permitted 5 ^ f is not supported by this package.
   It is not possible to raise by the power of a function.
"""
function ^(f::PE_Function, number::Int)
    if number < 0
        error("Negative powers are not supported.")
    elseif number == 0
        return PE_Function(1.0)
    elseif number == 1
        return f
    else
        val = f * f
        for i in 3:number
            val = val * f
        end
        return val
    end
end
function ^(f::PE_Function, number::Float64)
    error("Cannot raise a PE_Function to a float value.")
end
"""
    +(f1::MultivariateFunction, f2::MultivariateFunction)
    Any two multivariate Functions can be added to form a MultivariateFunction reflecting the sum.
"""
function +(f1::PE_Function, f2::PE_Function)
    return Sum_Of_Functions([f1,f2])
end
function +(f1::PE_Function, f2::Sum_Of_Functions)
    return Sum_Of_Functions([f1,f2])
end
function +(f1::PE_Function, f2::Piecewise_Function)
    return Piecewise_Function(f1 .+ f2.functions_, f2.thresholds_)
end
function +(f1::PE_Function, f2::Sum_Of_Piecewise_Functions)
    return Sum_Of_Piecewise_Functions(f2.functions_,f2.global_funcs_ + f1)
end

function +(f1::Sum_Of_Functions, f2::PE_Function)
    return +(f2,f1)
end
function +(f1::Piecewise_Function, f2::PE_Function)
    return +(f2,f1)
end
"""
    -(f1::MultivariateFunction, f2::MultivariateFunction)
    Any MultivariateFunction can be subtracted from another to form a MultivariateFunction reflecting the difference.
"""
function -(f1::PE_Function, f2::PE_Function)
    return +(f1,-1*f2)
end
function -(f1::PE_Function, f2::Sum_Of_Functions)
    return +(f1,-1*f2)
end
function -(f1::PE_Function, f2::Piecewise_Function)
    return +(f1, -1*f2 )
end
function -(f1::PE_Function, f2::Sum_Of_Piecewise_Functions)
    return +(f1,-1*f2)
end

function -(f1::Sum_Of_Functions, f2::PE_Function)
    return +(f1,1*f2)
end
function -(f1::Piecewise_Function, f2::PE_Function)
    return +(f1,-1*f2)
end
function -(f1::Sum_Of_Piecewise_Functions, f2::PE_Function)
    return +(f1,-1*f2)
end
"""
    *(f1::MultivariateFunction, f2::MultivariateFunction)
    Any two MultivariateFunctions can be multiplied to form a MultivariateFunction reflecting the product.
"""
function *(f1::PE_Function,f2::PE_Function)
    if (length(f1.units_) == 0)
        return f1.multiplier_ * f2
    elseif (length(f2.units_) == 0)
        return f2.multiplier_ * f1
    else
        f1_bases = get_bases(f1)
        f2_bases = get_bases(f2)
        min_bases = merge(min, f1_bases, f2_bases)
        f1_rebase = change_base(f1, min_bases)
        f2_rebase = change_base(f2, min_bases)
        L1 = length(f1_rebase)
        L2 = length(f2_rebase)
        if (L1 == 1) & (L2 == 1)
            f1_ = f1_rebase[1]
            f2_ = f2_rebase[1]
            new_mult = f1_.multiplier_ * f2_.multiplier_
            return PE_Function(new_mult, merge(*, f1_.units_, f2_.units_ ))
        else
            PEs = Array{PE_Function,1}()
            for f in f1_rebase
                for g in f2_rebase
                    append!(PEs, [f * g])
                end
            end
        end
        return Sum_Of_Functions(PEs)
    end
end

function *(f1::PE_Function, f2::Sum_Of_Functions)
    multiplied_functions = f1 .* f2.functions_
    return Sum_Of_Functions(multiplied_functions)
end
function *(f1::PE_Function, f2::Piecewise_Function)
    return Piecewise_Function(f1 .* f2.functions_, f2.thresholds_)
end
function *(f1::PE_Function, f2::Sum_Of_Piecewise_Functions)
    return f1 * convert(Piecewise_Function, f2)
end

function *(f1::Sum_Of_Functions, f2::PE_Function)
    return *(f2,f1)
end
function *(f1::Piecewise_Function, f2::PE_Function)
    return *(f2,f1)
end
function *(f1::Sum_Of_Piecewise_Functions, f2::PE_Function)
    return *(f2,f1)
end

# Sum of Functions

function +(f::Sum_Of_Functions,number::Float64)
    constant_function = PE_Function(number)
    return Sum_Of_Functions(vcat(f.functions_, [constant_function]))
end
function -(f::Sum_Of_Functions, number::Float64)
    return +(f, -number)
end
function *(f::Sum_Of_Functions, number::Float64)
    funcs = deepcopy(f.functions_)
    for i in 1:length(funcs)
        funcs[i] = funcs[i] * number
    end
    return Sum_Of_Functions(funcs)
end
function /(f::Sum_Of_Functions, number::Float64)
    return *(f, 1/number )
end

function +(f::Sum_Of_Functions, number::Int)
    number_as_float = convert(Float64, number)
    return +(f, number_as_float)
end
function -(f::Sum_Of_Functions, number::Int)
    number_as_float = convert(Float64, number)
    return -(f, number_as_float)
end
function *(f::Sum_Of_Functions, number::Int)
    number_as_float = convert(Float64, number)
    return *(f, number_as_float)
end
function /(f::Sum_Of_Functions, number::Int)
    number_as_float = convert(Float64, number)
    return /(f, number_as_float)
end
function ^(f::MultivariateFunction, number::Int)
    if number < 0
        error("Negative powers are not supported.")
    elseif number == 0
        return PE_Function(1.0)
    elseif number == 1
        return f
    else
        val = f * f
        for i in 3:number
            val = val * f
        end
        return val
    end
end
function ^(f::Sum_Of_Functions, number::Float64)
    error("Cannot raise a Sum_Of_Functions to a float value.")
end

function +(f1::Sum_Of_Functions, f2::Sum_Of_Functions)
    return Sum_Of_Functions([f1,f2])
end
function +(f1::Sum_Of_Functions, f2::Piecewise_Function)
    funcs = deepcopy(f2.functions_)
    for f in f1.functions_
        funcs = funcs .+ f
    end
    return Piecewise_Function(funcs, f2.thresholds_)
end
function +(f1::Sum_Of_Functions, f2::Sum_Of_Piecewise_Functions)
    return Sum_Of_Piecewise_Functions(f2.functions_,f2.global_funcs_ + f1)
end
function +(f1::Piecewise_Function, f2::Sum_Of_Functions)
    return +(f2,f1)
end
function +(f1::Sum_Of_Piecewise_Functions, f2::Sum_Of_Functions)
    return +(f2,f1)
end


function -(f1::Sum_Of_Functions, f2::Sum_Of_Functions)
    return Sum_Of_Functions([f1,-1*f2])
end
function -(f1::Sum_Of_Functions, f2::Piecewise_Function)
    return +(f1, -1 * f2)
end
function -(f1::Sum_Of_Functions, f2::Sum_Of_Piecewise_Functions)
    return +(f1,-1*f2)
end

function -(f1::Piecewise_Function, f2::Sum_Of_Functions)
    return +(f1, -1*f2)
end
function -(f1::Sum_Of_Piecewise_Functions, f2::Sum_Of_Functions)
    return +(f1,-1*f2)
end

function *(f1::Sum_Of_Functions,f2::Sum_Of_Functions)
    results = Array{Sum_Of_Functions}(undef, length(f1.functions_))
    for i in 1:length(f1.functions_)
        new_funcs = f1.functions_[i] * f2
        results[i] = new_funcs
    end
    return Sum_Of_Functions(results)
end
function *(f1::Sum_Of_Functions, f2::Piecewise_Function)
    f1_funcs = f1.functions_
    if length(f1_funcs) == 0
        return PE_Function(0.0)
    end
    funcs = f1_funcs[1] .* f2.functions_
    if length(f1_funcs) == 1
        return Piecewise_Function(funcs, f2.thresholds_)
    else
        for i in 2:length(f1_funcs)
            funcs = funcs .+ (f1_funcs[i] .* f2.functions_)
        end
        return Piecewise_Function(funcs, f2.thresholds_)
    end
end
function *(f1::Sum_Of_Functions, f2::Sum_Of_Piecewise_Functions)
    return f1 * convert(Piecewise_Function, f2)
end

function *(f1::Piecewise_Function, f2::Sum_Of_Functions)
    return *(f2,f1)
end
function *(f1::Sum_Of_Piecewise_Functions, f2::Sum_Of_Functions)
    return *(f2,f1)
end

# Piecewise Functions

function +(f::Piecewise_Function,number::Float64)
    functions_with_addition = f.functions_ .+ number
    return Piecewise_Function(functions_with_addition, f.thresholds_)
end
function -(f::Piecewise_Function,number::Float64)
    return +(f,-1.0*number)
end
function *(f::Piecewise_Function,number::Float64)
    functions_with_multiplication = f.functions_ .* number
    return Piecewise_Function(functions_with_multiplication, f.thresholds_)
end
function /(f::Piecewise_Function,number::Float64)
    return *(f, 1.0/number)
end
function +(f::Piecewise_Function,number::Int)
    number_as_float = convert(Float64, number)
    return +(f,number_as_float)
end
function -(f::Piecewise_Function,number::Int)
    number_as_float = convert(Float64, number)
    return -(f,number_as_float)
end
function *(f::Piecewise_Function,number::Int)
    number_as_float = convert(Float64, number)
    return *(f,number_as_float)
end
function /(f::Piecewise_Function,number::Int)
    number_as_float = convert(Float64, number)
    return /(f,number_as_float)
end

function +(f1::Piecewise_Function,f2::Piecewise_Function)
    c_f1, c_f2 = create_common_pieces(f1,f2)
    thresholds_ = c_f1.thresholds_
    functions_  = c_f1.functions_ + c_f2.functions_
    return Piecewise_Function(functions_, thresholds_)
end
function +(f1::Piecewise_Function,f2::Sum_Of_Piecewise_Functions)
    return Sum_Of_Piecewise_Functions(vcat(f2.functions_, f1), f2.global_funcs_)
end
function +(f1::Sum_Of_Piecewise_Functions,f2::Piecewise_Function)
    return +(f2,f1)
end

function -(f1::Piecewise_Function,f2::Piecewise_Function)
    return +(f1, -1.0 * f2)
end
function -(f1::Piecewise_Function,f2::Sum_Of_Piecewise_Functions)
    return +(f1,-1*f2)
end
function -(f1::Sum_Of_Piecewise_Functions,f2::Piecewise_Function)
    return +(f1,-1*f2)
end
function *(f1::Piecewise_Function,f2::Piecewise_Function)
    c_f1, c_f2 = create_common_pieces(f1,f2)
    thresholds_ = c_f1.thresholds_
    functions_ = c_f1.functions_ .* c_f2.functions_
    return Piecewise_Function(functions_, thresholds_)
end
function *(f1::Piecewise_Function,f2::Sum_Of_Piecewise_Functions)
    return f1 * convert(Piecewise_Function, f2)
end
function *(f1::Sum_Of_Piecewise_Functions,f2::Piecewise_Function)
    return *(f2,f1)
end

# Sum of Piecewise Functions
function +(f::Sum_Of_Piecewise_Functions,number::Float64)
    return Sum_Of_Piecewise_Functions(f.functions_, f.global_funcs_ + number )
end
function -(f::Sum_Of_Piecewise_Functions,number::Float64)
    return +(f,-1.0*number)
end
function *(f::Sum_Of_Piecewise_Functions,number::Float64)
    return Sum_Of_Piecewise_Functions(number .* f.functions_, number * f.global_funcs_)
end
function /(f::Sum_Of_Piecewise_Functions,number::Float64)
    return *(f, 1.0/number)
end
function +(f::Sum_Of_Piecewise_Functions,number::Int)
    number_as_float = convert(Float64, number)
    return +(f,number_as_float)
end
function -(f::Sum_Of_Piecewise_Functions,number::Int)
    number_as_float = convert(Float64, number)
    return -(f,number_as_float)
end
function *(f::Sum_Of_Piecewise_Functions,number::Int)
    number_as_float = convert(Float64, number)
    return *(f,number_as_float)
end
function /(f::Sum_Of_Piecewise_Functions,number::Int)
    number_as_float = convert(Float64, number)
    return /(f,number_as_float)
end



function +(f1::Sum_Of_Piecewise_Functions,f2::Sum_Of_Piecewise_Functions)
    return Sum_Of_Piecewise_Functions(vcat(f1.functions_, f2.functions_), f1.global_funcs_ + f2.global_funcs_)
end

function -(f1::Sum_Of_Piecewise_Functions,f2::Sum_Of_Piecewise_Functions)
    return +(f1,-1*f2)
end
function *(f1::Sum_Of_Piecewise_Functions,f2::Sum_Of_Piecewise_Functions)
    return convert(Piecewise_Function,f1) * convert(Piecewise_Function, f2)
end





function +(f1::Missing,f2::MultivariateFunction)
    return f1
end
function -(f1::Missing,f2::MultivariateFunction)
    return f1
end
function *(f1::Missing,f2::MultivariateFunction)
    return f1
end
function +(f1::MultivariateFunction,f2::Missing)
    return f2
end
function -(f1::MultivariateFunction,f2::Missing)
    return f2
end

function *(f1::MultivariateFunction,f2::Missing)
    return f2
end



# All

function +(number::Union{Int,Float64}, f::MultivariateFunction)
    return f + number
end
function -(number::Union{Int,Float64}, f::MultivariateFunction)
    return +(number,-1*f)
end
function *(number::Union{Int,Float64}, f::MultivariateFunction)
    return f * number
end
function /(number::Union{Int,Float64}, f::MultivariateFunction)
    error("This package doesn't support dividing by a function.")
end
function ^(number::Union{Int,Float64}, f::MultivariateFunction)
    error("This package doesn't support raising to the power of a function.")
end

###
function integral(f::MultivariateFunction, limits::Dict{Symbol,Tuple{Any,Any}})
    new_limits = convert_to_conformable_dict(limits)
    return integral(f, new_limits)
end
function evaluate(f::MultivariateFunction, coordinates::Dict{Symbol,Any})
    new_coordinates = convert_to_conformable_dict(coordinates)
    return evaluate(f, new_coordinates)
end


###
function convert_to_linearly_rescale_inputs(f::PE_Unit, alpha::Float64, beta::Float64)
    # We want the change the function so that whenever we put in x it is like we put in alpha x + beta.
    beta = beta / alpha
    alpha = 1.0/alpha
    new_base_ = (f.base_ + beta)/alpha
    new_multiplier = alpha^(f.d_)
    new_power_ = f.b_ * alpha
    return new_multiplier, PE_Unit(new_power_, new_base_, f.d_)
end
function convert_to_linearly_rescale_inputs(f::Missing, alpha_beta::Dict{Symbol,Tuple{Float64,Float64}})
    return f
end
function convert_to_linearly_rescale_inputs(f::PE_Function, alpha_beta::Dict{Symbol,Tuple{Float64,Float64}})
    if length(f.units_) == 0
        return f
    end
    mult = f.multiplier_
    final_units = Dict{Symbol,PE_Unit}()
    for dd in setdiff(keys(f.units_), keys(alpha_beta))
        final_units[dd] = f.units_[dd]
    end
    for dim in keys(alpha_beta)
        mm, unit = convert_to_linearly_rescale_inputs(f.units_[dim], alpha_beta[dim][1], alpha_beta[dim][2])
        final_units[dim] = unit
        mult = mult * mm
    end
    return PE_Function(mult, final_units)
end
function convert_to_linearly_rescale_inputs(f::Sum_Of_Functions, alpha_beta::Dict{Symbol,Tuple{Float64,Float64}})
    funcs = convert_to_linearly_rescale_inputs.(f.functions_, Ref(alpha_beta))
    return Sum_Of_Functions(funcs)
end
function convert_to_linearly_rescale_inputs(f::Piecewise_Function, alpha_beta::Dict{Symbol,Tuple{Float64,Float64}})
    new_thresholds = OrderedDict{Symbol,Array{Float64,1}}()
    for k in keys(f.thresholds_)
        alpha = alpha_beta[k][1]
        beta  = alpha_beta[k][2]
        new_thresholds[k] = (f.thresholds_[k] .* alpha) .+ beta
    end
    funcs_ = convert_to_linearly_rescale_inputs.(f.functions_, Ref(alpha_beta))
    return Piecewise_Function(funcs_, new_thresholds)
end

function convert_to_linearly_rescale_inputs(f::MultivariateFunction, alpha::Float64, beta::Float64)
    alpha_beta= Dict{Symbol,Tuple{Float64,Float64}}(default_symbol => (alpha,beta))
    return convert_to_linearly_rescale_inputs(f, alpha_beta)
end
