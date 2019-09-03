@testset "BigTIFFSubIFD8.tif" begin
filename = joinpath(testbase, "BigTIFFSubIFD8.tif")
    # $ ScanImageTiffReader image shape BigTIFFSubIFD8.tif
    # Shape: 3 x 64 x 64 x 2 @ u8
    tsize = ScanImageTiffReader.open(filename) do io
        size(io)
    end
    @test tsize == (3, 64, 64, 2)
    ttype = ScanImageTiffReader.open(filename) do io
        pxtype(io)
    end
    @test ttype == UInt8

    # $ ScanImageTiffReader image bytes BigTIFFSubIFD8.tif
    # 24 kB
    dat = ScanImageTiffReader.open(filename) do io
        data(io)
    end
    @test abs(sizeof(dat)/2^10 - 24.0) < 1e-5
    # @test ScanImageTiffReader.open(filename, length) == size(dat, 4) # TODO: check this assumption

    # $ ScanImageTiffReader descriptions --frame 0 BigTIFFSubIFD8.tif
    #
    @test ScanImageTiffReader.open(description, filename, 1) == ""

    # $ ScanImageTiffReader metadata BigTIFFSubIFD8.tif
    #
    @test ScanImageTiffReader.open(metadata, filename) == ""
end
