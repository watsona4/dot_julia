using SemidefiniteModels
using Compat
using Compat.Test
using Compat.LinearAlgebra

include("sdinterface.jl")
using CSDP
sdtest(CSDP.CSDPSolver(), duals=true)
