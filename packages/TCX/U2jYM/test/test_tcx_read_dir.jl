using Test

@testset "TESTSETS: Test read TCX dir" begin
    @testset "CASE: Test dir with NO TCX file" begin
	err, _ =  TCX.parse_tcx_dir(tempdir())
        @test err == 404
    end

    @testset "CASE: Test dir with TCX file" begin
        err, _ =  TCX.parse_tcx_dir(@__DIR__)
        @test err == 200
    end

    @testset "CASE: Test relative dir with TCX file" begin
        err, _ =  TCX.parse_tcx_dir(".")
        @test err == 200
    end
    @testset "CASE: Test DataFrame after process dir" begin
        err, ta =  TCX.parse_tcx_dir(".")
        @test (err == 200) & (size(getDataFrame(ta), 1) == 9273)
    end
end

