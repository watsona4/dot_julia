using DeIdentification
using CSV
using YAML
using DataFrames
using Dates
using Memento

using Test

# SET UP COMMON TEST VARIABLES AND ENVIRONMENT
test_file = "ehr_data.yml"
test_file_batch= "ehr_data_batch.yml"
logpath = joinpath(@__DIR__, "logs")
outputpath = joinpath(@__DIR__, "output")
basepath_not_created = joinpath(@__DIR__, "path")
logpath_not_created = joinpath(basepath_not_created, "to", "new", "logs")
outputpath_not_created = joinpath(basepath_not_created, "to", "new", "output")

try
    isdir(logpath) && rm(logpath, recursive=true, force=true)
catch
end

try
    isdir(outputpath) && rm(outputpath, recursive=true, force=true)
catch
end

try
    isdir(basepath_not_created) && rm(basepath_not_created, recursive=true, force=true)
catch
end

mkpath(logpath)
mkpath(outputpath)
# ----------------------------

@testset "config creation" begin
    cfg_raw = YAML.load_file(test_file)

    # nominally check YAML loading worked
    @test cfg_raw["project"] == "ehr"

    cfg = ProjectConfig(test_file)

    @test cfg_raw["project"] == cfg.name
    @test cfg_raw["datasets"][1]["name"] == cfg.file_configs[1].name
end

@testset "create config from csv" begin
    config_file = joinpath(@__DIR__, "example_config.yml")
    try
        build_config_from_csv("example_config", joinpath(@__DIR__, "data_worksheet_fields.csv"))

        config_raw = YAML.load_file(config_file)
        @test config_raw["project"] == "example_config"
        @test length(config_raw["datasets"]) == 11
    finally
        if isfile(config_file)
            try
                rm(config_file)
            catch
            end
        end
    end
end

@testset "rid generation" begin
    ids1 = [4, 6, 7, 3, 3, 5, 7]
    ids2 = [6, 5, 3, 4, 5]

    # Check hashing and research ID generation
    dicts = DeIdDicts(30, 100)
    hash1 = map( x-> DeIdentification.getoutput(dicts, DeIdentification.Hash, x, 0), ids1)
    hash2 = map( x-> DeIdentification.getoutput(dicts, DeIdentification.Hash, x, 0), ids2)

    rid1 = map( x-> DeIdentification.setrid(x, dicts), hash1)
    rid2 = map( x-> DeIdentification.setrid(x, dicts), hash2)

    @test rid1 == [1, 2, 3, 4, 4, 5, 3]
    @test rid2 == [2, 5, 4, 1, 5]
end


@testset "integration tests" begin
    proj_config = ProjectConfig(test_file)
    proj_config_batch = ProjectConfig(test_file_batch)
    deid = deidentify(proj_config)

    @test typeof(deid) == DeIdDicts

    @test isfile(joinpath(logpath,"ehr.log.0001"))

    dx = false
    salts = false
    df = DataFrame()
    df_pat = DataFrame()
    for (root, dirs, files) in walkdir(outputpath)
        for file in files
            if occursin(r"^deid_dx_.*csv", file)
                dx = true
                df = CSV.read(joinpath(root,file))
            elseif occursin(r"deid_pat_.*csv", file)
                df_pat = CSV.read(joinpath(root,file))
            elseif occursin(r"salts_.*json", file)
                salts = true
            end
        end
    end

    dfo = CSV.read(joinpath(@__DIR__, "data", "dx.csv"))

    # test column name change
    @test in(:EncounterBrownCSN, getfield(getfield(dfo, :colindex),:names))
    @test in(:CSN, getfield(getfield(df, :colindex),:names))

    # test that hash column was hashed
    @test length(df[1, :PatientPrimaryMRN]) == 64

    # test that dropped column was dropped
    @test in(:DiagnosisTerminologyType, getfield(getfield(dfo, :colindex),:names))
    @test !in(:DiagnosisTerminologyType, getfield(getfield(df, :colindex),:names))

    # test that dateshifted column was dateshifted
    @test df[1,:ArrivalDateandTime] != dfo[1,:ArrivalDateandTime]
    @test Dates.days(abs(df[1,:ArrivalDateandTime] - dfo[1,:ArrivalDateandTime])) <= proj_config.maxdays + Dates.days(Dates.Year(proj_config.shiftyears))
    @test isapprox(Dates.days(abs(df[1,:ArrivalDateandTime] - dfo[1,:ArrivalDateandTime]))/365, proj_config.shiftyears, atol = 1.0)

    # test the transforms work
    @test length(string(df_pat[1,:PatientBirthDate])) == 4

    # test that files were created as expected
    @test dx == true
    @test salts == true

    # test that when config has glob pattern in file name, ProjectConfig gets all files in directory.
    @test length(proj_config_batch.file_configs) == 9
    @test split(proj_config_batch.file_configs[3].filename, Sys.iswindows() ? "\\" : "/")[end] == "dx_2.csv"
end

@testset "primary identifiter" begin
    cfg = ProjectConfig("ehr_data_bad_pk.yml")

    @test_throws AssertionError deidentify(cfg)
end

@testset "hash seeding" begin
    cfg1 = ProjectConfig(test_file)
    cfg2 = ProjectConfig("ehr_data_alt_seed.yml")

    deid1 = deidentify(cfg1)
    deid1a = deidentify(cfg1)
    deid2 = deidentify(cfg2)

    @test deid1.salt == deid1a.salt
    @test deid1.salt != deid2.salt
end

@testset "create output directories" begin
    cfg = ProjectConfig("ehr_data_alt_paths.yml")
    deid = deidentify(cfg)

    @test isfile(joinpath(logpath_not_created,"ehr.log.0001"))
    @test isdir(joinpath(outputpath_not_created))
end

# TEAR DOWN
# this is necessary to ensure directories are deleted on Windows
GC.gc()

try
    rm(logpath, recursive=true, force=true)
catch
end

try
    rm(outputpath, recursive=true, force=true)
catch
end

try
    rm(joinpath(@__DIR__, "path"), recursive=true, force=true)
catch
end
# --------------------------
