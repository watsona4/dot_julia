using MultivariateFunctions
using DataFrames
using Dates
using Random
using Distributions
tol = 1e-14
fun1 = PE_Function(1.0,1.0,1.0,1)
fun2 = PE_Function(1.2,1.0,1.0,1)
fun3 = PE_Function(1.5,1.0,2.0,3)
fun4 = PE_Function(3.0,1.0,3.0,2)
fun5 = PE_Function(0.0,2.0,1.0,1)
fun6 = PE_Function(2.0,0.0,1.0,1)
fun7 = PE_Function(3.0,0.0,2.0,4)
fun8 = PE_Function(3.0,0.0,2.0,2)
fun9 = PE_Function(3.0,0.0,Date(2015,1,1),4)
fun10 = PE_Function(3.0,0.0,Date(2016,1,1),2)


limits = Dict{Symbol, Tuple{Union{Symbol,Float64},Union{Symbol,Float64}}}( [:x,:y] .=> [(:x_left, 5.6), (:y_left, :y_right) ]   )


mfun1 = PE_Function(1.8, Dict([:x, :y, :z] .=> [PE_Unit(1.0,1.0,1), PE_Unit(1.0,1.0,1), PE_Unit(1.0,2.0,3)]))
abs(mfun1.multiplier_ - 1.2*1.5) < 1e-10
mfun2 = PE_Function(4.5, Dict([:x, :y] .=> [PE_Unit(1.0,2.0,3), PE_Unit(1.0,3.0,2)]))
mfun3 = PE_Function(3.0, Dict([:z, :y] .=> [ PE_Unit(1.0,3.0,2), PE_Unit(1.0,1.0,1)]))
mfun4 = PE_Function(6.0, Dict([:x, :y] .=> [PE_Unit(0.0,1.0,1), PE_Unit(0.0,2.0,4)]))
mfun5 = PE_Function(6.0, Dict([:x, :z] .=> [PE_Unit(0.0,1.0,1), PE_Unit(0.0,2.0,2)]))
mfun6 = PE_Function(18.0, Dict([:x, :y, :z] .=> [PE_Unit(0.0,Date(2015,1,1),4), PE_Unit(0.0,1.0,1), PE_Unit(0.0,Date(2016,1,1),2)]))

mSumFunction1 = Sum_Of_Functions([mfun1, mfun2])
mSumFunction2 = Sum_Of_Functions([mSumFunction1, mfun3])
mSumFunction3 = Sum_Of_Functions([mSumFunction1, mSumFunction2])

coordinates = Dict([:x, :y, :z] .=> [0.5, 2.0, 3.0])

# Conversion
typeof(convert(MultivariateFunctions.Sum_Of_Functions, mfun1)) == MultivariateFunctions.Sum_Of_Functions

function test_result(func, eval_to)
    return abs(evaluate(func, coordinates) - eval_to) < 1e-05
end



# Testing numerical results
mfun1_value = evaluate(fun1, coordinates[:x]) * evaluate(fun2, coordinates[:y]) * evaluate(fun3, coordinates[:z])
test_result(mfun1, mfun1_value)
mfun2_value = evaluate(fun3, coordinates[:x]) * evaluate(fun4, coordinates[:y])
test_result(mfun2, mfun2_value)
test_result(mSumFunction1, mfun1_value + mfun2_value)
mfun3_value = evaluate(fun4, coordinates[:z]) * evaluate(fun1, coordinates[:y])
test_result(mSumFunction3, 2* mfun1_value + 2*mfun2_value + mfun3_value)
mfun6_value = evaluate(fun4, coordinates[:z]) * evaluate(fun1, coordinates[:y])
# Testing partial evaluations
mfun1_partiallyevaluated = evaluate(mfun1, Dict{Symbol,Float64}([:x, :y] .=> [2.0,2.0]))
abs(mfun1_partiallyevaluated.multiplier_ - 13.30030097807517) < tol
underlying_dimensions(mfun1_partiallyevaluated) == Set(Symbol[:z])

