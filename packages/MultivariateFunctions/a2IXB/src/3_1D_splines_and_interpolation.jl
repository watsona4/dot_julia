"""
    create_quadratic_spline(x::Array{Date,1},y::Array{Float64,1} ; gradients::Union{missing,Array{Float64,1}} = missing, extrapolation::Schumaker_ExtrapolationSchemes = Curve, left_gradient::Union{Missing,Float64} = missing, right_gradient::Union{Missing,Float64} = missing, dim_name::Symbol = default_symbol)
    create_quadratic_spline(x::Array{Int,1},y::Array{Float64,1} ; gradients::Union{missing,Array{Float64,1}} = missing, extrapolation::Schumaker_ExtrapolationSchemes = Curve, left_gradient::Union{Missing,Float64} = missing, right_gradient::Union{Missing,Float64} = missing, dim_name::Symbol = default_symbol)
    create_quadratic_spline(x::Array{Float64,1},y::Array{Float64,1} ; gradients::Union{missing,Array{Float64,1}} = missing, extrapolation::Schumaker_ExtrapolationSchemes = Curve, left_gradient::Union{Missing,Float64} = missing, right_gradient::Union{Missing,Float64} = missing, dim_name::Symbol = default_symbol)
    create_quadratic_spline(schum::Schumaker; dim_name::Symbol = default_symbol)

Create a quadratic spline. The spline is a Schumaker shape-preserving spline which is taken from the SchumakerSpline.jl package.
"""
function create_quadratic_spline(x::Array{Date,1},y::Array{Float64,1} ; gradients::Union{Missing,Array{Float64,1}} = missing, extrapolation::Schumaker_ExtrapolationSchemes = Curve, left_gradient::Union{Missing,Float64} = missing, right_gradient::Union{Missing,Float64} = missing, dim_name::Symbol = default_symbol)
    x_as_Float64s = years_from_global_base.(x)
    return create_quadratic_spline(x_as_Float64s, y; gradients = gradients, extrapolation = extrapolation, left_gradient = left_gradient, right_gradient = right_gradient, dim_name = dim_name)
end

function create_quadratic_spline(x::Array{DatePeriod,1},y::Array{Float64,1} ; gradients::Union{Missing,Array{Float64,1}} = missing, extrapolation::Schumaker_ExtrapolationSchemes = Curve, left_gradient::Union{Missing,Float64} = missing, right_gradient::Union{Missing,Float64} = missing, dim_name::Symbol = default_symbol)
    x_as_Float64s = period_length.(x)
    return create_quadratic_spline(x_as_Float64s, y; gradients = gradients, extrapolation = extrapolation, left_gradient = left_gradient, right_gradient = right_gradient, dim_name = dim_name)
end

function create_quadratic_spline(x::Array{Int,1},y::Array{Float64,1} ; gradients::Union{Missing,Array{Float64,1}} = missing, extrapolation::Schumaker_ExtrapolationSchemes = Curve, left_gradient::Union{Missing,Float64} = missing, right_gradient::Union{Missing,Float64} = missing, dim_name::Symbol = default_symbol)
    x_as_Float64s = convert.(Float64, x)
    return create_quadratic_spline(x_as_Float64s, y; gradients = gradients, extrapolation = extrapolation, left_gradient = left_gradient, right_gradient = right_gradient, dim_name = dim_name)
end

function create_quadratic_spline(x::Array{Float64,1},y::Array{Float64,1} ; gradients::Union{Missing,Array{Float64,1}} = missing, extrapolation::Schumaker_ExtrapolationSchemes = Curve, left_gradient::Union{Missing,Float64} = missing, right_gradient::Union{Missing,Float64} = missing, dim_name::Symbol = default_symbol)
    schum = Schumaker(x, y; gradients = gradients, extrapolation = extrapolation, left_gradient = left_gradient, right_gradient = right_gradient)
    return create_quadratic_spline(schum; dim_name = dim_name)
end

function create_quadratic_spline(schum::Schumaker; dim_name::Symbol = default_symbol)
    starts_ = schum.IntStarts_
    coefficients = schum.coefficient_matrix_
    number_of_intervals = size(coefficients)[1]
    funcs_ = Array{Sum_Of_Functions,1}(undef, number_of_intervals)
    for i in 1:number_of_intervals
        quadratic = PE_Function(coefficients[i,1], Dict{Symbol,PE_Unit}(dim_name => PE_Unit(0.0, starts_[i], 2)))
        linear    = PE_Function(coefficients[i,2], Dict{Symbol,PE_Unit}(dim_name => PE_Unit(0.0, starts_[i], 1)))
        constant  = PE_Function(coefficients[i,3], Dict{Symbol,PE_Unit}(dim_name => PE_Unit(0.0, 0.0       , 0)))
        polynomial = Sum_Of_Functions([quadratic, linear, constant])
        funcs_[i] = polynomial
    end
    thresholds = OrderedDict{Symbol,Array{Float64,1}}(dim_name => starts_)
    return Piecewise_Function(funcs_, thresholds)
end

