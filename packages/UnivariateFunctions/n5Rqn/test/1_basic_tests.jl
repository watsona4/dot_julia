using UnivariateFunctions
const tol = 10*eps()

# pe functions
function test_pe(a::Float64,b::Float64,base::Float64,d::Int,x::Float64)
    return a * exp(b*(x-base)) * (x-base)^d
end
f1 = PE_Function(1.0, 2.0,3.0, 4)
f1_test_result = test_pe(1.0, 2.0,3.0, 4,5.0)
abs(evaluate(f1, 5.0) - f1_test_result) < tol
f2 = PE_Function(0.0, 2.0,3.0, 4)
f2_test_result = 0.0
abs(evaluate(f2, 5.0) - f2_test_result) < tol
f3 = PE_Function(1.0, 8.0,7.0, 8)
f3_test_result = test_pe(1.0, 8.0,7.0, 8,5.0)
abs(evaluate(f3, 5.0) - f3_test_result) < tol

# Sum of functions
sum0 =  Sum_Of_Functions([])
typeof(sum0) == UnivariateFunctions.Sum_Of_Functions
sum1 =  Sum_Of_Functions([f1])
typeof(sum1) == UnivariateFunctions.Sum_Of_Functions
sum3 =  Sum_Of_Functions([f2,f3])
typeof(sum3) == UnivariateFunctions.Sum_Of_Functions
sum4 =  Sum_Of_Functions([f1,f2,f3])
typeof(sum4) == UnivariateFunctions.Sum_Of_Functions
length(sum4.functions_) == 3
sum5 =  Sum_Of_Functions([sum3, sum4])
typeof(sum5) == UnivariateFunctions.Sum_Of_Functions
length(sum5.functions_) == 4
abs(evaluate(sum1, 5.0) - f1_test_result) < tol
abs(evaluate(sum5, 5.0) - 2*f3_test_result - f1_test_result) < 100* tol
abs(evaluate(sum0, 5.0)) < tol

fl = 8.9
integ = 7

function test_result(func, expected_type, eval_to, len = 1)
    val_test = abs(evaluate(func, 5.0) - eval_to) < 1e-09
    if (!val_test)
        print("Failed Val Test")
    end
    type_test = typeof(func) == expected_type
    if (!type_test)
        print("Failed Type Test")
    end
    if typeof(func) == UnivariateFunctions.Sum_Of_Functions
        len_test = length(func.functions_) == len
        if (!len_test)
            print("Failed Length Test")
        end
        return all([val_test,type_test,len_test])
    else
        return all([val_test,type_test])
    end
end

# pe and Float
test_result(f1 + fl, UnivariateFunctions.Sum_Of_Functions, f1_test_result + fl,2 )
test_result(f1 - fl, UnivariateFunctions.Sum_Of_Functions, f1_test_result - fl,2 )
test_result(f1 * fl, UnivariateFunctions.PE_Function, (f1_test_result) * fl )
test_result(f1 / fl, UnivariateFunctions.PE_Function, (f1_test_result) / fl )
test_result(fl + f1, UnivariateFunctions.Sum_Of_Functions, f1_test_result + fl,2 )
test_result(fl - f1, UnivariateFunctions.Sum_Of_Functions, fl - f1_test_result,2 )
test_result(fl * f1, UnivariateFunctions.PE_Function, (f1_test_result) * fl )
# pe and Int
test_result(f1 + integ, UnivariateFunctions.Sum_Of_Functions, f1_test_result + integ,2 )
test_result(f1 - integ, UnivariateFunctions.Sum_Of_Functions, f1_test_result - integ,2 )
test_result(f1 * integ, UnivariateFunctions.PE_Function, (f1_test_result) * integ )
test_result(f1 / integ, UnivariateFunctions.PE_Function, (f1_test_result) / integ )
test_result(integ + f1, UnivariateFunctions.Sum_Of_Functions, f1_test_result + integ,2 )
test_result(integ - f1, UnivariateFunctions.Sum_Of_Functions, -f1_test_result + integ,2 )
test_result(integ * f1, UnivariateFunctions.PE_Function, (f1_test_result) * integ )


