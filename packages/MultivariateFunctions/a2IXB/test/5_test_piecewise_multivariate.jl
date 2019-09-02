using MultivariateFunctions
using DataStructures: OrderedDict
tol = 1e-15
fun1 = PE_Unit(1.0,1.0,1)
fun2 = PE_Unit(1.0,1.0,1)
fun3 = PE_Unit(1.0,2.0,3)
fun4 = PE_Unit(1.0,3.0,2)
fun6 = PE_Unit(0.0,1.0,1)
fun7 = PE_Unit(0.0,2.0,4)
fun8 = PE_Unit(0.0,2.0,2)

mfun1 = PE_Function(1.8, Dict(Symbol.(["x", "y", "z"]) .=> [fun1, fun2, fun3]))
abs(mfun1.multiplier_ - 1.2*1.5) < 1e-10
mfun2 = PE_Function(4.5, Dict(Symbol.(["x", "y"]) .=> [fun3, fun4]))
mfun3 = PE_Function(3.0, Dict(Symbol.(["z", "y"]) .=> [fun4, fun1]))
mfun4 = PE_Function(6.0, Dict(Symbol.(["x", "y"]) .=> [fun6, fun7]))
mfun5 = PE_Function(6.0, Dict(Symbol.(["x", "z"]) .=> [fun6, fun8]))

msum = mfun5 + mfun4

func_array = Array{Union{Sum_Of_Functions,Missing},3}(undef,3,2,2)
func_array[1,1,1] = Sum_Of_Functions(mfun1)
func_array[1,1,2] = Sum_Of_Functions(mfun2)
func_array[1,2,1] = mfun2 + mfun1
func_array[1,2,2] = mfun2 + mfun4
func_array[2,1,1] = Sum_Of_Functions(2*mfun1)
func_array[2,1,2] = mfun1 + mfun5
func_array[2,2,1] = mfun1 + mfun5
func_array[2,2,2] = mfun2 + mfun1 + mfun5
func_array[3,:,:] .= Missing()

thresholds_ = OrderedDict{Symbol,Array{Float64,1}}([:x, :y, :z] .=> [[0.0, 0.5, 1.0], [-5.0, -1.0], [0.0, 5.0]])

pw_func = Piecewise_Function(func_array, thresholds_)

# Testing zeroing.
coordinates = Dict{Symbol,Float64}([:w, :x, :y, :z] .=> [1.4, 0.4, 2.0, 3.0])
hypercube =  Dict{Symbol,Tuple{Float64,Float64}}([:x, :z] .=> [(0.5,Inf), (1.0,6.0)])
zero_outside_hypercube = Piecewise_Function(pw_func, hypercube, true)
abs(evaluate(pw_func, coordinates) - evaluate(zero_outside_hypercube, coordinates)) > 5.0
coordinates_in_cube = Dict{Symbol,Float64}([:w, :x, :y, :z] .=> [1.4, 0.7, 2.0, 3.0])
abs(evaluate(pw_func, coordinates_in_cube) - evaluate(zero_outside_hypercube, coordinates_in_cube)) < tol

# creating a pw with a pw
functions_ = Array{Any,2}(undef,3,2)
functions_[1,1] = Sum_Of_Functions(mfun1)
functions_[1,2] = Sum_Of_Functions(3.0*mfun2)
functions_[2,1] = pw_func
functions_[2,2] = mfun2 + mfun4
functions_[3,1] = pw_func + 1.0
functions_[3,2] = mfun2 + mfun5
thresholds_ = OrderedDict{Symbol,Array{Float64,1}}([:x, :y] .=> [[0.0, 0.6, 1.0], [-5.0, -1.0]])
pw_func2 = Piecewise_Function(functions_, thresholds_)
coords_21 = Dict{Symbol,Float64}([:w, :x, :y, :z] .=> [1.4, 0.7, -3.0, 3.0])
coords_22 = Dict{Symbol,Float64}([:w, :x, :y, :z] .=> [1.4, 0.7, 0.0, 3.0])
abs(evaluate(pw_func, coords_21) - evaluate(pw_func2, coords_21)) < tol
abs(evaluate(pw_func, coords_22) - evaluate(pw_func2, coords_22)) > 1.0

