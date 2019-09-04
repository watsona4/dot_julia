using UnivariateFunctions
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
package_approximation = UnivariateFunctions.create_ols_approximation(y, X, 0.0, 2, true)
package_predictions = UnivariateFunctions.evaluate.(package_approximation, X)
sum(abs.(glm_preds .- package_predictions)) < 1e-10

# Degree of 1 with no intercept
lm1 = fit(LinearModel, hcat(X), y)
glm_preds = predict(lm1, hcat(X))
package_approximation = UnivariateFunctions.create_ols_approximation(y, X, 0.0, 1, false)
package_predictions = UnivariateFunctions.evaluate.(package_approximation, X)
sum(abs.(glm_preds .- package_predictions)) < 1e-10

# Degree of 1 with no intercept
lm1 = fit(LinearModel, hcat(ones(obs)), y)
glm_preds = predict(lm1, hcat(ones(obs)))
package_approximation = UnivariateFunctions.create_ols_approximation(y, X, 0.0, 0, true)
package_predictions = UnivariateFunctions.evaluate.(package_approximation, X)
sum(abs.(glm_preds .- package_predictions)) < 1e-10

# With applying a base
Xmin = X .- 5
lm1 = fit(LinearModel, hcat(ones(obs), Xmin, Xmin .^ 2), y)
glm_preds = predict(lm1, hcat(ones(obs), Xmin, Xmin .^ 2))
package_approximation = UnivariateFunctions.create_ols_approximation(y, X, 5.0, 2, true)
package_predictions = UnivariateFunctions.evaluate.(package_approximation, X)
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
package_approximation = UnivariateFunctions.create_ols_approximation(y, X, baseDate, 2, true)
package_predictions = UnivariateFunctions.evaluate.(package_approximation, X)
sum(abs.(glm_preds .- package_predictions)) < 1e-10


# Chebyshev approximation
func = sin
nodes  =  12
degree =  8
left   = -2.0
right  =  5.0
approxim = UnivariateFunctions.create_chebyshev_approximation(func, nodes, degree, left, right)
X = convert(Array{Float64,1}, left:0.01:right)
y = func.(X)
y_approx = evaluate.(Ref(approxim), X)
maximum(abs.(y .- y_approx)) < 0.01

func = exp
nodes  =  12
degree =  8
left   =  1.0
right  =  5.0
approxim = UnivariateFunctions.create_chebyshev_approximation(func, nodes, degree, left, right)
X = convert(Array{Float64,1}, left:0.01:right)
y = func.(X)
y_approx = evaluate.(Ref(approxim), X)
maximum(abs.(y .- y_approx)) < 0.01
