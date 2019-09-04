using UnivariateFunctions: create_quadratic_spline
using UnivariateFunctions: evaluate, years_between, PE_Function, Sum_Of_Functions
using UnivariateFunctions: change_base_of_PE_Function, derivative, indefinite_integral
using UnivariateFunctions: Piecewise_Function, right_integral, left_integral, evaluate_integral
using UnivariateFunctions: UnivariateFunction, Undefined_Function, years_from_global_base
using Dates

tol = 10*eps()
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

spline = create_quadratic_spline(x,y)
# Test if interpolating
all(abs.(evaluate.(Ref(spline), x) .- y) .< tol)

# Testing third derivatives
third_derivatives = evaluate.(Ref(derivative(derivative(derivative(spline)))), x)
maximum(third_derivatives) < tol

# Testing Integrals
function analytic_integral(lhs,rhs)
    lhs_in_days = years_from_global_base(lhs)
    rhs_in_days = years_from_global_base(rhs)
    return rhs_in_days*log(rhs_in_days) - rhs_in_days + (2/3)*rhs_in_days^(3/2) - (lhs_in_days*log(lhs_in_days) - lhs_in_days)- (2/3)*lhs_in_days^(3/2)
end

lhs = StartDate
rhs = StartDate + Dates.Month(16)
numerical_integral  = evaluate_integral(spline, lhs,rhs)
numerical_integral2 = evaluate(right_integral(spline, lhs), rhs)
numerical_integral3 = evaluate(left_integral(spline, rhs), lhs)

analytical = analytic_integral(lhs,rhs)
abs(  analytical - numerical_integral  ) < 0.0001
abs(  analytical - numerical_integral2  ) < 0.0001
abs(  analytical - numerical_integral3  ) < 0.0001
