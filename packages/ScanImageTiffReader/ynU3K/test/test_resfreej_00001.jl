@testset "resfreej_00001.tif" begin
filename = joinpath(testbase, "resfreej_00001.tif")
    # $ ScanImageTiffReader image shape resfreej_00001.tif
    # Shape: 512 x 512 x 10 @ i16
    tsize = ScanImageTiffReader.open(filename) do io
        size(io)
    end
    @test tsize == (512, 512, 10)
    ttype = ScanImageTiffReader.open(filename) do io
        pxtype(io)
    end
    @test ttype == Int16

    # $ ScanImageTiffReader image bytes resfreej_00001.tif
    # 5 MB
    dat = ScanImageTiffReader.open(filename) do io
        data(io)
    end
    @test abs(sizeof(dat)/2^20 - 5.0) < 1e-5
    # @test ScanImageTiffReader.open(filename, length) == size(dat, 3) # TODO: check this assumption

    # $ ScanImageTiffReader descriptions --frame 0 resfreej_00001.tif
    # "frameNumbers = 1" 
    # "acquisitionNumbers = 1" 
    # "frameNumberAcquisition = 1" 
    # "frameTimestamps_sec = 0.000000000" 
    # "acqTriggerTimestamps_sec = 0.000000000" 
    # "nextFileMarkerTimestamps_sec = -1.000000000" 
    # "endOfAcquisition = 0" 
    # "endOfAcquisitionMode = 0" 
    # "dcOverVoltage = 0" 
    # "epoch = [1601  1  1  0  0 25.045]" 
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
    @test desc[7] == "endOfAcquisition = 0"
    @test desc[8] == "endOfAcquisitionMode = 0"
    @test desc[9] == "dcOverVoltage = 0"
    @test desc[10] == "epoch = [1601  1  1  0  0 25.045]"

    # $ ScanImageTiffReader metadata resfreej_00001.tif
    # { 
    #   "SI": { 
    #     "TIFF_FORMAT_VERSION": 3, 
    #     "VERSION_MAJOR": "2015", 
    #     "VERSION_MINOR": "4", 
    #     "acqState": "grab", 
    #     "acqsPerLoop": 1, 
    #     "extTrigEnable": 0, 
    #     "hBeams": { 
    #       "beamCalibratedStatus": [0,0,0], 
    # [...]
    # didn't parse for one reason or another...
    md = ScanImageTiffReader.open(filename) do io
        split(metadata(io), "\n")
    end
    @test md[1] == "{"
    @test md[2] == "  \"SI\": {"
    @test md[3] == "    \"TIFF_FORMAT_VERSION\": 3,"
    @test md[4] == "    \"VERSION_MAJOR\": \"2015\","
    @test md[5] == "    \"VERSION_MINOR\": \"4\","
    @test md[6] == "    \"acqState\": \"grab\","
    @test md[7] == "    \"acqsPerLoop\": 1,"
    @test md[8] == "    \"extTrigEnable\": 0,"
    @test md[9] == "    \"hBeams\": {"
    @test md[10] == "      \"beamCalibratedStatus\": [0,0,0],"
end
