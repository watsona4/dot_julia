module Kwant

export Builder,
TranslationalSymmetry,
smatrix,
lattice,
builder

abstract type AbstractKwantObject end

include("load_kwant.jl")
include("Lattice.jl")
include("Builder.jl")

using PyPlot
using .builder

function Base.getproperty(k::AbstractKwantObject, name::Symbol)
    if name==:o
        p = getfield(k,:o)
    else
        p = getproperty(k.o,name)
    end
    if name==:finalized
        q = _FiniteSystem(p)
    elseif name==:neighbors
        q = _Neighbors(p)
    elseif name==:submatrix
        q(args...;kwargs...) = submatrix(pycall(p,PyObject,args...,kwargs...))
    else
        q=p
    end
    return q
end

(p::PyObject)(k::AbstractKwantObject,args...;kwargs...) = pycall(p,PyObject,k.o,args...;kwargs...)


struct _FiniteSystem o::PyObject end
struct _Neighbors o::PyObject end
(fs::_FiniteSystem)() = pycall(fs.o,PyObject)
(nn::_Neighbors)() = pycall(nn.o,PyObject)

PyPlot.plot(b::AbstractKwantObject; kwargs...) = kwant.plot(b.o;kwargs...)

TranslationalSymmetry(x) = kwant.TranslationalSymmetry(x)
wave_function(args...;kwargs...) = kwant.wave_function(args...;kwargs...)

struct smatrix <: AbstractKwantObject
    o::PyObject
    smatrix(args...; kwargs...) = new(pycall(kwant.smatrix,PyObject,args...,kwargs...))
end
struct submatrix{T,N} <: AbstractArray{T,N}
    o::PyObject
    sbm::Array{T,N}
    function submatrix(o::PyObject)
        sbm = convert(Array,o)
        return new{eltype(sbm),ndims(sbm)}(o,sbm)
    end
end
Base.show(io::IO,sbm::submatrix) = show(io,sbm.sbm)
function Base.getproperty(k::submatrix, name::Symbol)
    if name==:o
        p = getfield(k,:o)
    elseif name==:sbm
        p = getfield(k,:sbm)
    else
        p = getproperty(k.o,name)
    end
    return p
end

funs = [:+,:-,:conj,:size,:length,:getindex]
for fun ∈ funs
    @eval Base.$fun(sbm::submatrix,args...;kwargs...) = $fun(sbm.sbm,args...;kwargs...)
    @eval Base.$fun(sbm1::submatrix,sbm2::submatrix,args...;kwargs...) = $fun(sbm1.sbm,sbm2.sbm,args...;kwargs...)
    @eval Base.$fun(x::Any,sbm::submatrix,args...;kwargs...) = $fun(x,sbm.sbm,args...;kwargs...)
end


end # module
