@testset "TR_003.tif" begin
filename = joinpath(testbase, "TR_003.tif")
    # $ ScanImageTiffReader image shape TR_003.tif
    # Shape: 512 x 512 x 10 @ i16
    tsize = ScanImageTiffReader.open(filename) do io
        size(io)
    end
    @test tsize == (512, 512, 10)
    ttype = ScanImageTiffReader.open(filename) do io
        pxtype(io)
    end
    @test ttype == Int16

    # $ ScanImageTiffReader image bytes TR_003.tif
    # 5 MB
    dat = ScanImageTiffReader.open(filename) do io
        data(io)
    end
    @test abs(sizeof(dat)/2^20 - 5.0) < 1e-5
    # @test ScanImageTiffReader.open(filename, length) == size(dat, 3) # TODO: check this assumption

    # $ ScanImageTiffReader descriptions --frame 0 TR_003.tif
    # "Frame Tag = 00000001" 
    # "scanimage.SI4.acqFrameBufferLength = 11" 
    # "scanimage.SI4.acqFrameBufferLengthMin = 2" 
    # "scanimage.SI4.acqFramesDone = 0" 
    # "scanimage.SI4.acqNumAveragedFrames = 1" 
    # "scanimage.SI4.acqNumFrames = 10" 
    # "scanimage.SI4.acqState = 'idle'" 
    # "scanimage.SI4.beamDirectMode = false" 
    # "scanimage.SI4.beamFillFracAdjust = 14" 
    # "scanimage.SI4.beamFlybackBlanking = true" 
    # [...]
    desc = ScanImageTiffReader.open(filename) do io
        split(description(io, 1), "\n")
    end
    @test desc[1] == "Frame Tag = 00000001"
    @test desc[2] == "scanimage.SI4.acqFrameBufferLength = 11"
    @test desc[3] == "scanimage.SI4.acqFrameBufferLengthMin = 2"
    @test desc[4] == "scanimage.SI4.acqFramesDone = 0"
    @test desc[5] == "scanimage.SI4.acqNumAveragedFrames = 1"
    @test desc[6] == "scanimage.SI4.acqNumFrames = 10"
    @test desc[7] == "scanimage.SI4.acqState = 'idle'"
    @test desc[8] == "scanimage.SI4.beamDirectMode = false"
    @test desc[9] == "scanimage.SI4.beamFillFracAdjust = 14"
    @test desc[10] == "scanimage.SI4.beamFlybackBlanking = true"

    # $ ScanImageTiffReader metadata TR_003.tif
    #
    @test ScanImageTiffReader.open(metadata, filename) == ""
end
