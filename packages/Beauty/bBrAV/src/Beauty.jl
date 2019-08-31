# Part of Beauty.jl: Add Beauty to your julia output.
# Copyright (C) 2019 Quantum Factory GmbH

module Beauty

using Requires
using Printf

include("internal.jl")
include("show-floats.jl")

function __init__()
    @require DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0" include("dataframes.jl")
    @require Measurements = "eff96d63-e80a-5855-80a2-b1b0885c5ab7" include("measurements.jl")
    @require Unitful = "1986cc42-f94f-5a68-af5c-568840ba703d" include("unitful.jl")
end # __init__

end # module
