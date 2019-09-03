using RingBuffers
import Compat: undef, fetch
using Compat.Test

@testset "RingBuffer Tests" begin
    include("pa_ringbuffer.jl")
    @testset "Can check frames readable and writable" begin
        rb = RingBuffer{Float64}(2, 8)
        @test framesreadable(rb) == 0
        @test frameswritable(rb) == 8
        write(rb, rand(2, 5))
        @test framesreadable(rb) == 5
        @test frameswritable(rb) == 3
        read(rb, 3)
        @test framesreadable(rb) == 2
        @test frameswritable(rb) == 6
        write(rb, rand(2, 6))
        @test framesreadable(rb) == 8
        @test frameswritable(rb) == 0
    end
    @testset "Can read/write 2D arrays" begin
        writedata = collect(reshape(1:10, 2, 5))
        readdata = collect(reshape(11:20, 2, 5))
        rb = RingBuffer{Int}(2, 8)
        write(rb, writedata)
        read!(rb, readdata)
        @test readdata == writedata
    end

    @testset "Can read/write 1D arrays" begin
        writedata = collect(1:10)
        readdata = collect(11:20)
        rb = RingBuffer{Int}(2, 8)
        write(rb, writedata)
        read!(rb, readdata)
        @test readdata == writedata
    end

    @testset "throws error writing 2D array of wrong channel count" begin
        writedata = collect(reshape(1:15, 3, 5))
        rb = RingBuffer{Int}(2, 8)
        @test_throws ErrorException write(rb, writedata)
    end

    @testset "throws error reading 2D array of wrong channel count" begin
        writedata = collect(reshape(1:10, 2, 5))
        readdata = collect(reshape(11:25, 3, 5))
        rb = RingBuffer{Int}(2, 8)
        write(rb, writedata)
        @test_throws ErrorException read!(rb, readdata)
    end

    @testset "throws error writing too-short array" begin
        writedata = collect(reshape(1:15, 3, 5))
        rb = RingBuffer{Int}(2, 8)
        @test_throws ErrorException write(rb, writedata, 8)
    end

    @testset "throws error reading into too-short array" begin
        readdata = collect(reshape(1:15, 3, 5))
        rb = RingBuffer{Int}(2, 8)
        @test_throws ErrorException read!(rb, readdata, 8)
    end

    @testset "multiple sequential writes work" begin
        writedata = collect(reshape(1:8, 2, 4))
        rb = RingBuffer{Int}(2, 10)
        write(rb, writedata)
        write(rb, writedata)
        readdata = read(rb, 8)
        @test readdata == hcat(writedata, writedata)
    end

    @testset "multiple queued writes work" begin
        writedata = collect(reshape(1:14, 2, 7))
        rb = RingBuffer{Int}(2, 4)
        writer1 = @async begin
            # println("writer 1 started")
            write(rb, writedata)
            # println("writer 1 finished")
        end
        writer2 = @async begin
            # println("writer 2 started")
            write(rb, writedata)
            # println("writer 2 finished")
        end
        readdata = read(rb, 14)
        @test readdata == hcat(writedata, writedata)
    end

    @testset "multiple sequential reads work" begin
        writedata = collect(reshape(1:16, 2, 8))
        rb = RingBuffer{Int}(2, 10)
        write(rb, writedata)
        readdata1 = read(rb, 4)
        readdata2 = read(rb, 4)
        @test hcat(readdata1, readdata2) == writedata
    end

    @testset "overflow blocks writer" begin
        writedata = collect(reshape(1:10, 2, 5))
        rb = RingBuffer{Int}(2, 8)
        write(rb, writedata)
        t = @async write(rb, writedata)
        sleep(0.1)
        @test t.state == :runnable
        readdata = read(rb, 8)
        @test fetch(t) == 5
        @test t.state == :done
        @test readdata == hcat(writedata, writedata[:, 1:3])
    end

    @testset "underflow blocks reader" begin
        writedata = collect(reshape(1:6, 2, 3))
        rb = RingBuffer{Int}(2, 8)
        write(rb, writedata)
        t = @async read(rb, 6)
        sleep(0.1)
        @test t.state == :runnable
        write(rb, writedata)
        @test fetch(t) == hcat(writedata, writedata)
        @test t.state == :done
    end

    @testset "closing ringbuf cancels in-progress writes" begin
        writedata = collect(reshape(1:20, 2, 10))
        rb = RingBuffer{Int}(2, 8)
        t1 = @async write(rb, writedata)
        t2 = @async write(rb, writedata)
        sleep(0.1)
        close(rb)
        @test fetch(t1) == 8
        @test fetch(t2) == 0
    end

    @testset "closing ringbuf cancels in-progress reads" begin
        writedata = collect(reshape(1:6, 2, 3))
        rb = RingBuffer{Int}(2, 8)
        write(rb, writedata)
        t1 = @async read(rb, 5)
        t2 = @async read(rb, 5)
        sleep(0.1)
        close(rb)
        @test fetch(t1) == writedata[:, 1:3]
        @test fetch(t2) == Array{Int}(undef, 2, 0)
    end

    @testset "writeavailable works with Matrices" begin
        writedata = collect(reshape(1:20, 2, 10))
        rb = RingBuffer{Int}(2, 8)
        @test writeavailable(rb, writedata) == 8
        @test readavailable(rb) == writedata[:, 1:8]
    end

    @testset "writeavailable works with Vectors" begin
        writedata = collect(1:20)
        rb = RingBuffer{Int}(2, 8)
        @test writeavailable(rb, writedata) == 8
        @test vec(readavailable(rb)) == writedata[1:16]
    end

    @testset "read reads until the buffer is closed" begin
        writedata = collect(reshape(1:8, 2, 4))
        rb = RingBuffer{Int}(2, 8)
        write(rb, writedata)
        reader = @async read(rb; blocksize=6)
        for _ in 1:3
            write(rb, writedata)
        end
        flush(rb)
        close(rb)
        if VERSION >= v"0.7.0-DEV.3977" # Julia PR 26039
            @test fetch(reader) == repeat(writedata, 1, 4)
        else
            @test fetch(reader) == Compat.repmat(writedata, 1, 4)
        end
    end

    @testset "flush works if we're queued behind a writer" begin
        writedata = collect(reshape(1:16, 2, 8))
        rb = RingBuffer{Int}(2, 4)
        writer1 = @async write(rb, writedata)
        flusher = @async flush(rb)
        writer2 = @async write(rb, writedata)
        read(rb, 16)
        fetch(flusher)
        # as long as this gets through then we should be OK that the tasks
        # woke each other up
        @test true
    end
end