###############################################################################
coordinates = Dict(Symbol.(["w","x", "y", "z"]) .=> [1.4, 0.5, 2.0, 3.0])
function test_result(func, eval_to, len = 1)
    val_test = abs(evaluate(func, coordinates) - eval_to) < 1e-05
    if (!val_test)
        println("Failed Val Test")
    end
    len_test = length(func.functions_) == len
    if (!len_test)
        println(string("Failed length Test, Length is ", length(func.functions_)))
    end
    return all([val_test,len_test])
end
ismissing(evaluate(pw_func, Dict(Symbol.(["w","x", "y", "z"]) .=> [-Inf, -Inf, -Inf, -Inf])))
test_result(pw_func, evaluate( mfun1 + mfun5, coordinates), 12)
deriv = Dict{Symbol,Int}(Symbol.(["x", "z"]) .=> [2,1])
abs(evaluate(derivative(pw_func, deriv), coordinates) - evaluate(derivative(mfun1 + mfun5, deriv), coordinates)) < tol

# Integration of piecewise function
integration_limits = Dict{Symbol,Tuple{Float64,Float64}}([:x, :y, :z] .=> [(0.25,0.75),(-4.0,-1.0),(0.0,3.0)])
integral_of_each_piece = integral(Sum_Of_Functions(mfun1) ,Dict{Symbol,Tuple{Float64,Float64}}([:x, :y, :z] .=> [(0.25,0.5),(-4.0,-1.0),(0.0,3.0)]))
integral_of_each_piece = integral_of_each_piece + integral(Sum_Of_Functions(2*mfun1) ,Dict{Symbol,Tuple{Float64,Float64}}([:x, :y, :z] .=> [(0.5,0.75),(-4.0,-1.0),(0.0,3.0)]))
integral_of_piecewise = integral(pw_func, integration_limits)
abs(integral_of_each_piece - integral_of_piecewise)  < tol
# Integration of piecewise function
integration_limits = Dict{Symbol,Tuple{Float64,Float64}}([:x, :y, :z] .=> [(0.25,0.75),(-4.0,-1.0),(0.0,8.0)])
integral_of_each_piece = integral(Sum_Of_Functions(mfun1) ,Dict{Symbol,Tuple{Float64,Float64}}([:x, :y, :z] .=> [(0.25,0.5),(-4.0,-1.0),(0.0,5.0)]))
integral_of_each_piece = integral_of_each_piece + integral(Sum_Of_Functions(2*mfun1) ,Dict{Symbol,Tuple{Float64,Float64}}([:x, :y, :z] .=> [(0.5,0.75),(-4.0,-1.0),(0.0,5.0)]))
integral_of_each_piece = integral_of_each_piece + integral(Sum_Of_Functions(mfun2) ,Dict{Symbol,Tuple{Float64,Float64}}([:x, :y, :z] .=> [(0.25,0.5),(-4.0,-1.0),(5.0,8.0)]))
integral_of_each_piece = integral_of_each_piece + integral(mfun1 + mfun5 ,Dict{Symbol,Tuple{Float64,Float64}}([:x, :y, :z] .=> [(0.5,0.75),(-4.0,-1.0),(5.0,8.0)]))
integral_of_piecewise = integral(pw_func, integration_limits)
abs(integral_of_each_piece - integral_of_piecewise)  < tol

# test algebra between Piecewise_Functions and PE_Functions.
test_result(pw_func + mfun4, evaluate( mfun1 + mfun5, coordinates) + evaluate(mfun4, coordinates), 12)
test_result(pw_func - mfun4, evaluate( mfun1 + mfun5, coordinates) - evaluate(mfun4, coordinates), 12)
test_result(pw_func * mfun4, evaluate( mfun1 + mfun5, coordinates) * evaluate(mfun4, coordinates), 12)
test_result(mfun4 + pw_func, evaluate( mfun1 + mfun5, coordinates) + evaluate(mfun4, coordinates), 12)
test_result(mfun4 - pw_func,  evaluate(mfun4, coordinates) - evaluate( mfun1 + mfun5, coordinates), 12)
test_result(mfun4 * pw_func, evaluate( mfun1 + mfun5, coordinates) * evaluate(mfun4, coordinates), 12)
# Multivariate Sum of Functions
test_result(pw_func + msum, evaluate( mfun1 + mfun5, coordinates) + evaluate(msum, coordinates), 12)
test_result(pw_func - msum, evaluate( mfun1 + mfun5, coordinates) - evaluate(msum, coordinates), 12)
test_result(pw_func * msum, evaluate( mfun1 + mfun5, coordinates) * evaluate(msum, coordinates), 12)
test_result(msum + pw_func, evaluate( mfun1 + mfun5, coordinates) + evaluate(msum, coordinates), 12)
test_result(msum - pw_func,  evaluate(msum, coordinates) - evaluate( mfun1 + mfun5, coordinates), 12)
test_result(msum * pw_func, evaluate( mfun1 + mfun5, coordinates) * evaluate(msum, coordinates), 12)


