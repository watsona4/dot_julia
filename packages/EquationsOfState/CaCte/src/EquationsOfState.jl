module EquationsOfState

using Reexport

include("Collections.jl")
@reexport using .Collections

include("NonlinearFitting.jl")
@reexport using .NonlinearFitting

include("FiniteStrains.jl")
@reexport using .FiniteStrains

include("LinearFitting.jl")
@reexport using .LinearFitting

end # module
