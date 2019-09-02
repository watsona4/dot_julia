module lattice

include("load_kwant.jl")
import .. AbstractKwantObject

abstract type AbstractLattice <:AbstractKwantObject end

struct Monatomic <: AbstractLattice o::PyObject end
struct Polyatomic <: AbstractLattice o::PyObject end

(lat::Monatomic)(i::Integer,j::Integer) = pycall(lat.o,PyObject,i,j)

square(a=1;kwargs...) = Monatomic(kwant.lattice.square(a;kwargs...))

general(arg;kwargs...) = Monatomic(kwant.lattice.general(arg;kwargs...))
general(arg1,arg2;kwargs...) = Polyatomic(kwant.lattice.general(arg1,arg2;kwargs...))

# function Base.getproperty(k::AbstractLattice, name::Symbol)
    # if name==:o
        # p = getfield(k,:o)
    # else
        # p = getproperty(k.o,name)
    # end
# #     if name==:sublattices
# #         p = Monatomic.(p)
#     end
    # return p
# end

end # module

# function Base.getproperty(k::AbstractLattice, name::Symbol)
#     if name==:o
#         p = getfield(k,:o)
#     else
#         p = getproperty(k.o,name)
#     end
#     if name==:neighbors
#         p = _Neighbors(p)
#     end
#     return p
# end