"""
    create_constant_interpolation_to_right(x::Array{Date,1},y::Array{Float64,1}; dim_name::Symbol = default_symbol)
    create_constant_interpolation_to_right(x::Array{DatePeriod,1},y::Array{Float64,1}; dim_name::Symbol = default_symbol)
    create_constant_interpolation_to_right(x::Array{Float64,1},y::Array{Float64,1}; dim_name::Symbol = default_symbol)

Create a piecewise constant one-dimensional function which carries values from the left to the right.
"""
function create_constant_interpolation_to_right(x::Array{Date,1},y::Array{Float64,1}; dim_name::Symbol = default_symbol)
    x_Float = years_from_global_base.(x)
    return create_constant_interpolation_to_right(x_Float,y; dim_name = dim_name)
end

function create_constant_interpolation_to_right(x::Array{DatePeriod,1},y::Array{Float64,1}; dim_name::Symbol = default_symbol)
    x_as_Float64s = period_length.(x)
    return create_constant_interpolation_to_right(x_as_Float64s, y; dim_name = dim_name)
end

function create_constant_interpolation_to_right(x::Array{Float64,1},y::Array{Float64,1}; dim_name::Symbol = default_symbol)
    x_ = vcat(-Inf,x)
    y = vcat(y[1], y)
    funcs_ = PE_Function.(y)
    thresholds_ = OrderedDict{Symbol,Array{Float64,1}}(dim_name => x_)
    return Piecewise_Function(funcs_, thresholds_)
end

"""
    create_constant_interpolation_to_left(x::Array{Date,1},y::Array{Float64,1}; dim_name::Symbol = default_symbol)
    create_constant_interpolation_to_left(x::Array{DatePeriod,1},y::Array{Float64,1}; dim_name::Symbol = default_symbol)
    create_constant_interpolation_to_left(x::Array{Float64,1},y::Array{Float64,1}; dim_name::Symbol = default_symbol)

Create a piecewise constant one-dimensional function which carries values from the right to the left.
"""
function create_constant_interpolation_to_left(x::Array{Date,1},y::Array{Float64,1}; dim_name::Symbol = default_symbol)
    x_Float = years_from_global_base.(x)
    return create_constant_interpolation_to_left(x_Float , y ; dim_name = dim_name)
end

function create_constant_interpolation_to_left(x::Array{DatePeriod,1},y::Array{Float64,1}; dim_name::Symbol = default_symbol)
    x_as_Float64s = period_length.(x)
    return create_constant_interpolation_to_left(x_as_Float64s, y; dim_name = dim_name)
end

function create_constant_interpolation_to_left(x::Array{Float64,1},y::Array{Float64,1}; dim_name::Symbol = default_symbol)
    x_ = vcat(-Inf,x[1:(length(x)-1)])
    funcs_ = PE_Function.(y)
    thresholds_ = OrderedDict{Symbol,Array{Float64,1}}(dim_name => x_)
    return Piecewise_Function(funcs_, thresholds_)
end

"""
    create_linear_interpolation(x::Array{Date,1},y::Array{Float64,1}; dim_name::Symbol = default_symbol)
    create_linear_interpolation(x::Array{DatePeriod,1},y::Array{Float64,1}; dim_name::Symbol = default_symbol)
    create_linear_interpolation(x::Array{Float64,1},y::Array{Float64,1}; dim_name::Symbol = default_symbol)

Create a piecewise linear one-dimensional function which interpolates linearly between datapoints.
"""
function create_linear_interpolation(x::Array{Date,1},y::Array{Float64,1}; dim_name::Symbol = default_symbol)
    x_Float = years_from_global_base.(x)
    return create_linear_interpolation(x_Float,y; dim_name = dim_name)
end

function create_linear_interpolation(x::Array{DatePeriod,1},y::Array{Float64,1}; dim_name::Symbol = default_symbol)
    x_as_Float64s = period_length.(x)
    return create_linear_interpolation(x_as_Float64s, y; dim_name = dim_name)
end

function create_linear_interpolation(x::Array{Float64,1},y::Array{Float64,1}; dim_name::Symbol = default_symbol)
    len = length(x)
    if len < 2
        error("Insufficient data to linearly interpolate")
    end
    starts_ = Array{Float64}(undef, len-1)
    funcs_  = Array{Sum_Of_Functions}(undef, len-1)
    coefficient = (y[2] - y[1])/(x[2] - x[1])
    starts_[1] = -Inf
    con = PE_Function(y[1])
    lin = PE_Function(coefficient,Dict{Symbol,PE_Unit}(dim_name => PE_Unit(0.0, x[1], 1)))
    funcs_[1]  = con + lin
    if len > 2
        for i in 2:(len-1)
            starts_[i] = x[i]
            coefficient = (y[i+1] - y[i])/(x[i+1] - x[i])
            con = PE_Function(y[i])
            lin = PE_Function(coefficient,Dict{Symbol,PE_Unit}(dim_name => PE_Unit(0.0, x[i], 1)))
            funcs_[i]  = con + lin
        end
    end
    thresholds_ = OrderedDict{Symbol,Array{Float64,1}}(dim_name => starts_)
    return Piecewise_Function(funcs_, thresholds_)
end
