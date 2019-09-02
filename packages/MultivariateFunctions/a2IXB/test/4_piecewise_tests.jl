using MultivariateFunctions

tol = 10*eps()

# Testing constructors.
before = PE_Function(0.0,0.0,0.0,1)
first_ = PE_Function(1.0,0.0,0.0,1)
secc = PE_Function(20.0,0.0,0.0,2)
last_  = Sum_Of_Functions([first_, secc])

f1 = Piecewise_Function([before, first_, secc, last_], [-Inf, -1.0,3.0, 10.0])
abs(evaluate(f1, -10.0) - 0.0 ) < tol
abs(evaluate(f1,   1.0) - 1.0 ) < tol
abs(evaluate(f1,   5.0) - 500.0) < tol
abs(evaluate(f1,  20.0) - 20.0 - 20*20*20) < tol
f2 = Piecewise_Function([before, first_, secc, last_], [-0.1, 0.0,2.0, 40.0])

f3 =  Piecewise_Function([before, f1, secc, last_], [-0.1, 0.0,2.0, 40.0])
f4 =  Piecewise_Function([secc, f1, secc, last_], [-2.1, -1.1,4.0, 40.0])

rebadge_test = rebadge(f3, Dict{Symbol,Symbol}(:default => :tester))
pop!(underlying_dimensions(rebadge_test)) == :tester
function test_result(func, eval0, eval5, len = 1)
    val_test0 = abs(evaluate(func, 0.0) - eval0) < 1e-09
    if (!val_test0)
        print("Failed Val Test at 0.0")
    end
    val_test5 = abs(evaluate(func, 5.0) - eval5) < 1e-09
    if (!val_test5)
        print("Failed Val Test at 5.0")
    end
    if typeof(func) == MultivariateFunctions.Piecewise_Function
        len_test = length(func.functions_) == len
        if (!len_test)
            print("Failed Length Test")
        end
        return all([val_test0,val_test5,len_test])
    else
        return all([val_test0,val_test5])
    end
end

# Testing with Ints
test_result(f1 + 5, 5.0, 505.0, 4)
test_result(5 + f1, 5.0, 505.0, 4)
test_result(f1 - 5, -5.0, 495.0, 4)
test_result(5 - f1, 5.0, -495.0, 4)
test_result(f1 * 5, 0.0, 2500.0, 4)
test_result(5 * f1, 0.0, 2500.0, 4)
test_result(f1 / 5, 0.0, 100.0, 4)
# And with Float64s
test_result(f1 + 5.0, 5.0, 505.0, 4)
test_result(5.0 + f1, 5.0, 505.0, 4)
test_result(f1 - 5.0, -5.0, 495.0, 4)
test_result(5.0 - f1, 5.0, -495.0, 4)
test_result(f1 * 5.0, 0.0, 2500.0, 4)
test_result(5.0 * f1, 0.0, 2500.0, 4)
test_result(f1 / 5.0, 0.0, 100.0, 4)


typeof(f4 + Missing()) == Missing
typeof(Missing() + f4) == Missing
typeof(f4 - Missing()) == Missing
typeof(Missing() - f4) == Missing
typeof(f4 * Missing()) == Missing
typeof(Missing() * f4) == Missing

typeof(-1*f4) == MultivariateFunctions.Piecewise_Function

test_result(f1 + first_, 0.0, 505.0, 4)
test_result(first_ + f1, 0.0, 505.0, 4)
test_result(f1 - first_, 0.0, 495.0, 4)
test_result(first_ - f1, 0.0, -495.0, 4)
test_result(f1 * first_, 0.0, 2500.0, 4)
test_result(first_ * f1, 0.0, 2500.0, 4)

test_result(f1 + last_, 0.0, 1005.0, 4)
test_result(last_ + f1, 0.0, 1005.0, 4)
test_result(f1 - last_, 0.0, -5.0, 4)
test_result(last_ - f1, 0.0, 5.0, 4)
test_result(f1 * last_, 0.0, 252500.0, 4)
test_result(last_ * f1, 0.0, 252500.0, 4)

test_result(f1 + f4, 0.0, 1000.0, 8)
test_result(f1 - f4, 0.0, 0.0, 8)
test_result(f1 * f4, 0.0, 250000.0, 8)

# Testing linear rescaling
#test function will be f4
alpha = 0.95
beta = 3.0
X = [-0.3, 0.0, 1.3, 1.5, 4.0, 7.0, 20.0, 40.0, 70.0, 100.0]
X_converted = (alpha .* X) .+ beta
f4_converted = convert_to_linearly_rescale_inputs(f4, alpha, beta)
y = evaluate.(Ref(f4),X)
converted_y = evaluate.(Ref(f4_converted), X_converted)
sum(abs.(y .- converted_y)) < 1e-10