# Testing partial evaluations of Sum_Of_Functions
mSumFunction1_partiallyevaluated = evaluate(mSumFunction1, Dict{Symbol,Float64}([:x, :y] .=> [3.0,2.0]))
abs(mSumFunction1_partiallyevaluated.functions_[1].multiplier_ - 72.3079329234756) < tol
underlying_dimensions(mSumFunction1_partiallyevaluated) == Set(Symbol[:z])

# Additions and subtractions
test_result( ((7 - (5.0 - mfun1))  + 5.0) + 7        , 14 + mfun1_value                )
test_result( ((7 - (5.0 - mSumFunction1))  + 5.0) + 7, 14 +  mfun1_value + mfun2_value )
# multiplications
test_result( (5 * mfun1) * 7.0        , 35* mfun1_value                  )
test_result( (5 * mSumFunction1) * 7.0, 35*  (mfun1_value + mfun2_value) )
# Divisions
test_result( (mfun1/2) / 3.0       ,  mfun1_value/6                  )
test_result( (mSumFunction1/2) /3.0, (mfun1_value + mfun2_value)/6 )
# powers
test_result( mfun1^0, 1.0)
test_result( mSumFunction1^0, 1)
test_result( mfun1^1, mfun1_value)
test_result( mSumFunction1^1, (mfun1_value + mfun2_value))
test_result( mfun1^2, mfun1_value^2)
test_result( mSumFunction1^2, (mfun1_value + mfun2_value)^2)
# multiplying functions
test_result( mfun1 * mfun2, mfun1_value * mfun2_value)
# Using Dates
dateCoordinates = Dict([:x, :y, :z] .=> [Date(2017,1,1), 2, 17.0])
dateCoordinates2 = Dict([:x, :y, :z] .=> [years_from_global_base(dateCoordinates[:x]), 2.0, 17.0])
abs(evaluate(mfun6, dateCoordinates) - evaluate(mfun6, dateCoordinates2) ) < 1e-14

# Derivatives
test_result(derivative(mfun4, Dict{Symbol,Int}(:x => 2)) , 0.0)
test_result(derivative(mfun4, Dict{Symbol,Int}(:y => 4)), 24 * 6 * (-0.5) )
test_result(derivative(mfun5, Dict([:x, :z] .=> [1,1])), 12 * (3-2)^1 )
# Integration
int_limits = Dict{Symbol,Tuple{Float64,Float64}}([:x, :y] .=> [(2.0,2.5), (3.0,3.5)])
abs(integral(mfun4, int_limits) - 0.6 * ((int_limits[:x][2] - 1)^2 - (int_limits[:x][1]-1)^2)*((int_limits[:y][2]-2)^5 - (int_limits[:y][1]-2)^5)) < tol
abs(integral(Sum_Of_Functions([mfun4, mfun4]), int_limits) - 1.2 * ((int_limits[:x][2] - 1)^2 - (int_limits[:x][1]-1)^2)*((int_limits[:y][2]-2)^5 - (int_limits[:y][1]-2)^5)) < tol

# Integration of constant function
constant_func = PE_Function(5.0)
abs(integral(constant_func, int_limits) - 5.0/4 ) < tol


## Dataframe evaluations
Random.seed!(1992)
nObs = 100
dd = DataFrame()
dd[:x] = rand( Normal(),nObs) + 0.1 .* rand( Normal(),nObs)
dd[:z] = rand( Normal(),nObs) + 0.1 .* rand( Normal(),nObs)
dd[:y] = (dd[:x] ) .* (dd[:z]) .+ dd[:x] + rand( Normal(),nObs)
sum(abs.(evaluate(mfun1, dd) + evaluate(mfun2, dd) - evaluate(mSumFunction1, dd))) < tol
