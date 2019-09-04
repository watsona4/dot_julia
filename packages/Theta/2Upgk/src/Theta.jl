module Theta

using LinearAlgebra
using NLopt
using GSL: sf_gamma_inc

include("riemann_matrix.jl")
include("eval_theta.jl")

include("lattice.jl")
include("ellipsoid.jl")
include("radius.jl")

include("characteristics.jl")
include("siegel_transform.jl")

include("schottky4.jl")
include("accola.jl")
include("fgsm.jl")

export theta
export RiemannMatrix, random_siegel
export siegel_transform, symplectic_transform
export theta_char, even_theta_char, odd_theta_char, check_azygetic
export schottky_genus_4, random_nonschottky_genus_4
export accola_chars, accola, random_nonaccola
export fgsm_chars, fgsm, random_nonfgsm

end 
