using Test
using YAJL

# A janky @test_throws that works with macro calls wrapped in an Expr.
test_throws(ex::Expr) = test_throws(ArgumentError, ex)
function test_throws(T::Type{<:Exception}, ex::Expr)
    try
        eval(ex)
        @error "Test failed: expected $T to be thrown" ex
        @test false
    catch e
        e isa LoadError && (e = e.error)
        if e isa T
            @test true
        else
            @error "Test failed: expected $T to be thrown, $(typeof(e)) thrown instead" ex
            @test false
        end
    end
end

macro test_nothrows(ex)
    quote
        try
            $(esc(ex))
            @test true
        catch e
            e isa LoadError && (e = e.error)
            @error "Test failed: expected no throw, $(typeof(e)) thrown instead" ex=$(QuoteNode(ex))
            @test false
        end
    end
end

mutable struct Counter <: YAJL.Context
    n::Int
    Counter() = new(0)
end
YAJL.collect(ctx::Counter) = ctx.n
@yajl integer(ctx::Counter, ::Int) = ctx.n += 1

mutable struct UntilN <: YAJL.Context
    n::Int
    xs::Vector{Int}
    cancelled::Bool
    broken::Bool
    UntilN(n::Int) = new(n, [], false, false)
end
YAJL.collect(ctx::UntilN) = ctx.xs, ctx.cancelled, ctx.broken
@yajl function integer(ctx::UntilN, n::Int)
    ctx.cancelled && (ctx.broken = true)
    if n == ctx.n
        ctx.cancelled = true
        return false
    else
        push!(ctx.xs, n)
    end
end

mutable struct ParametricSum{T<:Number} <: YAJL.Context
    x::T
    ParametricSum{T}() where T <: Number = new{T}(0)
end
YAJL.collect(ctx::ParametricSum) = ctx.x
@yajl number(ctx::ParametricSum{T}, v::Ptr{UInt8}, len::Int) where T <: Number =
    ctx.x += parse(T, unsafe_string(v, len))
@yajl number(ctx::ParametricSum{Int}, v::Ptr{UInt8}, len::Int) =
    ctx.x += 2 * parse(Int, unsafe_string(v, len))

mutable struct ParametricSumProduct{T<:Integer, U<:AbstractFloat} <: YAJL.Context
    x::T
    y::U
    ParametricSumProduct{T, U}() where {T <: Integer, U <: AbstractFloat} = new{T, U}(0, 0)
end
YAJL.collect(ctx::ParametricSumProduct) = ctx.x * ctx.y
@yajl integer(ctx::ParametricSumProduct, v::Int) = ctx.x += v
@yajl double(ctx::ParametricSumProduct, v::Float64) = ctx.y += v

mutable struct FooAcc <: YAJL.Context
    s::String
    FooAcc() = new("")
end
YAJL.collect(ctx::FooAcc) = ctx.s
@yajl integer(ctx::FooAcc, ::Int) = ctx.s *= "foo"

struct DoNothing <: YAJL.Context end
struct DoNothing2 <: YAJL.Context end
struct DoNothing3 <: YAJL.Context end
struct DoNothing4{T} <: YAJL.Context end

