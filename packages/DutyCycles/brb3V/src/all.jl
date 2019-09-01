import Measurements # This is used so rarely that the inconvenice of
                    # qualifying its members as Measurement.member is
                    # outweighted by the extra clarity gained.
using Unitful, UnitfulAngles
using Unitful: percent
using Documenter, DocStringExtensions

include("defaults.jl")
include("types.jl")
include("types-coherent.jl")
include("types-incoherent.jl")
include("types-union.jl")
include("accessors.jl")
include("constructors-helpers.jl")
include("constructors-coherent.jl")
include("constructors-incoherent.jl")
include("constructors.jl")
include("modification.jl")
include("coherence.jl")
include("waveforms.jl")
include("promotion.jl")
include("statistics.jl")
include("comparisons.jl")
include("operators.jl")
include("helpers.jl")
include("show.jl")
include("plot-recipes.jl")
