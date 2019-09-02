# Profile performance of NIRX.jl file reading

# This files requires JUNO to run
# and plot the profiling output.
# Benchmark tools are used to
# measure time to read a recording.


using Test
using NIRX
using DataDeps
using Juno
using Profile, BenchmarkTools


## Register useful data dependencies

register(DataDep("NIRX test file 1", "Single fNIRS experiment recording",
    ["https://s3.amazonaws.com/test.robertluke.net/fNIRS-test-data.zip"];
    post_fetch_method = [file->run(`unzip $file`)]
))


## Run once for JIT
triggers, header_info, info, wl1, wl2, config = read_NIRX(string(datadep"NIRX test file 1", "/fNIRS-test-data"))


## Time and profile
@btime triggers, header_info, info, wl1, wl2, config = read_NIRX(string(datadep"NIRX test file 1", "/fNIRS-test-data"))
@profiler triggers, header_info, info, wl1, wl2, config = read_NIRX(string(datadep"NIRX test file 1", "/fNIRS-test-data"))
