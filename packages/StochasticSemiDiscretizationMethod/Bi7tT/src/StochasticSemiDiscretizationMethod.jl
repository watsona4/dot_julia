module StochasticSemiDiscretizationMethod

import InteractiveUtils
using Reexport
@reexport using LinearAlgebra
@reexport using SparseArrays
@reexport using StaticArrays
@reexport using Arpack
using QuadGK
using Lazy: iterated, take

import SemiDiscretizationMethod
import SemiDiscretizationMethod:
AbstractLDDEProblem, AbstractResult,
MatrixOrFunction, ArrayOrFunction, VectorOrFunction, RealOrFunction, CyclicVector,
DiscretizationMethod, SemiDiscretization, NumericSD, methodorder, lagr_el0,
Coefficients, CoefficientMatrix, AdditiveVector,
ProportionalMX, DelayMX, Additive,
Delay,
subArray, SubMX, SubV,
calculate_Aavgs,
# calculateResults,
addSubmatrixToResult!,addSubvectorToResults!,
DiscreteMapping, DiscreteMappingSteps, 
subMxRange, rOfDelay, nStepOfLength, prodl,
reduce_additive

calculateDetResults! = SemiDiscretizationMethod.calculateResults!

include("structures_input.jl")
include("structures_method.jl")
include("structures_result.jl")

include("functions_method.jl")
include("functions_stoch_utilities.jl")
include("functions_discretization.jl")

export  SemiDiscretization, NumericSD, 
ProportionalMX,
Delay,DelayMX,
stCoeffMX,
Additive, stAdditive,
LDDEProblem,
DiscreteMapping_M1, DiscreteMapping_M2,
MxToCovVec, VecToCovMx,
# DiscreteMapping_M1_1step, DiscreteMapping_M2_1step,
fixPointOfMapping, spectralRadiusOfMapping

end # module
