# # Installation

# Installing the package is trivial as it is registered as a Julia package.
using Pkg
Pkg.add("ApproximateComputations")
Pkg.update()

# To include the library in our project we add it with `using`

using ApproximateComputations

# # Approximation Type

# The `Approximation` type is a wrapper parent type to be used to enclose data which has been returned 
# from a non-accurate source. This type can be extended to enclose extra information for debugging or
# improving a program by allowing more complex functional behaviour based on type and level of
# approximation

# Constructing an `Approximation` is trival
param = 5.0
approx_param = Approximation(param)

# The value stored in `approx_param` is the same as param, it is simply wrapped to allow for specialised
# behaviour. To extract the value and check this we use `Get(x)`
contained_value = Get(approx_param)

# # Approximate Fit Functions

# 1) Generate new functions which approximate 'sin' in the range 0.001 to pi/2 
# with 5000 samples set with the `sampleCount` option and a request for a table of the results with
# the `retDataFrame` option.
using ApproximateComputations
newFunctionsAndInformation, tableOfResults = GenerateAllApproximationFunctions(sin, 0.001, 1.57, sampleCount=5000, retDataFrame=true);

# When we display the results you will see the different precision, order and methods of generation.
# By default only a limited set are used. If you look into the documentation you will see the flags
# for different types of curve generation.
tableOfResults

# 2) Filter the generated functions to select the fastest executing function within our error constraint:
a = GetFastestAcceptable(newFunctionsAndInformation, meanErrorLimit=0.00000001)
println(GetFunctionName(a))  # -> returns sin_PolyLet9_Float64bit


# 3) Store the function for use:
approxsin = a.generatedFunction

# 4) Compare to accurate function:
approxResult = approxsin(1.0) # -> Approximation{Float64}(0.8414709848311571)
realResult = sin(1.0)   # -> {Float64} (0.8414709848078965)

# You will notice that the returned type of the generated function is of the `Approximation{T}` type.
# this is to ensure that any use of these functions in an application is with explicit understanding
# of the programmer when they extract the value to put it back into "non-approximate"-space.

# # Approximate Memoisation
# In this package we provide wrapper functions to allow the implementation of approximate memoisation
# using either trending batched memoisation or approximate hashing memoisation

# Memoisation is a common technique to store the return the values of an expensive 
# function so that multiple calls do not result in multiple expensive runs of the function.
# Memoisation can be ineffecient for numerical applications with slight variations of input
# where each input will result a different value being saved even when they are nearly identical.
# In an application which is error resilient this is wasted memory as a single value could be 
# stored for all inputs which are close or result in a similar answer.
                    
# As most memoisation is based on a hashtable we are able to construct an approximate memoisation 
# by allowing for the custom of custom hash functions which result in clashes when any two inputs
# are similar enough to be within our error threshold.

# With this setup, a hash function which causes a clash for any input values in 0.05 unit steps 
# can be used to quantise the memoisation and therefore allow for arbitrary precision. A more 
# complex hash function that allows for mapping based on the first differential of the function 
# being memoised can give scaled memoisation boundaries based on the maximum value change across
# an input range - allowing for optimal storage within your acceptable error range.

# To do the simple form of this with our tools we define our hash function and storage object:

sinhash(fn, val) = hash(val)
memoDict = Dict()

# Then we call the custom hash memoisation function with our targetfunction, storage object and hash 
# function followed by our inputs to the function.

println(ApproximateHashingMemoise(sin, memoDict, sinhash, 0.4))
println(ApproximateHashingMemoise(sin, memoDict, sinhash, 0.1))

# The returned value of the function will either be the actual value of calling that function with
# the inputs, or if a value is found in the storage object for the hash of the function and input
# then the stored value will be returned. Nice and simple!

# The weakness of this type of quantised memoisation is that the first value passed to it for any 
# given quantisation range will represent the whole range. In some cases where there is a non-uniform 
# access pattern for each quantisation range a value that is outside the commonly accessed part might
# be less representative than others.

