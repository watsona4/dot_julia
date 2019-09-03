@testset "9ketamineoriginalcropped.tif" begin
filename = joinpath(testbase, "9ketamineoriginalcropped.tif")
    # $ ScanImageTiffReader image shape 9ketamineoriginalcropped.tif
    # Shape: 119 x 114 x 300 @ u16
    tsize = ScanImageTiffReader.open(filename) do io
        size(io)
    end
    @test tsize == (119, 114, 300)
    ttype = ScanImageTiffReader.open(filename) do io
        pxtype(io)
    end
    @test ttype == UInt16

    # $ ScanImageTiffReader image bytes 9ketamineoriginalcropped.tif
    # 7.76253 MB
    dat = ScanImageTiffReader.open(filename) do io
        data(io)
    end
    @test abs(sizeof(dat)/2^20 - 7.76253) < 1e-5
    # @test ScanImageTiffReader.open(filename, length) == size(dat, 3) # TODO: check this assumption

    # $ ScanImageTiffReader descriptions --frame 0 9ketamineoriginalcropped.tif
    # "ImageJ=1.49v"
    # "images=300"
    # "slices=300"
    # "cf=0"
    # "c0=-32768.0"
    # "c1=1.0"
    # "vunit=Gray Value"
    # "loop=false"
    # "min=32556.0"
    # "max=34238.0"
    desc = ScanImageTiffReader.open(filename) do io
        split(description(io, 1), "\n")
    end
    @test desc[1] == "ImageJ=1.49v"
    @test desc[2] == "images=300"
    @test desc[3] == "slices=300"
    @test desc[4] == "cf=0"
    @test desc[5] == "c0=-32768.0"
    @test desc[6] == "c1=1.0"
    @test desc[7] == "vunit=Gray Value"
    @test desc[8] == "loop=false"
    @test desc[9] == "min=32556.0"
    @test desc[10] == "max=34238.0"

    # $ ScanImageTiffReader metadata 9ketamineoriginalcropped.tif
    #
    @test ScanImageTiffReader.open(metadata, filename) == ""
end
