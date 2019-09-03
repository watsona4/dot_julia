using StanSamples, Test

import StanSamples: # test internals
    iscommentline, fields, ColVar, combined_size, StanVar, StanScalar, StanArray,
    combine_colvars, empty_values, ncols, empty_vars_values, _read_values, read_values

@testset "raw reading" begin
    @test iscommentline("# this is a comment")
    @test iscommentline(" # this is a comment")
    @test iscommentline("#")
    @test !iscommentline("fly in the ointment #")
    @test !iscommentline("99,12")
    @test !iscommentline("99,12#comment")
    @test fields("a,b,c") == ["a","b","c"]
    @test fields("") == [""] # corner cases, should not appear in a CSV produced by CmdStan
    @test fields(",") == ["",""]
end

@testset "parsing variable names" begin
    @test ColVar("a") == ColVar(:a)
    @test ColVar("b99") == ColVar(:b99)
    @test ColVar("accept_stat__") == ColVar(:accept_stat__)
    @test ColVar("a.1.2.3") == ColVar(:a, 1, 2, 3)
    @test_throws ArgumentError ColVar("a.foo")
    @test_throws ArgumentError ColVar("a.0")
    @test_throws ArgumentError ColVar("a.0.")
end

@testset "combined size" begin
    @test combined_size([CartesianIndex((i,)) for i in 1:3]) == (3,)
    @test combined_size(vec([CartesianIndex((i,j))
                             for i in 1:3, j in 1:4])) == (3,4)
    @test_throws ArgumentError combined_size([CartesianIndex((i,)) for i in [1,3]])
    @test_throws ArgumentError combined_size([CartesianIndex((i,)) for i in [2,1]])
end

@testset "parsing header" begin
    let h = ColVar.([:a, :b, :c])
        @test combine_colvars(h) == StanScalar.((:a, :b, :c))
    end
    @test combine_colvars(ColVar.(["a", "b.1", "b.2", "c"])) ==
        (StanScalar(:a), StanArray(:b, (2,)), StanScalar(:c))
    @test combine_colvars(ColVar.(["a", "b.1.1", "b.2.1", "b.1.2", "b.2.2", "c"])) ==
        (StanScalar(:a), StanArray(:b, (2, 2)), StanScalar(:c))
    @test_throws ArgumentError combine_colvars(ColVar.(["a", "b.1", "b.2.1", "c"]))
end

@testset "variable types" begin
    a = StanScalar(:A)
    b, c, d = [StanArray(arg...) for arg in [(:B,2), (:C,2,3), (:D,2,3,5)]]
    @test empty_values(a) == Vector{Float64}()
    @test ncols(a) == 1
    @test empty_values(b) == Matrix{Float64}(undef, 2, 0)
    @test ncols(b) == 2
    @test empty_values(c) == Array{Float64,3}(undef, 2, 3, 0)
    @test ncols(c) == 6
    @test empty_values(d) == Array{Float64,4}(undef, 2, 3, 5, 0)
    @test ncols(d) == 30
end

@testset "empty var named tuple" begin
    vars = (StanScalar(:A), StanArray(:B,1), StanArray(:C,1,2), StanArray(:D,1,2,3))
    @test empty_vars_values(vars) == (A = Vector{Float64}(),
                                      B = Matrix{Float64}(undef, 1, 0),
                                      C = Array{Float64,3}(undef, 1, 2, 0),
                                      D = Array{Float64,4}(undef, 1, 2, 3, 0))
end

@testset "_read_values" begin
    @test _read_values(StanScalar(:a), [1.0]) == 1.0
    @test _read_values(StanArray(:a,2), [1.0, 2.0]) == [1.0, 2.0]
    @test _read_values(StanArray(:a,2,2), 1.0:4.0) == [1.0 3.0; 2.0 4.0]
    @test_throws BoundsError _read_values(StanArray(:a, 9), 1.0:4.0)
end

@testset "read values" begin
    # line with values
    io = IOBuffer("""
1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0
  # next line is too long, one after that is incomplete, then unparsable
1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0
1.0,2.0,3.0,4.0,5.0,6.0,7.0
1.0,foo,3.0,4.0,5.0,6.0,7.0,8.0
""")
    vars = (StanScalar(:a), StanArray(:b, 3), StanArray(:c, 2, 2))
    @test sum(ncols, vars) == 8
    vars_values = empty_vars_values(vars)
    buffer = Vector{Float64}(undef, sum(ncols, vars))
    @test read_values(io, vars, vars_values, buffer)
    @test vars_values == (a = [1.0], b = reshape(Float64.(2:4), 3, 1),
                          c = reshape(Float64.(5:8), 2, 2, 1))
    # comment line
    @test !read_values(io, vars, vars_values, buffer)
    # line too long
    @test_throws DimensionMismatch read_values(io, vars, vars_values, buffer)
    # incomplete line
    @test_throws DimensionMismatch read_values(io, vars, vars_values, buffer)
    # parser error
    @test_throws ArgumentError read_values(io, vars, vars_values, buffer)
end

@testset "read samples simple" begin
    io = IOBuffer("""
a,b.1,b.2,c.1.1,c.2.1,c.1.2,c.2.2
1.0,2.0,3.0,4.0,5.0,6.0,7.0
8.0,9.0,10.0,11.0,12.0,13.0,14.0
""")
    samples = read_samples(io)
    @test samples.a == [1.0, 8.0]
    @test samples.b == permutedims([2.0 3.0;
                                    9.0 10.0])
    @test size(samples.c) == (2, 2, 2)
    @test vec(samples.c) == Float64.(vcat(4:7, 11:14))
end

@testset "read samples large" begin
    samples = read_samples(joinpath(@__DIR__, "testmodel", "test-samples-1.csv"))
    scalar_vars = [:lp__,:accept_stat__,:stepsize__,:treedepth__,:n_leapfrog__,
                   :divergent__,:energy__,:mu,:sigma, :nu]
    @test Set(keys(samples)) == Set(vcat(scalar_vars, :alpha))
    N = 1000                    # hardcoded
    for v in scalar_vars
        @test isa(samples[v], Vector{Float64})
        @test length(samples[v]) == N
    end
    α = samples[:alpha]
    @test isa(α, AbstractArray{Float64,3})
    @test size(α) == (3, 5, N)
end

@testset "empty file (no header)" begin
    mktemp() do path, io
        write(io, """
# empty file
# just comments
""")
        @test_throws ErrorException read_samples(path)
    end
end
