
@testset "test shortest path" begin
    errcode, path = dubins_shortest_path(zeros(3), [1.0, 0.0, 0.0], 1.0)
    @test errcode == EDUBOK
end

@testset "test invalid ρ" begin
    errcode, path = dubins_shortest_path(zeros(3), [1.0, 0.0, 0.0], -1.0)
    @test errcode == EDUBBADRHO
    @test path == nothing
end

@testset "test no path" begin
    errcode, path = dubins_path(zeros(3), [10.0, 0.0, 0.0], 1.0, LRL)
    @test errcode == EDUBNOPATH
    @test path == nothing
end

@testset "test path length" begin
    errcode, path = dubins_shortest_path(zeros(3), [4.0, 0.0, 0.0], 1.0)
    @test errcode == EDUBOK
    path_length = dubins_path_length(path)
    @test isapprox(path_length, 4., atol=1e-3)
end

@testset "test simple path" begin
    errcode, path = dubins_path(zeros(3), [1.0, 0.0, 0.0], 1.0, LSL)
    @test errcode == EDUBOK
end

@testset "test segment lengths" begin
    errcode, path = dubins_path(zeros(3), [4.0, 0.0, 0.0], 1.0, LSL)
    @test errcode == EDUBOK
    @test dubins_segment_length_normalized(path, 0) == Inf
    @test dubins_segment_length_normalized(path, 1) == 0.0
    @test dubins_segment_length_normalized(path, 2) == 4.0
    @test dubins_segment_length_normalized(path, 3) == 0.0
    @test dubins_segment_length_normalized(path, 4) == Inf
end

@testset "test sample" begin
    errcode, path = dubins_path(zeros(3), [4.0, 0.0, 0.], 1.0, LSL)
    @test errcode == EDUBOK

    errcode, qsamp = dubins_path_sample(path, 0.0)
    @test errcode == EDUBOK
    @test qsamp == zeros(3)

    errcode, qsamp = dubins_path_sample(path, 4.0)
    @test errcode == EDUBOK
    @test qsamp == [4.0, 0.0, 0.0]
end

@testset "test sample out of bounds" begin
    errcode, path = dubins_path(zeros(3), [4.0, 0.0, 0.0], 1.0, LSL)
    @test errcode == EDUBOK

    errcode, qsamp = dubins_path_sample(path, -1.0)
    @test errcode == EDUBPARAM
    @test qsamp == nothing

    errcode, qsamp = dubins_path_sample(path, 5.0)
    @test errcode == EDUBPARAM
    @test qsamp == nothing
end

@testset "test sample many LSL" begin
    errcode, path = dubins_path([0.0, 0.0, π/2], [4.0, 0.0, -π/2], 1.0, LSL)
    @test errcode == EDUBOK

    errcode, configurations = dubins_path_sample_many(path, 1.0)
    @test errcode == 0
    @test isapprox(configurations[1], [0.0, 0.0, π/2], atol=1e-8)
end

@testset "test sample many RLR" begin
    errcode, path = dubins_path([0.0, 0.0, π/2], [4.0, 0.0, -π/2], 1.0, RLR)
    @test errcode == EDUBOK

    errcode, configurations = dubins_path_sample_many(path, 1.0)
    @test errcode == 0
    @test isapprox(configurations[1], [0.0, 0.0, π/2], atol=1e-8)
end

@testset "test path type" begin
    for i in 0:5
        path_type::DubinsPathType = (DubinsPathType)(i)
        errcode, path = dubins_path(zeros(3), [1.0, 0.0, 0.0], 1.0, path_type)
        (errcode == EDUBOK) && (@test dubins_path_type(path) == path_type)
    end
end

@testset "test end point" begin
    errcode, path = dubins_path(zeros(3), [4.0, 0.0, 0.0], 1.0, LSL)
    @test errcode == EDUBOK

    errcode, qsamp = dubins_path_endpoint(path)
    @test isapprox(qsamp, [4.0, 0.0, 0.0], atol=1e-8)
end

@testset "test extract sub-path" begin
    errcode, path = dubins_path(zeros(3), [4.0, 0.0, 0.0], 1.0, LSL)
    @test errcode == EDUBOK

    errcode, subpath = dubins_extract_subpath(path, 2.0)
    @test errcode == EDUBOK

    errcode, qsamp = dubins_path_endpoint(subpath)
    @test isapprox(qsamp, [2.0, 0.0, 0.0], atol=1e-8)
end

@testset "test extract invalid sub-path" begin
    errcode, path = dubins_path(zeros(3), [4.0, 0.0, 0.0], 1.0, LSL)
    @test errcode == EDUBOK

    errcode, subpath = dubins_extract_subpath(path, 8.0)
    @test errcode == EDUBPARAM
    @test subpath == nothing
end
