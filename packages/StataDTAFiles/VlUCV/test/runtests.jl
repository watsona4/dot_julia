using StataDTAFiles, Test, Dates, StrFs
using StataDTAFiles: LSF, verifytag, read_header, read_map, read_variable_types,
    read_variable_names, read_sortlist, read_formats, TIMESTAMPFMT, readrow
using Parameters: @unpack
import Tables

testdata = joinpath(@__DIR__, "data", "testdata.dta")

≅(a, b) = a == b
≅(a::AbstractVector, b::AbstractVector) = all(a .≅ b)
≅(a::Tuple, b::Tuple) = all(a .≅ b)
≅(a::NamedTuple, b::NamedTuple) = all(map(≅, a,  b))
≅(::Missing, ::Missing) = true

@testset "reading tags" begin
    @test verifytag(IOBuffer("<atag>"), "atag") == nothing
    @test verifytag(IOBuffer("</btag>"), "btag", true) == nothing
    @test_throws ErrorException verifytag(IOBuffer("noopening>"), "noopening")
    @test_throws EOFError verifytag(IOBuffer("<eof"), "eof")
    @test_throws ErrorException verifytag(IOBuffer("<a>"), "b")
end

@testset "reading header" begin
    dta = open(DTAFile, testdata)
    @test dta.header.release == 118
    @test dta.header.variables == 3
    @test dta.header.observations == 10
    @test dta.header.label == ""
    @test dta.map.eof == filesize(testdata)
    @test Base.IteratorEltype(typeof(dta)) ≡ Base.HasEltype()
    @test eltype(dta) == NamedTuple{(:a, :b, :c), Tuple{Union{Missing, Float32},
                                                        Union{Missing, Int16},
                                                        StrF{2}}}
    @test Base.IteratorSize(typeof(dta)) ≡ Base.HasLength()
    @test length(dta) == 10
    @test dta.sortlist == []
    @test dta.formats == ["%9.0g", "%9.0g", "%9s"]
    @test @inferred(collect(dta)) ≅ [(a = i > 7 ? missing : Float32(i),
                                     b = i ≤ 2 ? missing : Int16(i),
                                     c = StrF{2}(string(i))) for i in 1:10]
    close(dta)
end

@testset "reading header" begin
    str = open(repr, DTAFile, testdata)
    r_header = raw"^Stata DTA file 118, 3 vars in 10 rows, .*\n\s+not sorted\n"
    r_vars = raw"\s+a::Union\{Missing,\s*Float32\}.*\n\s+b::Union\{Missing,\s*Int16\}.*\n\s+c::StrF\{2\}.*$"
    @test occursin(Regex(r_header * r_vars), str)
end

@testset "type stability" begin
    # Test that readrow is inferred. Tests use internals, which are not part of the API.
    dta = open(DTAFile, testdata)
    @unpack boio = dta
    seek(boio, dta.map.data)
    verifytag(boio, "data")
    for _ in 1:length(dta)
        @test @inferred(readrow(boio, eltype(dta))) isa NamedTuple
    end
end

@testset "timestamp parsing" begin
    @test DateTime("04 Jul 2032 04:23", TIMESTAMPFMT) ==
        DateTime("04 Jul 2032 04:23", TIMESTAMPFMT) ==
        DateTime("2032-07-04T04:23:00")
end

@testset "elapsed dates" begin
    @test elapsed_days(0) == Date(1960, 1, 1)
    @test elapsed_days(1) == Date(1960, 1, 2)
    @test elapsed_days(-1) == Date(1959, 12, 31)
    @test elapsed_days(365) == Date(1960, 12, 31)
end

@testset "tables interface" begin
    dta = open(DTAFile, testdata)
    @test Tables.istable(typeof(dta)) == true
    @test Tables.rowaccess(typeof(dta)) == true
    @test Tables.rows(dta) ≡ dta
    @test Tables.schema(dta) ≡ Tables.Schema((:a, :b, :c),
                                             (Union{Missing, Float32},
                                              Union{Missing, Int16},
                                              StrF{2}))
    @test Tables.columntable(dta) ≅
        (a = Union{Missing, Float32}[1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, missing, missing, missing],
         b = Union{Missing, Int16}[missing, missing, 3, 4, 5, 6, 7, 8, 9, 10],
         c = StrF{2}["1", "2", "3", "4", "5", "6", "7", "8", "9", "10"])
end
