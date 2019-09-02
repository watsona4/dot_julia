module builder

export Builder

include("load_kwant.jl")
import .. AbstractKwantObject

struct Builder <:AbstractKwantObject
    o::PyObject
    Builder() = new(kwant.Builder())
    Builder(x;kwargs...) = new(kwant.Builder(x;kwargs...))
end

Base.setproperty!(b::Builder, name::Symbol, x::AbstractKwantObject) =
    setproperty!(b.o,name,x.o)

Base.setindex!(b::Builder,val,keys...) = set!(b.o,keys,val)
Base.setindex!(b::Builder,val,key) = set!(b.o,key,val)
Base.setindex!(b::Builder,val,key::AbstractKwantObject) = set!(b.o,key.o,val)

struct HoppingKind <: AbstractKwantObject
    o::PyObject
    (hk::HoppingKind)(syst::Builder) = hk.o(syst)
    function HoppingKind(a::Tuple,b::AbstractKwantObject,c::AbstractKwantObject)
        new(pycall(kwant.builder.HoppingKind,PyObject,a,b.o,c.o))
    end
    # function HoppingKind(a::Tuple,b::PyObject,c::PyObject)
        # new(pycall(kwant.builder.HoppingKind,PyObject,a,b,c))
    # end
    HoppingKind(a::Tuple) = HoppingKind(a...)
end

function Base.deleteat!(b::Builder,o::PyObject)
    py"""
    del $(b.o)[$o]
    """
    return nothing
end

function Base.setindex!(b::Builder,val,keys::Array{HoppingKind})
    for k ∈ keys
        b[k]=val
    end
    return nothing
end

end # module

# struct FiniteSystem <:AbstractKwantObject o::PyObject end
