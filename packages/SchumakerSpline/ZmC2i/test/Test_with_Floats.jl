using SchumakerSpline
tol = 10*eps()

x = collect(range(1, stop=6, length=1000))
y = log.(x) + sqrt.(x)
analytical_first_derivative(e) = 1/e + 0.5 * e^(-0.5)
spline = Schumaker(x,y)
for i in 1:length(x)
    abs(evaluate(spline, x[i]) - y[2]) < tol
end

# Testing First derivative.
first_derivatives = evaluate.(spline, x, 1)
maximum(abs.(first_derivatives .- analytical_first_derivative.(x))) < 0.002

# Testing second derivatives
second_derivatives = evaluate.(spline, x, 2)
maximum(second_derivatives) < tol

# Test higher derivative
higher_derivatives = evaluate.(spline, x, 3)
maximum(second_derivatives) < tol

# Testing Integrals
analytic_integral(lhs,rhs) = rhs*log(rhs) - rhs + (2/3) * rhs^(3/2) - ( lhs*log(lhs) - lhs + (2/3) * lhs^(3/2) )
lhs = 2.0
rhs = 2.5
numerical_integral = evaluate_integral(spline, lhs,rhs)
abs(analytic_integral(lhs,rhs) - numerical_integral) < 0.01

lhs = 1.2
rhs = 4.3
numerical_integral = evaluate_integral(spline, lhs,rhs)
abs(analytic_integral(lhs,rhs) - numerical_integral) < 0.01

lhs = 0.8
rhs = 4.0
numerical_integral = evaluate_integral(spline, lhs,rhs)
abs(analytic_integral(lhs,rhs) - numerical_integral) < 0.03


# Testing creation of a spline with gradient information.
first_derivs = analytical_first_derivative.(x)
spline = Schumaker(x,y; gradients = first_derivs)
first_derivatives = evaluate.(spline, x, 1)
maximum(abs.(first_derivatives .- analytical_first_derivative.(x))) < tol
# Testing creation of a spline with only the gradients on the edges.
first_derivs = analytical_first_derivative.(x)
spline = Schumaker(x,y; left_gradient = first_derivs[1], right_gradient = first_derivs[length(first_derivs)])
first_derivatives = evaluate.(spline, x, 1)
gaps = abs.(first_derivatives .- analytical_first_derivative.(x))
gaps[1] < tol
gaps[length(gaps)] < tol
minimum(gaps[2:(length(gaps)-1)]) > 10* tol

# Testing the other syntax for evaluation.
abs(spline(1.4) - evaluate(spline, 1.4)) < eps()
abs(spline(1.5) - evaluate(spline, 1.5)) < eps()
abs(spline(1.6) - evaluate(spline, 1.6)) < eps()

#=
# should be two random roots and one optima.
x = collect(range(-10, stop=10, length=1000))
function random_function(a::Int)
    vertex = (mod(a * 97, 89)- 45)/5
    y = -(x .- vertex).^2 .+ 1
    sp = Schumaker(x,y)
    return sp, vertex
end
using Optim
sp, vertex = random_function(2)
@time optimafinder = find_optima(sp)
@time optimize(x -> evaluate(sp,x[1]), -5.0, 5.0 )
=#


#= Testing AAD. Not in the full test batch to avoid another dependency
x = collect(range(-10, stop=10, length=1000))
function random_function(a::Int)
    vertex = (mod(a * 97, 89)- 45)/5
    y = -(x .- vertex).^2 .+ 1
    sp = Schumaker(x,y)
    return sp, vertex
end
sp, vertex = random_function(2)
function spl(x::Array{<:Real,1})
    return sum(evaluate.(Ref(sp), x))
end

using ForwardDiff
ForwardDiff.gradient(spl, [2,3])
=#
