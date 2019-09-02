using MultivariateFunctions
using Dates
tol = 10*eps()

today = Date(2000,1,1)
pe_func = PE_Function(1.0,2.0,today, 3)
(pe_func.units_[:default].base_ - years_from_global_base(today))   < tol
date_in_2020 = Date(2020,1,1)
pe_func2 = PE_Function(1.0,2.0,date_in_2020, 3)
(pe_func2.units_[:default].base_ - years_from_global_base(date_in_2020))   < tol
abs(evaluate(pe_func, date_in_2020) - evaluate(pe_func, years_from_global_base(date_in_2020)) ) < tol

#Sum of functions
sum_func = Sum_Of_Functions([pe_func, PE_Function(2.0,2.5,today, 3) ])
abs(evaluate(sum_func, date_in_2020) - evaluate(sum_func, years_from_global_base(date_in_2020)) ) < tol

inyear = Date(2001,1,1)
result = integral(pe_func,today,inyear)

left_integral = integral(pe_func, Dict{Symbol,Tuple{Any,Any}}(:default => (today, :default_right)))
abs(evaluate(left_integral, Dict{Symbol,Any}(:default_right => inyear)) - result) < 100 * tol
right_integral = integral(pe_func, Dict{Symbol,Tuple{Any,Any}}(:default => (:default_left, inyear)))
abs(evaluate(right_integral, Dict{Symbol,Any}(:default_left => today)) - result) <  100 * tol
both_integral = integral(pe_func, Dict{Symbol,Tuple{Any,Any}}(:default => (:default_left, :default_right)))
abs(evaluate(both_integral, Dict{Symbol,Any}([:default_left, :default_right] .=> [today, inyear])) - result) <  100 * tol