# To combat this problem we can also use a trending memoisation approach. In this approach every 
# time a quantised range is accessed the result is added to a record and once the requisite number
# of samples has been taken the returned value when a hit is found is the average of all the results
# for that quantisation range.

# The call to do this is very similiar with the addition of a `samplecount` input variable and we use 
# a more complex storage object to enable the counting of samples for each element. In the demo below
# we use a sample count of `3`:

trendingArray = []
for i in 1:5000
   push!(trendingArray,[0,0.0,0.0]) 
end

trendingsinhash(fn, val) = 1+Int64.(round(val*10.0))

println(TrendingMemoisation(sin, trendingsinhash, trendingArray, 3, 0.5)  == 0.479425538604203)
println(TrendingMemoisation(sin, trendingsinhash, trendingArray, 3, 0.55) == 0.5226872289306592)
println(TrendingMemoisation(sin, trendingsinhash, trendingArray, 3, 0.51) == 0.48817724688290753)
println(TrendingMemoisation(sin, trendingsinhash, trendingArray, 3, 0.59) == 0.5563610229127838)
println(TrendingMemoisation(sin, trendingsinhash, trendingArray, 3, 0.59) == 0.5563610229127838)

# # Loop Perforation

# Loop perforation is an approximation approach where loops are manipulated to reduce the iteration
# count in some way to improve the performance of an application without impacting the final result
# beyond a fixed constraint.

# This part of our library allows for the targeted replacement of loops parameters to achieve this in
# a generic way to arbitrary code.

# We perform this optimisation on Julia AST representations. As these cannot in the current release of
# Julia be directly extracted from a compiled function we require that the source is directly provided,
# like so:

expr =	quote
				function newfunc()
					aa = 0
					for i in 1:10
						aa = aa + 1
					end
					aa
				end
			end

# This example is of a simple loop which will increment a variable based on a ranged loop. This example
# is being used as it is trivial to test if the loop replacement has been a success.

# With our function defined we pass it into the loop perforatation function:

LoopPerforation(expr, UnitRange, ClipFrontAndBack)

# The function takes three inputs. The source code that is to be manipulated, the type of loop to
# target (in this case a loop which uses a UnitRange, others are supported and can be trivially
# extended to match any pattern), and a function which will output the replacement parameters. 
# The result of calling this function is that the input source code is changed in place.

# For our demo here we are passing in the source code, `UnitRange` as we are looking to replace the 
# `1:10` loop parameter which is a `UnitRange` and the included function `ClipFrontAndBack` which 
# takes the UnitRange and increments the minimum value and decrements the maximum value, resulting 
# in the range `2:8`.

# Once this has been called and has succeeded we can extract the function for use by evaluating the
# Julia Expressions:

eval(expr)

# We can test to see if the output is what we expect
	
println(newfunc() == 8)


# # AST Generation and Analysis

# ASTs in this library are formed through trees of `TreeMember` derived types. A `TreeMember` branch can be either
# an `Operator` or a `Variable` - leaves can be any type as they are only inputs into the other derived TreeMember
# types.

# When working with trees we do not define Operators explicitly - they are output from functions which take `Variables`
# as inputs. Like so:

DemoFunc(x) = x + x
DemoTree = DemoFunc(Variable(:x))
println(DemoTree)

# We can view these generated trees in a nicer form by using `printtree` - which also gives contextual information on
# the information stored within the `TreeMember` entries in the tree.
printtree(DemoTree)

# We can also view the tree with less information using `ToString`
println(ToString(DemoTree))

# We are able to have trees with constants in them, which are not `TreeMember` types
DemoFunc(x) = x + 1.0
DemoTree = DemoFunc(Variable(:x))
println("Tree with constant:")
println(DemoTree)
printtree(DemoTree)

# In our output, the constant values are labelled. When performing some transforms it is useful to have these contained
# within a `Variable` type. To do this we use the function `ReplaceConstantsWithVariables(tree)`
println("Tree with constant changed to a Variable type:")
ReplaceConstantsWithVariables(DemoTree)
printtree(DemoTree)

