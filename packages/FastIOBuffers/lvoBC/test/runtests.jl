module FastIOBuffersTest

using Test
using Random
using FastIOBuffers

@testset "write: bitstype numbers" begin
    for T = [Int8,UInt8,Int16,UInt16,Int32,UInt32,Int64,UInt64,Int128,UInt128,Float16,Float32,Float64]
        buf = FastWriteBuffer()
        @test iswritable(buf)
        @test !isreadable(buf)
        @test isopen(buf)
        @test_throws MethodError close(buf)
        @test position(buf) == 0
        for i = 1 : 2
            x = rand(T)
            @test write(buf, x)::Int == Core.sizeof(x)
            @test position(buf) == Core.sizeof(x)
            allocs = @allocated(write(buf, x))
            if i > 1
                @test allocs == 0
            end
            bytes = take!(buf)
            readbuf = IOBuffer(bytes)
            for _ = 1 : 2
                xback = read(readbuf, T)
                @test xback == x
            end
        end
        @test eof(buf)
    end
end

@testset "write: strings" begin
    rng = MersenneTwister(1)
    buf = FastWriteBuffer()
    for i = 1 : 2
        take!(buf)
        str = randstring(rng, 8)
        allocs = @allocated write(buf, str)
        if i > 1
            @test allocs == 0
        end
    end

    buf = FastWriteBuffer()
    for i = 1 : 1000
        str = randstring(rng, 8)
        @test write(buf, str)::Int == sizeof(str)
        write(buf, str)
        strstr = String(take!(buf))
        @test strstr == str * str
    end
end

@testset "read: bitstype numbers" begin
    rng = MersenneTwister(1)
    buf = FastReadBuffer()
    @test !iswritable(buf)
    @test isreadable(buf)
    @test isopen(buf)
    @test_throws MethodError close(buf)
    writebuf = IOBuffer()
    for T = [Int8,UInt8,Int16,UInt16,Int32,UInt32,Int64,UInt64,Int128,UInt128,Float16,Float32,Float64]
        @eval begin # otherwise read(buf, T) doesn't infer
            for i = 1 : 2
                x = rand($rng, $T)
                y = rand($rng, $T)
                write($writebuf, x)
                write($writebuf, y)
                setdata!($buf, take!($writebuf))
                @test bytesavailable($buf) == 2 * Core.sizeof($T)
                xback = read($buf, $T)
                allocs = @allocated read($buf, $T)
                @test xback === x
                if i > 1
                    @test allocs == 0
                end
                @test_throws EOFError read($buf, $T)
                seekstart($buf)
                @test read($buf, $T) == x
                seekend($buf)
                @test_throws EOFError read($buf, UInt8)
                @test position($buf) == 2 * Core.sizeof($T)
                seekstart($buf)
                skip($buf, Core.sizeof($T))
                @test bytesavailable($buf) == Core.sizeof($T)
                @test read($buf, $T) == y
                @test eof($buf)
            end
        end
    end
end

@testset "read: string" begin
    rng = MersenneTwister(1)
    buf = FastReadBuffer()
    writebuf = IOBuffer()
    str = randstring(rng)
    write(writebuf, str)
    write(writebuf, str)
    setdata!(buf, take!(writebuf))
    @test read(buf, String) == str * str
    seekstart(buf)
    @test String(readavailable(buf)) == str * str
end

include(joinpath(@__DIR__, "..", "perf", "runbenchmarks.jl"))

end