# Algebra between different Multivariate_Piecewise_Functions
func_array = Array{Union{Missing,Sum_Of_Functions},3}(undef,3,2,2)
func_array[1,1,1] = Sum_Of_Functions(mfun5)
func_array[1,1,2] = Sum_Of_Functions(mfun3)
func_array[1,2,1] = mfun3 + mfun1
func_array[1,2,2] = Sum_Of_Functions(2*mfun1)
func_array[2,1,1] = mfun2 + mfun4
func_array[2,1,2] = mfun1 + mfun5
func_array[2,2,1] = mfun5 + mfun5
func_array[2,2,2] = mfun4 + mfun1 + mfun5
func_array[3,:,:] .= mfun4 + mfun5 + mfun1

pw_func2 = Piecewise_Function(func_array, OrderedDict([:x, :y, :w] .=> [[0.2, 0.5, 1.0], [-4.0, -1.0], [0.0, 5.0]]))
test_result(pw_func + pw_func2, evaluate( (mfun1 + mfun5) + (mfun5 + mfun5), coordinates), 3*4*2*2)
test_result(pw_func - pw_func2, evaluate( (mfun1 + mfun5) - (mfun5 + mfun5), coordinates), 3*4*2*2)
test_result(pw_func * pw_func2, evaluate( (mfun1 + mfun5) * (mfun5 + mfun5), coordinates), 3*4*2*2)


## Testing of Sum_Of_Piecewise_Functions
spwf = Sum_Of_Piecewise_Functions([pw_func, pw_func2])
abs(evaluate(spwf, coordinates) - evaluate(pw_func, coordinates) - evaluate(pw_func2, coordinates) ) < tol
underlying_dimensions(spwf) == union(underlying_dimensions(pw_func), underlying_dimensions(pw_func2))
converted = convert(Piecewise_Function, spwf)
added = (pw_func + pw_func2)
converted.functions_[2,2,2,1].functions_[1] ≂ added.functions_[2,2,2,1].functions_[1]

test_result( (spwf + 1) - 1, evaluate( spwf, coordinates), 2)
test_result( 1 + (1 - spwf ), 2 - evaluate( spwf, coordinates), 2)
test_result( (spwf + 1.0) - 1.0, evaluate( spwf, coordinates), 2)
test_result( 1.0 + (1.0 - spwf ), 2 - evaluate( spwf, coordinates), 2)
test_result( (3 *spwf * 2) / 4, evaluate( spwf, coordinates) * 1.5, 2)
test_result( (3.0 *spwf * 2.0) / 4.0, evaluate( spwf, coordinates) * 1.5, 2)
test_result( (spwf^2), evaluate( spwf, coordinates)^2, 48)
deriv_spec = Dict{Symbol,Int}(:x => 1)
abs(evaluate(derivative(spwf, deriv_spec), coordinates) -  evaluate(derivative(pw_func,deriv_spec), coordinates) - evaluate(derivative(pw_func2, deriv_spec), coordinates)) < 1e-09
integration_limits = Dict{Symbol,Tuple{Float64,Float64}}([:x, :y, :w, :z] .=> [(0.25,0.75),(-4.0,-1.0),(0.0,8.0), (0.5, 2.4)])
evaluate(integral(spwf, integration_limits) -  integral(pw_func,integration_limits) - integral(pw_func2, integration_limits), coordinates)     < 1e-09
