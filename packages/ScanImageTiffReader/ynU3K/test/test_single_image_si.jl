@testset "single_image_si.tif" begin
filename = joinpath(testbase, "single_image_si.tif")
    # $ ScanImageTiffReader image shape single_image_si.tif
    # Shape: 512 x 512 @ i16
    tsize = ScanImageTiffReader.open(filename) do io
        size(io)
    end
    @test tsize == (512, 512)
    ttype = ScanImageTiffReader.open(filename) do io
        pxtype(io)
    end
    @test ttype == Int16

    # $ ScanImageTiffReader image bytes single_image_si.tif
    # 512 kB
    dat = ScanImageTiffReader.open(filename) do io
        data(io)
    end
    @test abs(sizeof(dat)/2^10 - 512.0) < 1e-5
    # @test ScanImageTiffReader.open(filename, length) == size(dat, 2) # TODO: check this assumption

    # $ ScanImageTiffReader descriptions --frame 0 single_image_si.tif
    # "frameNumbers = 1" 
    # "acquisitionNumbers = 1" 
    # "frameNumberAcquisition = 1" 
    # "frameTimestamps_sec = 0.000000000" 
    # "acqTriggerTimestamps_sec = 0.000000000" 
    # "nextFileMarkerTimestamps_sec = -1.000000000" 
    # "endOfAcquisition = 1" 
    # "endOfAcquisitionMode = 1" 
    # "dcOverVoltage = 0" 
    # "epoch = [  12  0 18514 60545 32 47.176]" 
    # [...]
    desc = ScanImageTiffReader.open(filename) do io
        split(description(io, 1), "\n")
    end
    @test desc[1] == "frameNumbers = 1"
    @test desc[2] == "acquisitionNumbers = 1"
    @test desc[3] == "frameNumberAcquisition = 1"
    @test desc[4] == "frameTimestamps_sec = 0.000000000"
    @test desc[5] == "acqTriggerTimestamps_sec = 0.000000000"
    @test desc[6] == "nextFileMarkerTimestamps_sec = -1.000000000"
    @test desc[7] == "endOfAcquisition = 1"
    @test desc[8] == "endOfAcquisitionMode = 1"
    @test desc[9] == "dcOverVoltage = 0"
    @test desc[10] == "epoch = [  12  0 18514 60545 32 47.176]"

    # $ ScanImageTiffReader metadata single_image_si.tif
    # SI.LINE_FORMAT_VERSION = 1 
    # SI.TIFF_FORMAT_VERSION = 3 
    # SI.VERSION_COMMIT = '4a32c3beef986466d0828dc41806ed4f0abe494f' 
    # SI.VERSION_MAJOR = '2018a' 
    # SI.VERSION_MINOR = '0' 
    # SI.acqState = 'grab' 
    # SI.acqsPerLoop = 1 
    # SI.extTrigEnable = false 
    # SI.hBeams.beamCalibratedStatus = false 
    # SI.hBeams.directMode = false 
    # [...]
    # didn't parse for one reason or another...
    md = ScanImageTiffReader.open(filename) do io
        split(metadata(io), "\n")
    end
    @test md[1] == "SI.LINE_FORMAT_VERSION = 1"
    @test md[2] == "SI.TIFF_FORMAT_VERSION = 3"
    @test md[3] == "SI.VERSION_COMMIT = '4a32c3beef986466d0828dc41806ed4f0abe494f'"
    @test md[4] == "SI.VERSION_MAJOR = '2018a'"
    @test md[5] == "SI.VERSION_MINOR = '0'"
    @test md[6] == "SI.acqState = 'grab'"
    @test md[7] == "SI.acqsPerLoop = 1"
    @test md[8] == "SI.extTrigEnable = false"
    @test md[9] == "SI.hBeams.beamCalibratedStatus = false"
    @test md[10] == "SI.hBeams.directMode = false"
end
