module Media

include("dynamic.jl")
include("system.jl")
include("compat.jl")

function __init__()
  init_compat()
end

end
