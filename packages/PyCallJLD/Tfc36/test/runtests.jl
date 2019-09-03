using PyCallJLD
using Test
using PyCall, JLD

tmp = joinpath(tempdir(), "temp.jld")
const deque = pyimport("collections")["deque"]

try
    obj = [deque([1,2,3]), deque([4,5,6])]
    save(tmp, "x", obj)
    @test load(tmp, "x") == obj

    save(tmp, "x", PyObject("fé"))
    @test load(tmp, "x") == PyObject("fé")

    obj = PyObject(rand(UInt8, 1000))
    save(tmp, "x", obj)
    @test load(tmp, "x") == obj
finally
    rm(tmp, force=true)
end
