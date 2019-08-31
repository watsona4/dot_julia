using SauterSchwabQuadrature

using LinearAlgebra
using Test

include("local_space.jl")
include("numquad.jl")
include("verificationintegral.jl")

include("test_cf_p_verification.jl")
include("test_ce_p_verification.jl")
include("test_cv_p_verification.jl")
include("test_pd_p_verification.jl")
