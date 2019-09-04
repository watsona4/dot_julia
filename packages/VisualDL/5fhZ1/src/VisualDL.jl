__precompile__()
module VisualDL

using PyCall
const LogWriter = PyNULL()

function __init__()
    copy!(LogWriter, pywrap(pyimport("visualdl")).LogWriter)
end

include("logger.jl")

end # module
