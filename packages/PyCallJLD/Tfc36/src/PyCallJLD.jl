# See https://github.com/JuliaIO/JLD.jl/blob/master/doc/jld.md#custom-serialization
__precompile__()
module PyCallJLD

using PyCall, JLD

const dumps = PyNULL()
const loads = PyNULL()

function __init__()
    pickle = pyimport(PyCall.pyversion.major ≥ 3 ? "pickle" : "cPickle")
    copy!(dumps, pickle["dumps"])
    copy!(loads, pickle["loads"])
end

struct PyObjectSerialization
    repr::Vector{UInt8}
end

function JLD.writeas(pyo::PyObject)
    b = PyCall.PyBuffer(pycall(dumps, PyObject, pyo))
    # We need a `copy` here because the PyBuffer might be GC'ed after we've
    # left this scope, but see
    # https://github.com/JuliaPy/PyCallJLD.jl/pull/3/files/17b052d018f79905baf855b40e440d2cacc171ae#r115525173
    PyObjectSerialization(copy(unsafe_wrap(Array, Ptr{UInt8}(pointer(b)), sizeof(b))))
end

function JLD.readas(pyo_ser::PyObjectSerialization)
    pycall(loads, PyObject,
           PyObject(PyCall.@pycheckn ccall(@pysym(PyCall.PyString_FromStringAndSize),
                                           PyPtr, (Ptr{UInt8}, Int),
                                           pyo_ser.repr, sizeof(pyo_ser.repr))))
end


end # module
