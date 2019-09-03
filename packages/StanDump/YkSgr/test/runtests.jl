using StanDump, Test

using StanDump: dump, _dump, StanDumpIO

function stanrepr(x, internal = false; options...)
    io = IOBuffer()
    sd = StanDumpIO(io ; options...)
    (internal ? _dump : dump)(sd, x)
    String(take!(sd.io))
end

@testset "integer" begin
    @test stanrepr(1) == "1"
    @test stanrepr(typemax(Int32)+1) == string(typemax(Int32)+1) * "L"
    @test stanrepr(-99) == "-99"
    @test_throws ArgumentError stanrepr(BigInt(typemax(Int64))+1, true)
end

@testset "float" begin
    @test stanrepr(1/7) == string(1/7)
    @test stanrepr(-pi) == string(Float64(-pi))
    @test stanrepr(Inf) == "Inf"
    @test stanrepr(-Inf) == "-Inf"
    @test stanrepr(Inf32) == "Inf"
    @test stanrepr(-Inf32) == "-Inf"
    @test stanrepr(NaN) == "NaN"
    @test stanrepr(1//2) == "0.5"
end

@testset "unhandled" begin
    @test_throws ArgumentError stanrepr(:s)      # standalone symbol
    @test_throws ArgumentError stanrepr(nothing) # unknown type
    @test_throws ArgumentError stanrepr(:s__ => 1) # invalid name
    @test_throws ArgumentError stanrepr(Symbol("1s") => 1) # invalid name
end

@testset "definition and formatting" begin
    _repr(x; kwargs...) = stanrepr(x, true; kwargs...)
    @test _repr(:A => 99) == "A <- 99\n" # defaults
    # non-compact
    @test _repr(:A => 99; def_arrow = false, def_newline = false, compact = false) ==
        "A = 99\n" # same as above
    @test _repr(:A => 99; def_arrow = true, def_newline = false, compact = false) ==
        "A <- 99\n"
    @test _repr(:A => 99; def_arrow = false, def_newline = true, compact = false) ==
        "A =\n99\n"
    @test _repr(:A => 99; def_arrow = true, def_newline = true, compact = false) ==
        "A <-\n99\n"
    # compact
    @test _repr(:A => 99; def_arrow = false, def_newline = false, compact = true) ==
        "A=99\n"
    @test _repr(:A => 99; def_arrow = true, def_newline = false, compact = true) ==
        "A<-99\n"
    @test _repr(:A => 99; def_arrow = false, def_newline = true, compact = true) ==
        "A=\n99\n" # same as above
    @test _repr(:A => 99; def_arrow = true, def_newline = true, compact = true) ==
        "A<-\n99\n"
end

@testset "vector" begin
    @test stanrepr([1, 2]) == "c(1, 2)"
    @test stanrepr(2:10) == "2:10"
    @test stanrepr(10:2) == "integer(0)"
    @test stanrepr(Int[]) == "integer(0)"
    @test stanrepr([3.0, 7.0]) == "c(3.0, 7.0)"
    @test stanrepr(range(0, 1; length = 3)) == "c(0.0, 0.5, 1.0)"
end

@testset "array" begin
    @test stanrepr([1 2 3; 4 5 6], compact = true) ==
        "structure(c(1,4,2,5,3,6),.Dim=c(2,3))"
end

@testset "dict" begin
    d = Dict(:a => [1, 2], :b => 9.0)
    s = "a <- c(1, 2)\nb <- 9.0\n"
    let io = IOBuffer()
        stan_dump(io, d)
        @test String(take!(io)) == s
    end
end

@testset "general" begin
    io = IOBuffer()
    sd = StanDumpIO(io; compact = true)
    stan_dump(sd, (a = 1, b = 2)) # multiple arguments
    @test String(take!(io)) == "a<-1\nb<-2\n"
end

@testset "accidental varnames (from pairs)" begin
    @test_throws ArgumentError stan_dump(stdout, 1:3)
end
