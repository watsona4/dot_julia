using ScanImageTiffReader
using Test
using DotEnv
using JSON

DotEnv.config()

@testset "failures" begin
    filename = "/not/a/file"
    @test_throws Exception ScanImageTiffReader.open(filename, size)
end

if haskey(ENV, "TESTBASE")
    testbase = ENV["TESTBASE"]

    include("test_9ketamineoriginalcropped.jl")
    include("test_BigTIFF.jl")
    include("test_BigTIFFLong.jl")
    include("test_BigTIFFLong8.jl")
    include("test_BigTIFFMotorola.jl")
    include("test_BigTIFFMotorolaLongStrips.jl")
    include("test_BigTIFFSubIFD4.jl")
    include("test_BigTIFFSubIFD8.jl")
    include("test_Classic.jl")
    include("test_TR_003.jl")
    include("test_lin_00001.jl")
    include("test_linfree_00001.jl")
    include("test_linfreej_00001.jl")
    include("test_linj_00001.jl")
    include("test_oldfmt.jl")
    include("test_oldfmtj.jl")
    include("test_res_00001.jl")
    include("test_resfree_00001.jl")
    include("test_resfreej_00001.jl")
    include("test_resj_00001.jl")
    include("test_resj_2018a_00002.jl")
    include("test_single_image_si.jl")
else
    testbase = mktempdir()

    # download a test file
    dsource = "https://drive.google.com/uc?export=download&id=1Zbje2OG1QqUr9D4UGd_ag2iV6aiM_6j0"

    import HTTP
    r = HTTP.request("GET", dsource; redirect=true)
    open(joinpath(testbase, "linj_00001.tif"), "w") do io
        write(io, r.body)
    end

    include("test_linj_00001.jl")

    # cleanup
    rm(joinpath(testbase, "linj_00001.tif"))
    rm(testbase)
end
