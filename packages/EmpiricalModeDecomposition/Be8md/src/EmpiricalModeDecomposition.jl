module EmpiricalModeDecomposition

using AbstractFFTs
using Dierckx
using Distributions
using FFTW
using ForwardDiff
using LinearAlgebra
using Random
using Statistics

include("mode-decompositions/emd.jl")
include("mode-decompositions/eemd.jl")
include("extras/hilbert.jl")

export EMDSetting, emd, EEMDSetting, eemd, hilbert_transform, hht

end # module
