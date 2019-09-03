@testset "linfree_00001.tif" begin
filename = joinpath(testbase, "linfree_00001.tif")
    # $ ScanImageTiffReader image shape linfree_00001.tif
    # Shape: 512 x 512 x 10 @ i16
    tsize = ScanImageTiffReader.open(filename) do io
        size(io)
    end
    @test tsize == (512, 512, 10)
    ttype = ScanImageTiffReader.open(filename) do io
        pxtype(io)
    end
    @test ttype == Int16

    # $ ScanImageTiffReader image bytes linfree_00001.tif
    # 5 MB
    dat = ScanImageTiffReader.open(filename) do io
        data(io)
    end
    @test abs(sizeof(dat)/2^20 - 5.0) < 1e-5
    # @test ScanImageTiffReader.open(filename, length) == size(dat, 3) # TODO: check this assumption

    # $ ScanImageTiffReader descriptions --frame 0 linfree_00001.tif
    # "frameNumbers = 1" 
    # "acquisitionNumbers = 1" 
    # "frameNumberAcquisition = 1" 
    # "frameTimestamps_sec = 0.000000" 
    # "acqTriggerTimestamps_sec = " 
    # "nextFileMarkerTimestamps_sec = " 
    # "endOfAcquisition =  0" 
    # "endOfAcquisitionMode = 0" 
    # "dcOverVoltage = 0" 
    # "epoch = [2016 6 4 13 52 6.7667]" 
    desc = ScanImageTiffReader.open(filename) do io
        split(description(io, 1), "\n")
    end
    @test desc[1] == "frameNumbers = 1"
    @test desc[2] == "acquisitionNumbers = 1"
    @test desc[3] == "frameNumberAcquisition = 1"
    @test desc[4] == "frameTimestamps_sec = 0.000000"
    @test desc[5] == "acqTriggerTimestamps_sec = "
    @test desc[6] == "nextFileMarkerTimestamps_sec = "
    @test desc[7] == "endOfAcquisition =  0"
    @test desc[8] == "endOfAcquisitionMode = 0"
    @test desc[9] == "dcOverVoltage = 0"
    @test desc[10] == "epoch = [2016 6 4 13 52 6.7667]"

    # $ ScanImageTiffReader metadata linfree_00001.tif
    # SI.TIFF_FORMAT_VERSION = 3 
    # SI.VERSION_MAJOR = '2015' 
    # SI.VERSION_MINOR = '4' 
    # SI.acqState = 'grab' 
    # SI.acqsPerLoop = 1 
    # SI.extTrigEnable = false 
    # SI.hBeams.beamCalibratedStatus = [false false false] 
    # SI.hBeams.beamStatus = [0 0 0] 
    # SI.hBeams.directMode = [false false false] 
    # SI.hBeams.enablePowerBox = false 
    # [...]
    # didn't parse for one reason or another...
    md = ScanImageTiffReader.open(filename) do io
        split(metadata(io), "\n")
    end
    @test md[1] == "SI.TIFF_FORMAT_VERSION = 3"
    @test md[2] == "SI.VERSION_MAJOR = '2015'"
    @test md[3] == "SI.VERSION_MINOR = '4'"
    @test md[4] == "SI.acqState = 'grab'"
    @test md[5] == "SI.acqsPerLoop = 1"
    @test md[6] == "SI.extTrigEnable = false"
    @test md[7] == "SI.hBeams.beamCalibratedStatus = [false false false]"
    @test md[8] == "SI.hBeams.beamStatus = [0 0 0]"
    @test md[9] == "SI.hBeams.directMode = [false false false]"
    @test md[10] == "SI.hBeams.enablePowerBox = false"
end
