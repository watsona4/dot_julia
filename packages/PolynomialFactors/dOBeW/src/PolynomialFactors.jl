
module PolynomialFactors


## TODO
## * performance is still really poor for larger degrees.


using AbstractAlgebra
using Combinatorics
import Primes
import LinearAlgebra
import LinearAlgebra: norm, dot, I


include("utils.jl")
include("polyutils.jl")
include("factor_zp.jl")
include("lll.jl")
include("factor_zx.jl")


export poly_factor, factormod
#export factor, rational_roots, factormod


end # module
