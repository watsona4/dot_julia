using Test #, Logging
using Unitful, Measurements, DataFrames

"""Helper for tests: Capture the output of show(io, mime, x)."""
function showoutput(mime::String, x, options...)
    buffer = IOBuffer()
    io = IOContext(buffer, options...)
    show(io, mime, x)
    return String(take!(buffer))
end

"""Helper function to test the output, useful for looping over
values. If the keyword argment broken is given, perform a @test_broken
instead of a @test."""
function testshow(mime::String, got, want; broken::Bool=false)
    if broken
        @eval @test_broken showoutput($mime, $got) == $want
    else
        @eval @test showoutput($mime, $got) == $want
    end
end

@testset "internals" begin
    include("internals.jl")
end
@testset "show(::AbstractFloat)" begin
    testshow("text/plain", 100.049, "100.0")
    testshow("text/plain", 1.00049, "1.000")
    testshow("text/plain", Float16(100.0), "100.0(2)")
    testshow("text/plain", Float16(1.0), "1.00(3)")
end
@testset "show(::Measurements.Measurement)" begin
    include("show-measurements.jl")
end
@testset "show(::Unitful.Quantity)" begin
    include("show-unitful.jl")
end
@testset "show(::DataFrame)" begin
    include("show-dataframes.jl")
end
