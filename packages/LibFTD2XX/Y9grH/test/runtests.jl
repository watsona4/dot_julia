# LibFTD2XX.jl
#
# By Reuben Hill 2019, Gowerlabs Ltd, reuben@gowerlabs.co.uk
#
# Copyright (c) Gowerlabs Ltd.

using LibFTD2XX

include("util.jl")

numdevs = LibFTD2XX.createdeviceinfolist()
if numdevs > 0
  @info "found $numdevs devices. Running hardware tests..."
  include("hardware/wrapper.jl")
  include("hardware/LibFTD2XX.jl")
else
  @info "found $numdevs devices. Running nohardware tests..."
  include("nohardware/wrapper.jl")
  include("nohardware/LibFTD2XX.jl")
end