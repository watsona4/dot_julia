using Test
using NIRX
using DataDeps
using HDF5

## Register useful data dependencies

register(DataDep("NIRX test file 1", "Single fNIRS experiment recording",
    ["https://s3.amazonaws.com/test.robertluke.net/fNIRS-test-data.zip"];
    post_fetch_method = [file->run(`unzip $file`)]
))

register(DataDep("NIRX results file 1", "Single fNIRS experiment recording",
    ["https://s3.amazonaws.com/test.robertluke.net/fNIRS-test-data.h5.zip"];
    post_fetch_method = [file->run(`unzip $file`)]
))


## Read example NIRX file and test basic sizes of what is returned

triggers, header_info, info, wl1, wl2, config = read_NIRX(string(datadep"NIRX test file 1", "/fNIRS-test-data"))

@test size(triggers) == (62, 2)
@test length(header_info) == 23
@test length(info) == 7
@test size(wl1) == (7008, 256)
@test size(wl2) == (7008, 256)
@test length(config) == 10


# Read known results for wavelengths 1 and 2 and check values

wl1_true = h5read(string(datadep"NIRX results file 1", "/fNIRS-test-data.h5"), "wl1")
wl2_true = h5read(string(datadep"NIRX results file 1", "/fNIRS-test-data.h5"), "wl2")
tri_true = h5read(string(datadep"NIRX results file 1", "/fNIRS-test-data.h5"), "triggers")

@test wl1[:, Bool.(header_info["SourceDetectorMask"][:, 4])] == wl1_true
@test wl2[:, Bool.(header_info["SourceDetectorMask"][:, 4])] == wl2_true
@test triggers == tri_true

# Test types of returned info
@test isa(info["Name"], String)
@test isa(info["Age"], Number)
@test isa(info["Gender"], String)
@test isa(info["Contact Information"], String)
@test isa(info["Study Type"], String)
@test isa(info["Experiment History"], String)
@test isa(info["Additional Notes"], String)
@test info["Name"] == "Rob"
@test info["Age"] == 32
@test info["Gender"] == ""
@test info["Contact Information"] == ""
@test info["Study Type"] == "Tapping"
@test info["Experiment History"] == ""
@test info["Additional Notes"] == "Participant 3"

