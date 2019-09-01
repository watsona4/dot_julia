module DiracNotation

using Requires
include("prettyprint.jl")

function __init__()
    @require QuantumOptics = "6e0679c1-51ea-5a7c-ac74-d61b76210b0c" include("qo.jl")
end

end # module
