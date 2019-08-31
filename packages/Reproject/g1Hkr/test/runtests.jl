using Reproject
using Test
using Conda, PyCall
using FITSIO, WCS
using SHA: sha256

ENV["PYTHON"]=""
Conda.add_channel("astropy")
Conda.add("reproject")
rp = pyimport("reproject")
astropy = pyimport("astropy")

include("parsers.jl")
include("utils.jl")
include("core.jl")
