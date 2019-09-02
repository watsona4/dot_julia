
using HELICS
using Test
const h = HELICS

@test h.helicsGetVersion() isa String
@test h.helicsGetVersion() == "2.0.0 (03-10-19)"

include("valuefederate.jl")
include("messagefederate.jl")
include("combinationfederate.jl")
include("messagefilter.jl")

include("api.jl")

include("query.jl")
