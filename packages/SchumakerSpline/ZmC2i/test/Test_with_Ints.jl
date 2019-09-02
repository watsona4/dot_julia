using SchumakerSpline
tol = 10*eps()

x = [1,2,3,4,5,6,7,8,9,10,11,12]
y = log.(x) + sqrt.(x)

typeof(x) == Vector{Int}

spline = Schumaker(x,y)
for i in 1:length(x)
    abs(evaluate(spline, x[i]) - y[2]) < tol
end
# Evaluation with a Float64.
evaluate(spline, 11.5)

# Testing second derivatives
xArray = range(1, stop=6, length=1000)
second_derivatives = evaluate.(spline, xArray,2)
maximum(second_derivatives) < tol

# Testing Integrals
analytic_integral(lhs,rhs) = rhs*log(rhs) - rhs + (2/3) * rhs^(3/2) - ( lhs*log(lhs) - lhs + (2/3) * lhs^(3/2) )
lhs = 2.0
rhs = 2.5
numerical_integral = evaluate_integral(spline, lhs,rhs)
abs(analytic_integral(lhs,rhs) - numerical_integral) < 0.01

lhs = 2.1
rhs = 2.11
numerical_integral = evaluate_integral(spline, lhs,rhs)
abs(analytic_integral(lhs,rhs) - numerical_integral) < 0.01


lhs = 1
rhs = 4
numerical_integral = evaluate_integral(spline, lhs,rhs)
abs(analytic_integral(lhs,rhs) - numerical_integral) < 0.1
