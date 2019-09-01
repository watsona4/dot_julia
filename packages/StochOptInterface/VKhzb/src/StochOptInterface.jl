#  Copyright 2018, JuliaStochOpt and contributors.
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.
################################################################################
# StochOptInterface
# A Julia package to encode Stochastic Programming problems.
################################################################################
module StochOptInterface

using Compat

using TimerOutputs, DocStringExtensions
# Stochastic Program
include("stochprog.jl")
include("attributes.jl")

# Solution
include("solution.jl")
# Result informations and timing/allocation statistics
include("info.jl")
# Stopping Criterion
include("stopcrit.jl")

# Algorithm
include("algorithm.jl")

end
