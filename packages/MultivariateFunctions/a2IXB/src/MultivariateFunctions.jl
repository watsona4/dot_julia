module MultivariateFunctions

using Dates
using SchumakerSpline
using GLM
using DataFrames: DataFrame
using DataStructures: OrderedDict
using Combinatorics: permutations
using LinearAlgebra: Symmetric, inv, det
using Optim

# This includes functions for use of MultivariateFunctions with dates.
include("date_conversions.jl")
export years_between, years_from_global_base, period_length
# The abstract type MultivariateFunction and all structs are implemented here.
# In addition we have operator reversals and some supporting functions.
include("0_structs_and_generic_reversals.jl")
export MultivariateFunction, PE_Function, Sum_Of_Functions, Piecewise_Function
export Sum_Of_Piecewise_Functions, PE_Unit
export change_base, trim_piecewise_function, sort, convert_to_linearly_rescale_inputs
export evaluate, rebadge, underlying_dimensions, convert, ≂
include("1_algebra.jl")
export +, -, *, /, ^
include("2_calculus.jl")
export derivative, all_derivatives, Hessian, jacobian, uniroot, find_local_optima
export integral
include("3_1D_splines_and_interpolation.jl")
export create_quadratic_spline, create_constant_interpolation_to_right
export create_constant_interpolation_to_left, create_linear_interpolation
include("chebyshevs.jl")
export get_chevyshevs_up_to
include("4_chebyshev_approximation.jl")
export create_chebyshev_approximation
include("5_ols_regression.jl")
export create_ols_approximation, create_saturated_ols_approximation
include("6_HighDimensionalApproximation.jl")
export create_recursive_partitioning, create_mars_spline, trim_mars_spline
end
