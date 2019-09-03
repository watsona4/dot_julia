__precompile__()

module Struve

include("fast.jl")
include("integral.jl")
include("large_arg.jl")
include("small_arg.jl")

# define defaults, should be exact
const H0 = _H0_integral
const K0 = _K0_integral
const L0 = _L0_integral
const M0 = _M0_integral

const H = _H_integral
const K = _K_integral
const L = _L_integral
const M = _M_integral

# define fast, less exact alternatives
const H0_fast = _H0_fast
const H1_fast = _H1_fast

end # module