@testset "YAJL.jl" begin
    @testset "Basics" begin
        io = IOBuffer("[" * repeat("0,", 1000000) * "0]")
        expected = 1000001
        @test YAJL.run(io, Counter()) == expected
    end

    @testset "Cancellation" begin
        io = IOBuffer("[" * repeat("0,", 10) * "1,1,1,1,1]")
        expected = zeros(Int, 10), true, false
        @test YAJL.run(io, UntilN(1)) == expected
    end

    @testset "Parametric types" begin
        io = IOBuffer("[" * repeat("1.0,", 1000000) * "1.0]")
        expected = Float64(1000001)
        @test YAJL.run(io, ParametricSum{Float64}()) === expected
        io = IOBuffer("[" * repeat("1,", 1000000) * "1]")
        expected = Int(2000002)
        @test YAJL.run(io, ParametricSum{Int}()) === expected
        io = IOBuffer("[" * repeat("1.0,", 100) * repeat("1,", 100) * "1]")
        expected = Float64(10100)
        @test YAJL.run(io, ParametricSumProduct{Int, Float64}()) === expected
    end

    @testset "Not isbitstype" begin
        io = IOBuffer("[" * repeat("0,", 10) * "0]")
        expected = repeat("foo", 11)
        @test YAJL.run(io, FooAcc()) == expected
    end

    @testset "Parse options" begin
        ctx = DoNothing()
        io = IOBuffer("// foo\n{}")
        @test_nothrows YAJL.run(io, ctx; options=YAJL.ALLOW_COMMENTS)
        io = IOBuffer([0x22, 0xff, 0x22])
        @test_nothrows YAJL.run(io, ctx; options=YAJL.DONT_VALIDATE_STRINGS)
        io = IOBuffer("{}.")
        @test_nothrows YAJL.run(io, ctx; options=YAJL.ALLOW_TRAILING_GARBAGE)
        io = IOBuffer("{}{}")
        @test_nothrows YAJL.run(io, ctx; options=YAJL.ALLOW_MULTIPLE_VALUES)
        io = IOBuffer("[")
        @test_nothrows YAJL.run(io, ctx; options=YAJL.ALLOW_PARTIAL_VALUES)
        io = IOBuffer("// foo\n[{}")
        @test_nothrows YAJL.run(io, ctx; options=YAJL.ALLOW_COMMENTS | YAJL.ALLOW_PARTIAL_VALUES)
    end

    @testset "Parse errors" begin
        test_throws(YAJL.ParseError, :(YAJL.run(IOBuffer("."), DoNothing())))
    end

    @testset "@yajl errors + warnings" begin
        # Invalid callback name.
        test_throws(:(@yajl foo(::DoNothing) = nothing))
        # Untyped callback arguments.
        test_throws(:(@yajl null(ctx) = nothing))
        test_throws(:(@yajl integer(ctx::DoNothing, v) = nothing))
        # Invalid arguments.
        test_throws(:(@yajl null() = nothing))
        test_throws(:(@yajl null(::Int) = nothing))
        test_throws(:(@yajl null(::DoNothing, ::Any) = nothing))
        test_throws(:(@yajl boolean(::DoNothing, v::String) = nothing))
        test_throws(:(@yajl integer(::DoNothing, v::String) = nothing))
        test_throws(:(@yajl double(::DoNothing, v::String) = nothing))
        test_throws(:(@yajl number(::DoNothing, v::String, len::Int) = nothing))
        test_throws(:(@yajl number(::DoNothing, v::Cstring, len::String) = nothing))
        # Useless/destructive number callbacks.
        @test_logs eval(:(@yajl number(::DoNothing, ::Ptr{UInt8}, ::Int) = true))
        @test_logs (:warn, r"no effect") eval(:(@yajl integer(::DoNothing, ::Int) = nothing))
        @test_logs (:warn, r"no effect") eval(:(@yajl double(::DoNothing, ::Float64) = nothing))
        @test_logs eval(:(@yajl integer(::DoNothing2, ::Int) = nothing))
        @test_logs (:warn, r"disables") eval(:(@yajl number(::DoNothing2, ::Ptr{UInt8}, ::Int) = nothing))
        @test_logs eval(:(@yajl double(::DoNothing3, ::Float64) = nothing))
        @test_logs (:warn, r"disables") eval(:(@yajl number(::DoNothing3, ::Ptr{UInt8}, ::Int) = nothing))
        # When parametric types don't overlap, there should be no warning.
        @test_logs eval(:(@yajl integer(::DoNothing4{Int}, ::Int) = nothing))
        @test_logs eval(:(@yajl number(::DoNothing4{String}, ::Ptr{UInt8}, ::Int) = nothing))
        @test_logs eval(:(@yajl number(::DoNothing4{Nothing}, ::Ptr{UInt8}, ::Int) = nothing))
        @test_logs eval(:(@yajl double(::DoNothing4{Missing}, ::Float64) = nothing))
    end

    @testset "Minifier" begin
        io = IOBuffer("""
        [
          {
            "foo": null,
            "bar": 0,
            "baz": 1.2,
            "qux": "qux"
          },
          1,
          2,
          3
        ]
        """)
        expected = """[{"foo":null,"bar":0,"baz":1.2,"qux":"qux"},1,2,3]"""
        @test String(take!(YAJL.run(io, YAJL.Minifier(IOBuffer())))) == expected
    end
end
