# UnivariateFunctions.jl

| Build | Coverage |
|-------|----------|
| [![Build Status](https://travis-ci.com/s-baumann/UnivariateFunctions.jl.svg?branch=master)](https://travis-ci.org/s-baumann/UnivariateFunctions.jl) | [![Coverage Status](https://coveralls.io/repos/github/s-baumann/UnivariateFunctions.jl/badge.svg?branch=master)](https://coveralls.io/github/s-baumann/UnivariateFunctions.jl?branch=master)

This implements single algebra and evaluation on simple univariate functions.
There are a few ways in which it can be used.
* UnivariateFunctions can be used in the creation of splines. This has the added
    advantage that a spline implemented as a UnivariateFunction can be manipulated
    easily. It can be differentiated and then added to another function, etc.
* Any continuous interpolation scheme can be done with the added benefit that derivatives/integrals/products etc can be found analytically.
* Basic approximation schemes like OLS regression and chebyshev polynomials can be done with the added benefit that derivatives/integrals/products etc can be found analytically.

Development on this package is discontinued other than bug fixes as everything is generalised in [MultivariateFunctions.jl](https://github.com/s-baumann/MultivariateFunctions.jl). This provides a superset of the functionality of UnivariateFunctions.jl.

## Structs

There are four main UnivariateFunction structs that are part of this package. These are:
* Undefined_Function - An undefined function behaves similarly to "missing" in Julia. Whenever anything is added/multiplied/etc with an undefined function the result is undefined. The integral and derivative of an undefined function is undefined. If an undefined function is evaluated it will return a missing.
* PE_Function - This is the basic function type. It has a form of $a \exp(b(x-base_)) (x-base)^d$.
* Sum_Of_Functions - This is an array of PE_Functions. Note that by adding PE_Functions we can replicate any given polynomial. Hence from Weierstrass' approximation theorem we can approximate any continuous function on a bounded domain to any desired level of accuracy (whether this is practical in numerical computing depends on the function being approximated).
* Piecewise_Function - This defines a different UnivariateFunction for each part of the x domain.

It is possible to perform any additions, subtractions, multiplications between any two UnivariateFunctions and between Ints/Floats and any UnivariateFunction. No division is allowed and it is not possible to raise a UnivariateFunction to a negative power. This is to ensure that all univariatefunctions are analytically integrable and differentiable. This may change in future releases.

## Major limitations
* It is not possible to divide by univariate functions or raise them by a negative power.
* When multiplying pe_functions with different base dates there is often an issue of very high or very low numbers that go outside machine precision. If one were trying to change a PE_Function from base 2010 to 50, this would not generally be possible. This is because to change $a exp(x-2020)$ to $q exp(x - 50)$ we need to premultiply the first expression by $exp(-1950)$ which is a tiny number. In these cases it is better to do the algebra on paper and rewriting the code accordingly as often base changes cancel out on paper. It is also good to change bases as rarely as possible. If different univariate functions use different bases then there is a need to base change when multiplying them which can result in errors. Note that if base changes are segment in the x domain by means of a piecewise function then they should never interact meaning it is ok to use different bases here.
* There is no support for finding optima, roots, fixedpoints etc. If anyone has an idea of how to do it efficiently then please let me know.
* There is no support for finding a function representing the upper/lower envelope of multiple functions. If anyone has an idea of how to do it efficiently then please let me know.

## Interpolation and Splines
So far this package support the following interpolation schemes:
* Constant interpolation from the left to the right. Such a Piecewise_Function spline can be constructed by the create_constant_interpolation_to_right method.
* Constant interpolation from the right to the left. Such a Piecewise_Function spline can be constructed by the create_constant_interpolation_to_left method.
* Linear interpolation. Such a Piecewise_Function spline can be constructed by the create_linear_interpolation method.
It also supports the following spline (which can also be used for interpolation)
* Schumaker shape preserving spline - Such a Piecewise_Function spline can be constructed by the create_quadratic_spline method.

## Approximation and regression
So for this package supports the creation of the following approximation schemes:
* OLS regression. The create_ols_approximation function can create a UnivariateFunction approximating a linear relationship. The degree input to this function can be used to specify the number of higher powers of x to be used in approximating y. For instance if the degree is two then y will be approximated as a linear combination of x and x^2 as well as an intercept (if the intercept boolean is true).
* Chebyshev polynomials - This will approximate a function using the Chebyshev basis functions. This approximation function can then be integreted which accomplished Chebyshev–Gauss quadrature.



## Date Handling

* All base dates are immediately converted to floats and are not otherwise saved. Thus there is no difference between a PE_Function created with a base as a float and one created with the matching date. This is done to simplify the code. All date conversions is done by finding the year fractions between the date and the global base date of Date(2000,1,1). This particular global base date should not affect anything as long as it is consistent. It is relatively trivial to change it (in the date_conversions.jl file) and recompile however if desired.

# Examples

## For basic algebra:

Consider we have a two functions f and g and want to add them, multiply them by some other function h, then square it and finally integrate the result between 2.0 and 2.8. This can be done analytically with UnivariateFunctions:
```
f = PE_Function(1.0, 2.0, 4.0, 5)
g = PE_Function(1.3, 2.0, 4.3, 2)
h = PE_Function(5.0, 2.2, 1.0,0)
result_of_operations = (h*(f+g))^2
evaluate_integral(result_of_operations, 2.0, 2.8)
```

## For data interpolation

Suppose we have want to approximate some function with some sampled points. First to generate some points
```
using UnivariateFunctions
const global_base_date = Date(2000,1,1)
StartDate = Date(2018, 7, 21)
x = Array{Date}(undef, 1000)
for i in 1:1000
    x[i] = StartDate +Dates.Day(2* (i-1))
end
function ff(x::Date)
    days_between = years_from_global_base(x)
    return log(days_between) + sqrt(days_between)
end
y = ff.(x)
```
Now we can generate a UnivariateFunction that can be used to easily interpolate from the sampled points:
```
func = create_quadratic_spline(x,y)
```
And we can evaluate from this function and integrate it and differentiate it in the normal way:
```
evaluate(func, Date(2020,1,1))
evaluate.(Ref(func), [Date(2020,1,1), Date(2021,1,2)])
evaluate(derivative(func), Date(2021,1,2))
evaluate_integral(func, Date(2020,1,1), Date(2021,1,2))
```
If we had wanted to interpolate instead with a constant method(from left or from right) or by linearly
interpolating then we could have just generated func with a different method:
create_constant_interpolation_to_left,
create_constant_interpolation_to_right or
create_linear_interpolation.

If we have lots of data that we want to summarise with OLS
```
# Generating example data
using Random
Random.seed!(1)
obs = 1000
X = rand(obs)
y = X .+ rand(Normal(),obs) .+ 7
# And now making an approximation function
approxFunction = create_ols_approximation(y, X, 0.0, 2, true)
```
And if we want to approximate the sin function in the [2.3, 5.6] bound with 7 polynomial terms and 20 approximation nodes:
```
chebyshevs = create_chebyshev_approximation(sin, 20, 7, 2.3, 5.6)
```
We can integrate the above term in the normal way to achieve Gauss-Chebyshev quadrature:
```
evaluate_integral(chebyshevs, 2.3, 5.6)
```
