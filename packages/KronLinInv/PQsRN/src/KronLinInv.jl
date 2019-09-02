

#
# This file is a part of KronLinInv. License is MIT
# Copyright (c) 2019 Andrea Zunino
#

##==========================================================
module KronLinInv

export CovMats,FwdOps,KLIFactors
export calcfactors,posteriormean,blockpostcov


using Distributed
using LinearAlgebra

include("kronlininv.jl")

include("kronlininv_serial.jl")

##==========================================================
end # module
#########################################
