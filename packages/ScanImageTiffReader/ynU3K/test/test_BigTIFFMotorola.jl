@testset "BigTIFFMotorola.tif" begin
filename = joinpath(testbase, "BigTIFFMotorola.tif")
    # $ ScanImageTiffReader image shape BigTIFFMotorola.tif
    # Shape: 3 x 64 x 64 @ u8
    tsize = ScanImageTiffReader.open(filename) do io
        size(io)
    end
    @test tsize == (3, 64, 64)
    ttype = ScanImageTiffReader.open(filename) do io
        pxtype(io)
    end
    @test ttype == UInt8

    # $ ScanImageTiffReader image bytes BigTIFFMotorola.tif
    # 12 kB
    dat = ScanImageTiffReader.open(filename) do io
        data(io)
    end
    @test abs(sizeof(dat)/2^10 - 12.0) < 1e-5
    # @test ScanImageTiffReader.open(filename, length) == size(dat, 3) # TODO: check this assumption

    # $ ScanImageTiffReader descriptions --frame 0 BigTIFFMotorola.tif
    #
    @test ScanImageTiffReader.open(description, filename, 1) == ""

    # $ ScanImageTiffReader metadata BigTIFFMotorola.tif
    #
    @test ScanImageTiffReader.open(metadata, filename) == ""
end
