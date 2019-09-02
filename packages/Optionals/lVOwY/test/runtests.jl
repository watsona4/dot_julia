
using Optionals
using Compat.Test

struct Foo
    x::Optional{Int}
end

@testset "Optionals" begin
    @test !ismissing(Optional(13))
    @test ismissing(Optional{String}())
    @test !ismissing(Foo(42).x)
    @test ismissing(Foo(missing).x)

    @test coalesce(Optional(42)) == 42
    @test coalesce(Optional{String}()) === missing
    @test coalesce(Optional(42), 13) == 42
    @test coalesce(Optional{Int}(), 99) == 99

    @test repr(Optional(42)) == "42"
    @test repr(Optional{Int}()) == "missing"

    @test Optional(13) < Optional(42)
    @test 13 < Optional(42)
    @test Optional(13) < 42
    @test (13 < Optional{Int}()) === missing
    @test (Optional{Int}() < 13) === missing
    @test (Optional{Int}() < Optional{Int}()) === missing
    @test (Optional{Int}() < Optional{Int}(42)) === missing
    @test (Optional{Int}(13) < Optional{Int}()) === missing

    @test Optional(13) == Optional(13)
    @test 13 == Optional(13)
    @test Optional(13) == 13
    @test (13 == Optional{Int}()) === missing
    @test (Optional{Int}() == 13) === missing
    @test (Optional{Int}() == Optional{Int}()) === missing
    @test (Optional{Int}() == Optional{Int}(42)) === missing
    @test (Optional{Int}(13) == Optional{Int}()) === missing
end
