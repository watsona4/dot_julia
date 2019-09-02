using MultivariateFunctions
using DataFrames
using Dates
using Random
using GLM

tol = 10*eps()

Random.seed!(1)
obs = 1000
X = rand(obs)
y = X .+ rand(Normal(),obs) .+ 7

# Basic use case with 2 degrees
lm1 = fit(LinearModel, hcat(ones(obs), X, X .^ 2), y)
glm_preds = predict(lm1, hcat(ones(obs), X, X .^ 2))
package_approximation, reg1 = create_ols_approximation(y, X, 2; intercept = true, base_x = 0.0)
package_predictions = evaluate.(package_approximation, X)
sum(abs.(glm_preds .- package_predictions)) < 1e-10

# Degree of 1 with no intercept
lm1 = fit(LinearModel, hcat(X), y)
glm_preds = predict(lm1, hcat(X))
package_approximation, reg2 = create_ols_approximation(y, X, 1; intercept = false)
package_predictions = evaluate.(package_approximation, X)
sum(abs.(glm_preds .- package_predictions)) < 1e-10

# Degree of 1 with no intercept
lm1 = fit(LinearModel, hcat(ones(obs)), y)
glm_preds = predict(lm1, hcat(ones(obs)))
package_approximation, reg3 = create_ols_approximation(y, X, 0; intercept = true)
package_predictions = evaluate.(package_approximation, X)
sum(abs.(glm_preds .- package_predictions)) < 1e-10

# With applying a base
Xmin = X .- 5
lm1 = fit(LinearModel, hcat(ones(obs), Xmin, Xmin .^ 2), y)
glm_preds = predict(lm1, hcat(ones(obs), Xmin, Xmin .^ 2))
package_approximation, reg4 = create_ols_approximation(y, X, 2; intercept = true, base_x = 5.0)
package_predictions = evaluate.(package_approximation, X)
sum(abs.(glm_preds .- package_predictions)) < 1e-10

# With x as dates and a base.
X = Array{Date}(undef, obs)
baseDate =  Date(2016, 7, 21)
StartDate = Date(2018, 7, 21)
for i in 1:obs
    X[i] = StartDate +Dates.Day(2* (i-1))
end
XConverted = years_between.(X, baseDate)
lm1 = fit(LinearModel, hcat(ones(obs), XConverted, XConverted .^ 2), y)
glm_preds = predict(lm1, hcat(ones(obs), XConverted, XConverted .^ 2))
package_approximation, reg5 = create_ols_approximation(y, X, 2; intercept = true, base_date = baseDate)
package_predictions = evaluate.(package_approximation, X)
sum(abs.(glm_preds .- package_predictions)) < 1e-10





##### Multivariate Tests

Random.seed!(1992)
nObs = 1000
dd = DataFrame()
dd[:x] = rand( Normal(),nObs) + 0.1 .* rand( Normal(),nObs)
dd[:z] = rand( Normal(),nObs) + 0.1 .* rand( Normal(),nObs)
dd[:w] = (0.5 .* rand( Normal(),nObs)) .+ 0.7.*(dd[:z] .- dd[:x]) + 0.1 .* rand( Normal(),nObs)
dd[:y] = (dd[:x] .*dd[:w] ) .* (dd[:z] .- dd[:w]) .+ dd[:x] + rand( Normal(),nObs)
dd[7,:y] = 1.0

# Creating basic PE_Units
linear    = PE_Unit(0.0,0.0,1)
quadratic = PE_Unit(0.0,0.0,2)
# Creating Model
constant_term = PE_Function(1.0, Dict{Symbol,PE_Unit}())
x_lin         = PE_Function(1.0, Dict{Symbol,PE_Unit}(:x => linear))
z_lin         = PE_Function(1.0, Dict{Symbol,PE_Unit}(:z => linear))
w_lin         = PE_Function(1.0, Dict{Symbol,PE_Unit}(:w => linear))
w_quad        = PE_Function(1.0, Dict{Symbol,PE_Unit}(:w => quadratic))
x_lin_z_quad  = PE_Function(1.0, Dict{Symbol,PE_Unit}([:x, :z] .=> [linear, quadratic]))
model = constant_term + x_lin + z_lin + w_lin + w_quad + x_lin_z_quad
# Regression and testing
mod_1, reg_1 = create_ols_approximation(dd, :y, model)
dd[:predicted_y] = evaluate(mod_1, dd)
sum(abs.(dd[:predicted_y] - reg_1.rr.mu)) < 1e-12

# Now we look at a saturated model.
y = :y
x_variables = [:x,:z]
degree = 2
intercept = true
univariate_dim_name = :default
mod_2, reg_2 = create_saturated_ols_approximation(dd, y, x_variables, degree)
dd[:predicted_y_2] = evaluate(mod_2, dd)
sum(abs.(dd[:predicted_y_2] - reg_2.rr.mu)) < 1e-12

# Now we look at a saturated model.
y = :y
x_variables = [:x,:y,:z]
degree = 3
intercept = true
univariate_dim_name = :default
mod_3, reg_3 = create_saturated_ols_approximation(dd, y, x_variables, degree)
dd[:predicted_y_3] = evaluate(mod_3, dd)
sum(abs.(dd[:predicted_y_3] - reg_3.rr.mu)) < 1e-11

# Now the second model should have higher RSS than the first because it has fewer variables and terms. We can test this:
sum((dd[:predicted_y_2] .- dd[:y]).^2) > sum((dd[:predicted_y] .- dd[:y]).^2)
# The third model should have lower RSS than the first because it has more terms. Testing this:
sum((dd[:predicted_y_3] .- dd[:y]).^2) < sum((dd[:predicted_y] .- dd[:y]).^2)
