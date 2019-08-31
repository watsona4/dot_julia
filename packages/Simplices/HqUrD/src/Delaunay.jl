__precompile__()
module Delaunay

using StaticArrays
using LinearAlgebra
using PyCall

# strides(::Transpose) is not implemented. This workaround from
# https://github.com/JuliaPy/PyCall.jl/issues/555 should fix it.
using PyCall: PyObject
PyObject(x::Adjoint) = PyObject(copy(x))
PyObject(x::Transpose) = PyObject(copy(x))

const scipyspatial = PyNULL()

function __init__()
    copy!(scipyspatial, pyimport_conda("scipy.spatial", "scipy"))
end

function simplexindices_static(delaunaytriang::PyCall.PyObject)
    # The indices of simplices from the pycall object
    py_simplexinds = delaunaytriang."simplices"

    # Get the indices of the first simplex to determine
    # the number of dimensions.
    n_vertices = length(get(py_simplexinds, PyVector{Int32}, 0))

    # Convert to Julian, accounding for index differences
    # between Python and Julia
    n_simplices = length(py_simplexinds)
    juliainds = Vector{SVector{n_vertices, Int32}}(undef, n_simplices)
    for i = 1:n_simplices
        v = get(py_simplexinds, PyVector{Int32}, i - 1) .+ 1
        juliainds[i] = SVector{n_vertices}(v)
    end
    juliainds
end


function simplexindices(delaunaytriang::PyCall.PyObject)
    # The indices of simplices from the pycall object
    py_simplexinds = delaunaytriang."simplices"

    # Get the indices of the first simplex to determine
    # the number of dimensions.
    n_vertices = length(get(py_simplexinds, PyVector{Int32}, 0))

    # Convert to Julian, accounding for index differences
    # between Python and Julia
    n_simplices = length(py_simplexinds)
    juliainds = Vector{Vector{Int32}}(undef, n_simplices)
    for i = 1:n_simplices
        v = get(py_simplexinds, PyVector{Int32}, i - 1) .+ 1
        juliainds[i] = v
    end
    juliainds
end

function delaunay_static(points)
    triang = scipyspatial.Delaunay(points)
    simplexindices_static(triang)
end

function delaunay(points)
    triang = scipyspatial.Delaunay(points)
    simplexindices(triang)
end

function delaunayn(points)
    py = scipyspatial.Delaunay(points)
    indices = zeros(Int, length(py."simplices"), size(points, 2) + 1)
    pyarray_to_array!(py."simplices", indices, Int)
    return indices .+ 1 # Add 1 to account for base difference in indices
end

function pyarray_to_array!(pyobject, arr, T)
    for i = 1:length(pyobject)
        arr[i, :] = get(pyobject, PyVector{T}, i-1) # i-1 because of Python 0 indexing
    end
end

export delaunay, delaunay_static, delaunayn

end