# This transform does not change how the function can be executed or the result. We can test this by running our tree.
# Trees are executed by evaluation using `EmulateTree(t, DictInputs=())`
@show input=1.0
print( "Original Result: ")
println( DemoFunc(input) )
print( "Altered Tree Result: ")
println( EmulateTree(DemoTree, Dict(:x=>input)))

# When emulating a tree we need to pass the inputs in as a dictionary for each symbol, or we can define the symbols
# globally using `SetSymbolValue(symbol, value)` and we can clear all set variables with `ClearSymbolDict()`
@show input=2.0
SetSymbolValue(:x, input)
print( "Original Result: ")
println( DemoFunc(input) )
print( "Altered Tree Result: ")
println( EmulateTree(DemoTree) )
ClearSymbolDict()

# When we want to create a tree from more complex functions we need to anable the environment to be able to map any
# internal function calls to our AST inputs types. 
ComplexFunction(x) = sqrt(x)

try
   ComplexTree = ComplexFunction(Variable(:x))
catch
   println("We were unable to create an AST from ComplexFunction as `sqrt` is not defined to take a Variable as an input.") 
end

# To be able to create the tree we need to detect all the function calls within the submitted function and override them.
# In Julia we cannot override a function unless it has been imported. As we cannot import functions when not at the global
# scope we have provided the macro `@importall' which will import all functions from a module automatically so that we can
# override them with our AST creation types.
using ImportAll
@importall Base

println("Generating override functions: ")
ovr = GetOverrides(ComplexFunction)
eval(GetConstructionFunction())(ovr, verbose=true)
println("Done!")

# With the environment configured we can not generate the tree for `ComplexFunction` without error.
println("We can now generate the tree for ComplexFunction:")
ComplexTree = ComplexFunction(Variable(:x))
printtree(ComplexTree)

# Once we are done with global variables we can clear them using `ClearSymbolDict()`
println("Clearing symbol dictionary:")
ClearSymbolDict()

# When we generate a tree each node is given a unique ID so that is can be easily targeted.
# The current GlobalID index can be retrieved with `GetGlobalID()` and reset with `ResetGlobalID()`
println("Current Global ID index is: $(GetGlobalID())")
ResetGlobalID()
println("Current Global ID index is: $(GetGlobalID())")

# To be able to analyse trees we have provided methods to be able to extract information.
# We will create an analysis function here to be our test object.
AnalysisFunction(x,y) = sqrt( (10.0 * x) + (5 * y * x * x) )
ovr = GetOverrides(AnalysisFunction)
eval(GetConstructionFunction())(ovr, verbose=true)
AnalysisTree = AnalysisFunction(Variable(:x), Variable(:y))
ReplaceConstantsWithVariables(AnalysisTree)

# First to get all the leaf nodes in the tree:
println("Show the initial state of the tree:")
println(ToString(AnalysisTree))

# Showing the leaves in our tree:
println("All Leaves:")
println(GetAllLeaves(AnalysisTree))

# Showing the symbols being used in our tree:
println("All Symbols:")
println(GetAllSymbols(AnalysisTree))

# Getting all the operators in this tree
println("All Operators:")
println(GetOperators(AnalysisTree))

# We also provide a function to extract just the IDs of each operator.
println("All Operators IDs:")
println(GetOperatorIDs(AnalysisTree))

# Get all subtrees:
println("Showing one of the subtrees:")
println(ToString(GetAllTrees(AnalysisTree)[3]))

# We can extract a specific branch by ID
println("Extracting a specific subtree:")
println(ToString(GetSubTree(AnalysisTree, 6)))

# If we want to edit the tree we can do replacement on any node.

# Here we will replace the multiply by `5.0` at ID=11 to a multiply by `24.5`
println("Changing the value of Variable with ID=11 from 5.0 to 24.5")
ReplaceSubTree(AnalysisTree, Variable(24.5) ,11)