# Sum and Float
test_result(sum4 + fl, UnivariateFunctions.Sum_Of_Functions, f1_test_result + f3_test_result + fl, 3 )
test_result(sum4 - fl, UnivariateFunctions.Sum_Of_Functions, f1_test_result + f3_test_result - fl, 3 )
test_result(sum4 * fl, UnivariateFunctions.Sum_Of_Functions, (f1_test_result + f3_test_result) * fl, 3 )
test_result(sum4 / fl, UnivariateFunctions.Sum_Of_Functions, (f1_test_result + f3_test_result) / fl, 3 )
test_result(fl + sum4, UnivariateFunctions.Sum_Of_Functions, f1_test_result + f3_test_result + fl, 3 )
test_result(fl - sum4, UnivariateFunctions.Sum_Of_Functions, -f1_test_result -f3_test_result + fl, 3 )
test_result(fl * sum4, UnivariateFunctions.Sum_Of_Functions, (f1_test_result + f3_test_result) * fl, 3 )
# Sum and Int
test_result(sum4 + integ, UnivariateFunctions.Sum_Of_Functions, f1_test_result + f3_test_result + integ, 3 )
test_result(sum4 - integ, UnivariateFunctions.Sum_Of_Functions, f1_test_result + f3_test_result - integ, 3 )
test_result(sum4 * integ, UnivariateFunctions.Sum_Of_Functions, (f1_test_result + f3_test_result) * integ, 3 )
test_result(sum4 / integ, UnivariateFunctions.Sum_Of_Functions, (f1_test_result + f3_test_result) / integ, 3 )
test_result(integ + sum4, UnivariateFunctions.Sum_Of_Functions, f1_test_result + f3_test_result + integ, 3 )
test_result(integ - sum4, UnivariateFunctions.Sum_Of_Functions, -f1_test_result -f3_test_result + integ, 3 )
test_result(integ * sum4, UnivariateFunctions.Sum_Of_Functions, (f1_test_result + f3_test_result) * integ, 3 )

### Making sums with addition and subtraction.
evaluate(sum4, 5.0) == evaluate(f1 + f2 + f3, 5.0)
abs(evaluate(sum4, 5.0) - 2*evaluate(f3, 5.0) - evaluate(f1 + f2 - f3, 5.0)) < 0.001

### Changing of base
f1_unchanged = change_base_of_PE_Function(f1, 3.0)
typeof(f1_unchanged) == UnivariateFunctions.PE_Function
abs(f1.base_ - f1_unchanged.base_) < tol

f1_changed = change_base_of_PE_Function(f1, 4.0)
typeof(f1_changed) == UnivariateFunctions.Sum_Of_Functions
abs(f1_changed.functions_[1].base_ - 4.0) < tol
abs(f1_changed.functions_[3].base_ - 4.0) < tol
abs(evaluate(f1_changed, 5.0) - f1_test_result) < 100*tol # Changing bases should not change this.

f1_changed_again = change_base_of_PE_Function(f1, -1.0)
typeof(f1_changed_again) == UnivariateFunctions.Sum_Of_Functions
abs(f1_changed_again.functions_[1].base_ + 1.0) < tol
abs(f1_changed_again.functions_[3].base_ + 1.0) < tol
abs(evaluate(f1_changed_again, 5.0) - f1_test_result) < 1000000*tol # Changing bases should not change this.

f3_changed = change_base_of_PE_Function(f3, 12.0)
typeof(f3_changed) == UnivariateFunctions.Sum_Of_Functions
abs(f3_changed.functions_[1].base_ - 12.0) < tol
abs(f3_changed.functions_[3].base_ - 12.0) < tol
abs(evaluate(f3_changed, 5.0) - f3_test_result) < 100*tol # Changing bases should not change this.

### multiplication of functions
test_result( f1 * f3 , UnivariateFunctions.Sum_Of_Functions, (f1_test_result * f3_test_result), 9 )
test_result( f1 * PE_Function(1.0,2.0,3.0,4) , UnivariateFunctions.PE_Function, (f1_test_result * f1_test_result), 1 )
test_result( f1 * sum4 , UnivariateFunctions.Sum_Of_Functions, f1_test_result * (f1_test_result + f3_test_result), 11 )
test_result( sum4 * f1 , UnivariateFunctions.Sum_Of_Functions, f1_test_result * (f1_test_result + f3_test_result), 11 )
test_result( sum4 * sum4 , UnivariateFunctions.Sum_Of_Functions, (f1_test_result + f3_test_result)^2, 12 )

