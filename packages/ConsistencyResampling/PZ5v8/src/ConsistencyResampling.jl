module ConsistencyResampling

using Bootstrap
using Bootstrap: BootstrapSampling
using StatsBase

using Random

import Bootstrap: bootstrap

export bootstrap, ConsistentSampling

include("bootstrap.jl")
include("utils.jl")

end # module
