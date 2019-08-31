"""
    CALCEPH

  This module is a wrapper of CALCEPH, IMCCE planetary ephemeris access
  library. It supports INPOPxx, JPL DExxx and SPICE ephemeris.

  https://www.imcce.fr/inpop/calceph

"""
module CALCEPH

# To make Pkg aware that this dependency
# will be injected by BinaryProvider.
using Libdl

deps = abspath(joinpath(splitdir(@__FILE__)[1], "..", "deps", "deps.jl"))
if isfile(deps)
    include(deps)
else
    error("libcalceph was not found. Please run 'Pkg.build(\"CALCEPH\").")
end

struct CALCEPHException <: Exception
    msg::String
end

include("ephem.jl")
export Ephem, prefetch, CALCEPHException

include("compute.jl")
export compute

include("timespan.jl")
export timespan

include("bodyId.jl")
export naifId

include("units.jl")
export unitAU, unitKM, unitDay, unitSec, unitRad, useNaifId, outputEulerAngles, outputNutationAngles

include("orient.jl")
export orient

include("rotAngMom.jl")
export rotAngMom

include("constants.jl")
export constants

include("introspection.jl")
export timeScale, positionRecords, orientationRecords

include("fivePointStencil.jl")

include("errorHandling.jl")

end # module