# And here is the result.
# We can see that it has replaced the `Variable` with ID 11 with the new `Variable` we created which has the ID 12
println(ToString(AnalysisTree))

# We can also transform any variable into a different type. So lets change the `Variable` we have just inserted from 
# a Float64 to a Float32
println("Changing the type of Variable with ID=12 from Float64 to Float32")
ReplaceTypeOfSpecifiedVariable(AnalysisTree, 12, Float32)
println(ToString(AnalysisTree))

# That worked - but what if we wanted to change all `Variable`'s of one type to another? We use
#  `ReplaceAllVariablesOfType(tree, targettype, replacementtype)`. This will go through and replace all entries of one type
# with another. This step will replace the last Float64 with a Float32 of the same value.
println("Changing the type of all Float64 variables to Float32")
ReplaceAllVariablesOfType(AnalysisTree, Float64, Float32)
println(ToString(AnalysisTree))

# In the above example you may have noticed that the type of the symbol `x` is ambiguous. This is due to it being dependent
# on what value you assign to the symbol. If you want it to be a Float32 then pass a Float32 to the function when it is called.

# When we have finished making changes to the AST we may want to be able to convert it back to a normal Julia function, we can 
# do that with `TreeToFunction`
func = TreeToFunction(AnalysisTree, :OutputFunction)
print( "Tree Result: ")
println( EmulateTree(AnalysisTree, Dict(:x=>1.0, :y=>2.0)) )
print( "Generated Function Result: ")
println( func(1.0, 2.0) )
println("Name of function: $(func)")

# To help in analysing error between similar functions we provide the functions
# `TreeComparison` and `PrintTreeComparisonError` to compute the difference in results

# To show this we will create an arbitrary function `ErrorTestingFunction` which does a few operations
ErrorTestingFunction(x) = ((100.0/x) * x) + (0.0001 * x) * (10.00004 / x)
HighPrecisionTestingTree = ErrorTestingFunction(Variable(:x))

# We will then make a copy of it and reduce the precision to inject some error into the function
LowPrecisionTestingTree = deepcopy(HighPrecisionTestingTree)
ReplaceAllVariablesOfType(LowPrecisionTestingTree, Float64, Float32)
printtree(LowPrecisionTestingTree)

# We will then generate some input values between `0.01` and `1.0` to use as inputs of the correct type
HighPrecTestData = collect(0.01:0.001:1.0)
LowPrecTestData = Float32.(HighPrecTestData)

# As testing this function needs to specify which symbol needs to be given a value for input
# we need to extend our inputs to include which symbol input value they are representing.
HighPrecisionComparisonInput = []
LowPrecisionComparisonInput  = []
for i in 1:length(HighPrecTestData)
    push!(HighPrecisionComparisonInput,(:x, HighPrecTestData[i]))
    push!(LowPrecisionComparisonInput,(:x, LowPrecTestData[i]))
end

# We then pass the high and low precision trees and inputs to `TreeComparison` to get the 
# error data which we can print with `PrintTreeComparisonError`. This will give the overall
# error output of the function and compare the two.
compResults = TreeComparison(HighPrecisionTestingTree, LowPrecisionTestingTree, HighPrecisionComparisonInput, LowPrecisionComparisonInput)
PrintTreeComparisonError(compResults)

# When we have similar tree we want to determine the different in error at each node for each input.
# For this we use `GetErrorInTree`. This will output a new tree with the average error at each node stored
# and optionally with the `fetchtimeline` flag it will also return an array of the error for each input at
# each node.
resultsTree, perinputresults = GetErrorInTree(HighPrecisionTestingTree, LowPrecisionTestingTree, :x, HighPrecTestData, LowPrecTestData, fetchtimeline=true)
printtree(resultsTree)

# These errors per node can then be graphed with `PlotASTError` to give a clear idea of where error is introduced into the program for
# each input by displaying the error for each input for each subtree.
PlotASTError(resultsTree, perinputresults, HighPrecTestData, (768,512))
