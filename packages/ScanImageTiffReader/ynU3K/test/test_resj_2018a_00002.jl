@testset "resj_2018a_00002.tif" begin
filename = joinpath(testbase, "resj_2018a_00002.tif")
    # $ ScanImageTiffReader image shape resj_2018a_00002.tif
    # Shape: 1024 x 1024 x 5 @ i16
    tsize = ScanImageTiffReader.open(filename) do io
        size(io)
    end
    @test tsize == (1024, 1024, 5)
    ttype = ScanImageTiffReader.open(filename) do io
        pxtype(io)
    end
    @test ttype == Int16

    # $ ScanImageTiffReader image bytes resj_2018a_00002.tif
    # 10 MB
    dat = ScanImageTiffReader.open(filename) do io
        data(io)
    end
    @test abs(sizeof(dat)/2^20 - 10.0) < 1e-5
    # @test ScanImageTiffReader.open(filename, length) == size(dat, 3) # TODO: check this assumption

    # $ ScanImageTiffReader descriptions --frame 0 resj_2018a_00002.tif
    # "{" 
    # "  "frameNumbers": 1," 
    # "  "acquisitionNumbers": 1," 
    # "  "frameNumberAcquisition": 1," 
    # "  "frameTimestamps_sec": 0.000000000," 
    # "  "acqTriggerTimestamps_sec": -0.000087000," 
    # "  "nextFileMarkerTimestamps_sec": -1.000000000," 
    # "  "endOfAcquisition": 0," 
    # "  "endOfAcquisitionMode": 0," 
    # "  "dcOverVoltage": 0," 
    # [...]
    desc = ScanImageTiffReader.open(filename) do io
        split(description(io, 1), "\n")
    end
    @test desc[1] == "{"
    @test desc[2] == "  \"frameNumbers\": 1,"
    @test desc[3] == "  \"acquisitionNumbers\": 1,"
    @test desc[4] == "  \"frameNumberAcquisition\": 1,"
    @test desc[5] == "  \"frameTimestamps_sec\": 0.000000000,"
    @test desc[6] == "  \"acqTriggerTimestamps_sec\": -0.000087000,"
    @test desc[7] == "  \"nextFileMarkerTimestamps_sec\": -1.000000000,"
    @test desc[8] == "  \"endOfAcquisition\": 0,"
    @test desc[9] == "  \"endOfAcquisitionMode\": 0,"
    @test desc[10] == "  \"dcOverVoltage\": 0,"

    # $ ScanImageTiffReader metadata resj_2018a_00002.tif
    # { 
    #   "SI": { 
    #     "LINE_FORMAT_VERSION": 1, 
    #     "TIFF_FORMAT_VERSION": 3, 
    #     "VERSION_COMMIT": "3cb14551ff2a74fc2cf001207f1cafb10231ea2f", 
    #     "VERSION_MAJOR": "2018a", 
    #     "VERSION_MINOR": "0", 
    #     "acqState": "grab", 
    #     "acqsPerLoop": 1, 
    #     "extTrigEnable": 0, 
    # [...]
    md = ScanImageTiffReader.open(filename) do io
        JSON.parse(metadata(io))
    end
    # only descend two levels...
    @test md["SI"]["imagingSystem"] == "ResScanner"
    @test md["SI"]["acqState"] == "grab"
    @test md["SI"]["VERSION_COMMIT"] == "3cb14551ff2a74fc2cf001207f1cafb10231ea2f"
    @test md["SI"]["loopAcqInterval"] == 10
    @test md["SI"]["VERSION_MINOR"] == "0"
    @test md["SI"]["extTrigEnable"] == 0
    @test md["SI"]["TIFF_FORMAT_VERSION"] == 3
    @test md["SI"]["LINE_FORMAT_VERSION"] == 1
    @test md["SI"]["acqsPerLoop"] == 1
    @test md["SI"]["VERSION_MAJOR"] == "2018a"
    @test md["SI"]["objectiveResolution"] == 59.7425
    @test md["RoiGroups"]["photostimRoiGroups"] == nothing
end
