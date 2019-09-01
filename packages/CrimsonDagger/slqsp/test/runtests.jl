using Distributed
addprocs(2)

using Dagger
import Dagger: indexes, project
using CrimsonDagger
using Test

include("domain.jl")
include("array.jl")
include("scheduler-options.jl")
include("fault-tolerance.jl")
# TODO: include("cache.jl")
Dagger.cleanup()
