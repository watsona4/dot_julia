module ApproximateComputations

include("FittingFunctionApproximation.jl")
include("ASTReplacementApproximation.jl")
include("LoopPerforation.jl")
include("Memoisation.jl")


### Fitting functions exports
# Exporting the approximation wrapper type
export Approximation, Get

# Exporting function generation results types
export GeneratedFunctionType, ErrorResultsContainer

# Exporting getters for function result type
export GetAbsoluteError, GetMeanDifference, GetMedianDifference, GetMedianBenchmarkTime, GetMeanBenchmarkTime

# Exporting function selection functions
export GetFastestAcceptable, FilterFunctionList, GetFunctionName

# Export function visualisation plotting functions
export PlotApproximationFunctionResults, PlotApproximationFunctionDiff, PlotApproximationFunctionDiffHist, PlotMedianError, PlotMedianRuntime, PlotRuntimeErrorPair

# Export main function for generating replacement functions
export GenerateAllApproximationFunctions

# Exporting Loop Perforation function and helpers
export LoopPerforation
export OnlyEvenIterations, OnlyOddIterations, ClipFrontAndBack, OnlyFirstHalf, OnlySecondHalf

# Exporting Memoisation
export TrendingMemoisation, ApproximateHashingMemoise

### AST Replacement Exports
export Operator, Variable, TreeMember, ResetGlobalID, GetGlobalID
export EmulateTree, FullUnwrap, UnwrapTree, WrapTree, ReplaceSubTree, GetAllTrees, UpdateEnvironmentForFunction
export printtree, SetSymbolValue, ClearSymbolDict
export GetAllLeaves, GetAllSymbols, GetAllSymbolsList
export GetOverrides, GetConstructionFunction, @BuildOverrideFromArray
export ReplaceConstantsWithVariables, ReplaceTypeOfSpecifiedVariable, ReplaceAllVariablesOfType
export InArray, GetOperatorIDs, GetOperators
export GetResultForID, SetResultForID
export GetErrorInTree
export GetSubTree
export ToString
export PlotASTError
export TreeToFunction, TreeToFunctionLeaf
export PrintTreeComparisonError, TreeComparison
end