### Powers pe
test_result( f1 ^ 0 , UnivariateFunctions.PE_Function, 1.0 )
test_result( f1 ^ 1 , UnivariateFunctions.PE_Function, (f1_test_result) )
test_result( f1 ^ 2 , UnivariateFunctions.PE_Function, (f1_test_result * f1_test_result) )
abs(evaluate(f1 ^ 4 ,5.0) - (f1_test_result * f1_test_result * f1_test_result * f1_test_result)) < 1e-03 # This fails normal tol.

### Powers sums
test_result( sum4 ^ 0 , UnivariateFunctions.PE_Function, 1.0 )
test_result( sum4 ^ 1 , UnivariateFunctions.Sum_Of_Functions, (f1_test_result + f3_test_result), 3 )
test_result( sum4 ^ 2 , UnivariateFunctions.Sum_Of_Functions, (f1_test_result + f3_test_result)^2, 12 )
# Higher powers give an underflow problem with base changes.


## Testing Calculus.
pe_const    = PE_Function(2.0,0.0,5.0,0)
pe_lin      = PE_Function(2.0,0.0,5.0,1)
pe_quad     = PE_Function(2.0,0.0,2.0,2)
pe_exp      = PE_Function(2.0,2.0,1.0,0)
pe_exp_quad = PE_Function(2.0,2.0,2.0,2)

# Linear gradient constant
abs(evaluate(derivative(pe_lin),5.0) - evaluate(derivative(pe_lin),1.0) ) < tol
typeof(derivative(pe_lin)) == UnivariateFunctions.Sum_Of_Functions
# This is also linear
abs(evaluate(derivative(derivative(pe_quad)),5.0) -evaluate(derivative(derivative(pe_quad)),9.0) ) < tol
# derivative into a sum of functions
typeof(derivative(pe_exp_quad)) == UnivariateFunctions.Sum_Of_Functions
abs(evaluate(derivative(pe_exp_quad),5.0) - ( 2.0*exp(2.0*(5.0-2.0))*(5.0-2.0)*(2 + 2.0*(5.0-2.0)) ) ) < tol
# Derivaitve of sum
abs(evaluate(derivative(sum4),5.0) - evaluate(derivative(f1),5.0) - evaluate(derivative(f3),5.0) ) < 1e-09

# integral of constant
indefinite_integral(pe_const).d_ == 1
# Integral of quadratic
abs(evaluate_integral(pe_quad,1.0,2.0) - ((2/3)*2^3 - 4*2^2 + 8*2) + ((2/3)*1^3 - 4*1^2 + 8*1)) < tol
# Integral of exponential
abs(evaluate_integral(pe_exp,0.2,3.8) - (exp(2.0*(3.8-1.0)) - exp(2.0*(0.2-1.0))  )) < tol
# Integral of combined.
combined_analytical_integral = PE_Function(1.0,2.0,2.0,2) - PE_Function(1.0,2.0,2.0,1) + PE_Function(0.5,2.0,2.0,0)
abs(evaluate_integral(pe_exp_quad,0.2,3.8) - ( evaluate(combined_analytical_integral, 3.8) - evaluate(combined_analytical_integral, 0.2))) < tol

# left and right integrals
l_int = left_integral(pe_exp_quad, 0.2)
(evaluate(l_int, 3.8) - evaluate_integral(pe_exp_quad,0.2,3.8)) < tol
r_int = right_integral(pe_exp_quad, 3.8)
(evaluate(r_int, 0.2) - evaluate_integral(pe_exp_quad,0.2,3.8)) < tol

## Testing linear rescaling
# For PE_Functions
test_func = PE_Function(0.5,1.2,0.9,2)
inp = 4.0
alpha = 0.435
beta = -1.52
rescaled_input = alpha*inp + beta
converted_test_func = convert_to_linearly_rescale_inputs(test_func, alpha, beta)
abs(evaluate(test_func, inp) - evaluate(converted_test_func, rescaled_input)) < 1e-10
# For undefined.
typeof(convert_to_linearly_rescale_inputs(Undefined_Function(), alpha, beta)) == UnivariateFunctions.Undefined_Function
# SumOfFunctions
sumFunc = test_func + pe_exp_quad + pe_exp
converted_sumFunc = convert_to_linearly_rescale_inputs(sumFunc, alpha, beta)
abs(evaluate(sumFunc, inp) - evaluate(converted_sumFunc, rescaled_input)) < 1e-10
