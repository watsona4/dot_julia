using CacheVariables, BSON, Test

## Add data directory, define data file path
dirpath = joinpath(@__DIR__, "data")
isdir(dirpath) && rm(dirpath; recursive=true)
mkdir(dirpath)
path = joinpath(dirpath, "test.bson")

## Test save functionality
@testset "Save" begin
    # 1. verify log message
    @test_logs (:info, "Saving to $path\nx\ny\nz") (@cache path begin
        x = collect(1:3)
        y = 4
        z = "test"
	"final output"
    end)

    rm(path)
    out = @cache path begin
        x = collect(1:3)
        y = 4
        z = "test"
	"final output"
    end

    # 3. did variables enter workspace correctly?
    @test x == [1, 2, 3]
    @test y == 4
    @test z == "test"
    @test out == "final output"
end

## Test load functionality
@testset "Load" begin
    # 1. set all variables to nothing
    x = nothing
    y = nothing
    z = nothing
    out = nothing

    # 2. file exists: load variables from it
    # verify log message
    @test_logs (:info, "Loading from $path\nx\ny\nz") (@cache path begin
        x = collect(1:3)
        y = 4
        z = "test"
	"final output"
    end)

    # load variables
    out = @cache path begin
        x = collect(1:3)
        y = 4
        z = "test"
	"final output"
    end

    # 3. did variables enter workspace correctly?
    @test x == [1, 2, 3]
    @test y == 4
    @test z == "test"
    @test out == "final output"
end

## Test overwrite behavior
@testset "Overwrite" begin
    # 1. change file contents
    bson(path; x=nothing, y=nothing, z=nothing, ans=nothing)

    # 2. add `true` to @cache call to overwrite
    # validate log message
    @test_logs (:info, "Overwriting $path\nx\ny\nz") (@cache path begin
        x = collect(1:3)
        y = 4
        z = "test"
	"final output"
    end true)

    # overwrite data file
    overwrite = true
    @cache path begin
        x = collect(1:3)
        y = 4
        z = "test"
	"final output"
    end overwrite

    # 3. check that correct data was overwritten
    x = nothing
    y = nothing
    z = nothing
    out = nothing
    out = @cache path begin
        x = collect(1:3)
        y = 4
        z = "test"
	"final output"
    end

    @test x == [1, 2, 3]
    @test y == 4
    @test z == "test"
    @test out == "final output"
end

## Clean up
rm(dirpath; recursive=true)
