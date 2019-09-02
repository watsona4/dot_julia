
"""
    create_saturated_ols_approximation(dd::DataFrame, y::Symbol, x_variables::Array{Symbol,1}, degree::Int; intercept::Bool = true,  bases::Dict{Symbol,Float64} = Dict{Symbol,Float64}(x_variables .=> repeat([0.0],length(x_variables))))
This creates MultivariateFunction from an OLS regression predicting some variable. You input a dataframe and specify what column in that dataframe
is to be predicted by inputting a symbol y. you also put in an array of what x_variables should be used in prediction. A saturated ols model is then calculated up to the specified degree which is returned as a MultivariateFunction.
"""
function create_saturated_ols_approximation(dd::DataFrame, y::Symbol, x_variables::Array{Symbol,1}, degree::Int; intercept::Bool = true,  bases::Dict{Symbol,Float64} = Dict{Symbol,Float64}(x_variables .=> repeat([0.0],length(x_variables))))
    model = Array{PE_Function,1}()
    if intercept
        append!(model, [PE_Function(1.0,Dict{Symbol,PE_Unit}())] )
    end
    if degree > 0
        number_of_variables = length(x_variables)
        linear_set = Array{PE_Function,1}(undef, number_of_variables)
        for i in 1:length(x_variables)
            linear_set[i] = PE_Function(1.0,Dict{Symbol,PE_Unit}(x_variables[i] => PE_Unit(0.0,bases[x_variables[i]],1) ))
        end
        higher_order_terms = Array{Array{PE_Function,1},1}(undef,degree)
        higher_order_terms[1] = linear_set
        for i in 2:degree
            degree_terms = Array{PE_Function,1}()
            for j in 1:number_of_variables
                append!(degree_terms, linear_set[j] .* hcat(higher_order_terms[i-1]))
            end
            higher_order_terms[i] = degree_terms
        end
        append!(model, vcat(higher_order_terms...))
    end
    sum_of_functions = Sum_Of_Functions(model) # We put it through here to remove duplicates.
    return create_ols_approximation(dd, y, sum_of_functions)
end

"""
    create_ols_approximation(dd::DataFrame, y::Symbol, model::MultivariateFunction; allowrankdeficient = true)
    create_ols_approximation(dd::DataFrame, y::Symbol, model::Sum_Of_Functions; allowrankdeficient = true)
    create_ols_approximation(dd::DataFrame, y::Symbol, model::Sum_Of_Piecewise_Functions; allowrankdeficient = true)
This creates MultivariationFunction from an OLS regression predicting some variable. You input a dataframe and specify what column in that dataframe
is to be predicted by inputting a symbol y. You also input the regression model. This is input as a Array{MultivariateFunction,1}.
Each function that is input will be multiplied by the ols coefficient and will return a new function with these coefficients
incorporated.
"""
function create_ols_approximation(dd::DataFrame, y::Symbol, model::Array; allowrankdeficient = true)
    X = hcat(evaluate.(model, Ref(dd))...)
    y = dd[y]
    reg = fit(LinearModel, X,y, allowrankdeficient)
    coefficients = reg.pp.beta0
    updated_model = Sum_Of_Piecewise_Functions(model .* coefficients)
    return updated_model, reg
end
function create_ols_approximation(dd::DataFrame, y::Symbol, model::Sum_Of_Functions)
    return create_ols_approximation(dd, y, model.functions_)
end
function create_ols_approximation(dd::DataFrame, y::Symbol, model::Sum_Of_Piecewise_Functions)
    return create_ols_approximation(dd, y, vcat( model.functions_, model.global_funcs_ ))
end
"""
    create_ols_approximation(y::Array{Float64,1}, x::Array{Float64,1}, degree::Int; intercept::Bool = true, dim_name::Symbol = default_symbol, base_x::Float64 = 0.0)
    create_ols_approximation(y::Array{Float64,1}, x::Array{Date,1}, degree::Int; intercept::Bool = true, dim_name::Symbol = default_symbol, base_date::Date = global_base_date)

This predicts a linear relationship between the y and x arrays and creates a MultivariateFunction containing the approximation function. The degree specifies how many higher
order terms of x should be used (for instance degree 2 implies x and x^2 are both used to predict y).
"""
function create_ols_approximation(y::Array{Float64,1}, x::Array{Float64,1}, degree::Int; intercept::Bool = true, dim_name::Symbol = default_symbol, base_x::Float64 = 0.0)
    dd = DataFrame()
    dd[dim_name] = x
    dd[:y]       = y
    base_dict = Dict{Symbol,Float64}(dim_name => base_x)
    return create_saturated_ols_approximation(dd, :y, [dim_name], degree; intercept = intercept, bases = base_dict)
end

function create_ols_approximation(y::Array{Float64,1}, x::Array{Date,1}, degree::Int; intercept::Bool = true, dim_name::Symbol = default_symbol, base_date::Date = global_base_date)
    return  create_ols_approximation(y, years_from_global_base.(x), degree; intercept = intercept, dim_name = dim_name, base_x = years_from_global_base(base_date))
end
