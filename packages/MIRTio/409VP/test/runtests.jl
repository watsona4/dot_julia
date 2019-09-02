# test/runtests.jl

using MIRTio
using Test

@test read_rdb_hdr(:test)
