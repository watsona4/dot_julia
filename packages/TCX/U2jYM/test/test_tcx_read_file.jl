using Test

gpx_sample_file2=joinpath(@__DIR__, gpx_sample_file)
tcx_sample_file2=joinpath(@__DIR__, tcx_sample_file)
tcx_centrypark_run_file2=joinpath(@__DIR__, tcx_centrypark_run_file)
tcx_treadmill_run_file2=joinpath(@__DIR__, tcx_treadmill_run_file)

@testset "TESTSETS: Test read TCX file" begin
    @testset "CASE: Test file not XML" begin
        err, data =  TCX.parse_tcx_file(joinpath(@__DIR__, "runtests.jl"))
        @test err == 400
    end

    @testset "CASE: Test file not exists" begin
        err, data =  TCX.parse_tcx_file("non-existing-file.tcx")
        @test err == 404
    end

    @testset "CASE: Test file exist but not a TCX file" begin
        err, _ =  TCX.parse_tcx_file(gpx_sample_file2)
        @test err == 400
    end

    @testset "CASE: Test a TCX records run." begin
        err, data =  TCX.parse_tcx_file(tcx_sample_file2)
        @test (err == 200) & (getActivityType(data) == "Running")
    end

    @testset "CASE: Test a TCX contains track points." begin
        err, data =  TCX.parse_tcx_file(tcx_sample_file2)
        @test (err == 200) & (size(getDataFrame(data), 1) == 3427)
    end

    @testset "CASE: Test a TCX treadmill run, no logitude/latitude." begin
        err, data =  TCX.parse_tcx_file(tcx_treadmill_run_file2)
        @test (err == 200) & (getDistance2(data) == 0)
    end

    @testset "CASE: Test a TCX static running distance." begin
        err, data =  TCX.parse_tcx_file(tcx_centrypark_run_file2)
        @test (err == 200) & (getDistance(data) == 27020)
    end

    @testset "CASE: Test a TCX running distance from Geodesy." begin
        err, data =  TCX.parse_tcx_file(tcx_centrypark_run_file2)
        @test (err == 200) & (getDistance2(data) > 0)
    end

    @testset "CASE: Test a TCX static average pace." begin
        err, data =  TCX.parse_tcx_file(tcx_centrypark_run_file2)
        @test (err == 200) & (getAveragePace(data) > 0 )
    end

    @testset "CASE: Test to get TCX duration." begin
        err, data =  TCX.parse_tcx_file(tcx_centrypark_run_file2)
        @test (err == 200) & (getDuration(data) > 0 )
    end
end

