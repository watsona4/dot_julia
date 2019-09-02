"""
This module implements various methods of locally approximating a function, such as multi-linear, simplex
and k-nearest-neighbor approximation. An example use case is for locally approximating value
functions in value iteration
"""
module LocalFunctionApproximation

using GridInterpolations
using NearestNeighbors
import NearestNeighbors: NNTree

using Distances

export
	LocalFunctionApproximator,
	LocalGIFunctionApproximator,
	LocalNNFunctionApproximator,
	n_interpolating_points,
	get_all_interpolating_points,
	get_all_interpolating_values,
	get_interpolating_nbrs_idxs_wts,
	compute_value,
	set_all_interpolating_values,
	finite_horizon_extension


abstract type LocalFunctionApproximator end

"""
	n_interpolating_points(lfa::LocalFunctionApproximator)

Return the number of interpolanting points that the approximator is using
"""
function n_interpolating_points end

"""
	get_all_interpolating_points(lfa::LocalFunctionApproximator)

Return the vector of points (in a specific order) that are used to interpolate
"""
function get_all_interpolating_points end

"""
	get_all_interpolating_values(lfa::LocalFunctionApproximator)

Return the vector of all interpolating values (in the same order as the interpolating points)
"""
function get_all_interpolating_values end

"""
	get_interpolating_nbrs_idxs_wts(lfa::LocalFunctionApproximator, v::AbstractVector)

Return a tuple of (indices, weights) for the interpolants for a specific query v
"""
function get_interpolating_nbrs_idxs_wts end

"""
	compute_value(lfa::LocalFunctionApproximator, v::AbstractVector)

Return the value of the function at some query point v, based on the local function approximator

	compute_value(lfa::LocalFunctionApproximator, v_list::AbstractVector{V}) where V <: AbstractVector{Float64}

Return the value of the function for a list of query points, based on the local function approximator
"""
function compute_value end

"""
	set_all_interpolating_values(lfa::LocalFunctionApproximator, vals::AbstractVector)

Set the values of all interpolating points to the input vector
"""
function set_all_interpolating_values end

"""
	finite_horizon_extension(lfa::LocalFunctionApproximator, hor::Int64)

Extend the LFA appropriately along a new dimension to allow for finite-horizon approximations
"""
function finite_horizon_extension end


include("local_gi_fa.jl")
include("local_nn_fa.jl")

end # module
