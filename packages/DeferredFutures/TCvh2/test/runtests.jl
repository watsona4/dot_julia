using DeferredFutures
using Distributed
using Serialization
using Test

@testset "DeferredRemoteRefs" begin
    @testset "DeferredFuture Comparison" begin
        rc = RemoteChannel()
        @test DeferredFuture(rc) == DeferredFuture(rc)
        @test hash(DeferredFuture(rc)) == hash(DeferredFuture(rc))
    end

    @testset "DeferredChannel Comparison" begin
        rc = RemoteChannel()
        func = () -> RemoteChannel()
        @test DeferredChannel(rc, func) == DeferredChannel(rc, func)
        @test hash(DeferredChannel(rc, func)) == hash(DeferredChannel(rc, func))
    end

    @testset "Finalizing" begin
        df = DeferredFuture()
        finalize(df)
        @test_throws Exception isready(df)
        @test_throws Exception fetch(df)
        @test_throws Exception df[]
        @test_throws Exception put!(df, 1)
        @test_throws Exception take!(df)
        @test_throws Exception wait(df)
        finalize(df)

        dc = DeferredChannel()
        finalize(dc)
        @test_throws Exception isready(dc)
        @test_throws Exception fetch(dc)
        @test_throws Exception close(dc)
        @test_throws Exception dc[]
        @test_throws Exception put!(dc, 1)
        @test_throws Exception take!(dc)
        @test_throws Exception wait(dc)
        finalize(dc)

        dc = DeferredChannel()
        close(dc)
        @test !isready(dc)
        @test_throws Exception fetch(dc)
        @test_throws Exception dc[]
        @test_throws Exception put!(dc, 1)
        @test_throws Exception take!(dc)
        @test_throws Exception wait(dc)
        close(dc)
        finalize(dc)
        @test_throws Exception isready(dc)
        @test_throws Exception fetch(dc)
        @test_throws Exception close(dc)
        @test_throws Exception dc[]
        @test_throws Exception put!(dc, 1)
        @test_throws Exception take!(dc)
        @test_throws Exception wait(dc)

        df = DeferredFuture()
        put!(df, 1)
        @test df[] == 1
        finalize(df)
        @test_throws Exception isready(df)
        @test_throws Exception fetch(df)
        @test_throws Exception df[]
        @test_throws Exception put!(df, 1)
        @test_throws Exception take!(df)
        @test_throws Exception wait(df)

        dc = DeferredChannel()
        put!(dc, 1)
        @test dc[] == 1
        finalize(dc)
        @test_throws Exception isready(dc)
        @test_throws Exception fetch(dc)
        @test_throws Exception close(dc)
        @test_throws Exception dc[]
        @test_throws Exception put!(dc, 1)
        @test_throws Exception take!(dc)
        @test_throws Exception wait(dc)

        dc = DeferredChannel()
        put!(dc, 1)
        @test dc[] == 1
        close(dc)
        @test isready(dc)
        @test fetch(dc) == 1
        @test dc[] == 1
        @test_throws Exception put!(dc, 1)
        @test take!(dc) == 1
        @test !isready(dc)
        @test_throws Exception fetch(dc)
        @test_throws Exception dc[]
        @test_throws Exception put!(dc, 1)
        @test_throws Exception take!(dc)
        @test_throws Exception wait(dc)
        finalize(dc)
        @test_throws Exception isready(dc)
        @test_throws Exception fetch(dc)
        @test_throws Exception close(dc)
        @test_throws Exception dc[]
        @test_throws Exception put!(dc, 1)
        @test_throws Exception take!(dc)
        @test_throws Exception wait(dc)
    end

    @testset "Distributed DeferredFuture" begin
        top = myid()
        bottom = addprocs(1)[1]
        @everywhere using DeferredFutures

        try
            val = "hello"
            df = DeferredFuture(top)

            @test !isready(df)

            fut = remotecall_wait(bottom, df) do dfr
                put!(dfr, val)
            end
            @test fetch(fut) == df
            @test isready(df)
            @test fetch(df) == val
            @test wait(df) == df
            @test_throws ErrorException put!(df, val)

            @test df[] == val
            @test df[5] == 'o'

            @test df.outer.where == top
            @test fetch(df.outer).where == bottom

            reset!(df)
            @test !isready(df)
            put!(df, "world")
            @test fetch(df) == "world"
            finalize(df)
            @test_throws Exception isready(df)
            @test_throws Exception fetch(df)
            @test_throws Exception df[]
            @test_throws Exception put!(df, 1)
            @test_throws Exception take!(df)
            @test_throws Exception wait(df)
            finalize(df)
        finally
            rmprocs(bottom)
        end
    end

    @testset "Distributed DeferredChannel" begin
        top = myid()
        bottom = addprocs(1)[1]
        @everywhere using DeferredFutures

        try
            val = "hello"
            channel = DeferredChannel(top, 32)

            @test !isready(channel)

            fut = remotecall_wait(bottom, channel) do dfr
                put!(dfr, val)
            end
            @test fetch(fut) == channel
            @test isready(channel)
            @test fetch(channel) == val
            @test wait(channel) == channel

            @test channel[] == val
            @test channel[5] == 'o'

            put!(channel, "world")
            @test take!(channel) == val
            @test fetch(channel) == "world"

            @test channel.outer.where == top
            @test fetch(channel.outer).where == bottom

            reset!(channel)
            @test !isready(channel)
            put!(channel, "world")
            @test fetch(channel) == "world"
            finalize(channel)
            @test_throws Exception isready(channel)
            @test_throws Exception fetch(channel)
            @test_throws Exception close(channel)
            @test_throws Exception channel[]
            @test_throws Exception put!(channel, 1)
            @test_throws Exception take!(channel)
            @test_throws Exception wait(channel)
            finalize(channel)
        finally
            rmprocs(bottom)
        end
    end


    @testset "Allocation" begin
        rand_size = 800000000  # sizeof(rand(10000, 10000))
        GC.gc()
        main_size = Base.summarysize(Distributed)

        top = myid()
        bottom = addprocs(1)[1]
        @everywhere using DeferredFutures

        try
            df = DeferredFuture(top)

            remote_size = remotecall_fetch(bottom, df) do dfr
                GC.gc()
                main_size = Base.summarysize(Distributed)

                # the DeferredFuture is initialized and the data is stored on bottom
                put!(dfr, rand(10000, 10000))
                main_size
            end

            GC.gc()
            # tests that the data has not been transfered to top
            @test Base.summarysize(Distributed) < main_size + rand_size

            remote_size_new = remotecall_fetch(bottom) do
                GC.gc()
                Base.summarysize(Distributed)
            end

            # tests that the data still exists on bottom
            @test remote_size_new >= remote_size + rand_size
        finally
            rmprocs(bottom)
        end
    end

    @testset "Transfer" begin
        rand_size = 800000000  # sizeof(rand(10000, 10000))
        GC.gc()
        main_size = Base.summarysize(Main)

        top = myid()
        left, right = addprocs(2)
        @everywhere using DeferredFutures

        try
            df = DeferredFuture(top)

            left_remote_size = remotecall_fetch(left, df) do dfr
                GC.gc()
                main_size = Base.summarysize(Main)
                put!(dfr, rand(10000, 10000))
                main_size
            end

            right_remote_size = remotecall_fetch(right, df) do dfr
                GC.gc()
                main_size = Base.summarysize(Main)
                global data = fetch(dfr)
                main_size
            end

            GC.gc()
            @test Base.summarysize(Main) < main_size + rand_size

            right_remote_size_new = remotecall_fetch(right) do
                GC.gc()
                Base.summarysize(Main)
            end

            @test right_remote_size_new >= right_remote_size + rand_size
        finally
            rmprocs([left, right])
        end
    end

    @testset "@defer" begin
        ex = macroexpand(@__MODULE__, :(@defer RemoteChannel(()->Channel(5))))
        ex = macroexpand(@__MODULE__, :(@defer RemoteChannel()))

        channel = @defer RemoteChannel(()->Channel(32))

        put!(channel, 1)
        put!(channel, 2)

        @test fetch(channel) == 1
        @test take!(channel) == 1
        @test fetch(channel) == 2

        fut = macroexpand(@__MODULE__, :(@defer Future()))
        other_future = macroexpand(@__MODULE__, :(@defer Future()))

        @test_throws LoadError macroexpand(@__MODULE__, :(@defer mutable struct Foo end))
        try
            macroexpand(@__MODULE__, :(@defer mutable struct Foo end))
            @test false
        catch e
            @test e.error isa AssertionError
        end

        @test_throws LoadError macroexpand(@__MODULE__, :(@defer Channel()))
        try
            macroexpand(@__MODULE__, :(@defer Channel()))
            @test false
        catch e
            @test e.error isa AssertionError
        end
        close(channel)
    end

    @testset "Show" begin
        rc = RemoteChannel()
        rc_params = "($(rc.where),$(rc.whence),$(rc.id))"

        @test sprint(show, DeferredFuture(rc)) == "DeferredFuture at $rc_params"

        dc = DeferredChannel(rc, print)
        @test sprint(show, dc) == "DeferredChannel(print) at $rc_params"
    end

    @testset "Serialization" begin
        @testset "DeferredFuture serialization on same process" begin
            df = DeferredFuture(myid())

            io = IOBuffer()
            serialize(io, df)
            seekstart(io)
            deserialized_df = deserialize(io)
            close(io)

            @test deserialized_df == df
        end

        @testset "DeferredFuture serialization on a cluster" begin
            df1 = DeferredFuture(myid())
            df2 = DeferredFuture(myid())

            io = IOBuffer()
            serialize(io, df1)
            df1_string = take!(io)
            close(io)

            put!(df2, 28)

            io = IOBuffer()
            serialize(io, df2)
            df2_string = take!(io)
            close(io)

            bottom = addprocs(1)[1]
            @everywhere using DeferredFutures
            @everywhere using Serialization

            df3_string = ""
            try
                df3_string = @fetchfrom bottom begin
                    io = IOBuffer()
                    write(io, df1_string)
                    seekstart(io)
                    bottom_df1 = deserialize(io)
                    close(io)

                    put!(bottom_df1, 37)

                    io = IOBuffer()
                    write(io, df2_string)
                    seekstart(io)
                    bottom_df2 = deserialize(io)
                    close(io)

                    @test isready(bottom_df2) == true
                    @test fetch(bottom_df2) == 28
                    reset!(bottom_df2)

                    df3 = DeferredFuture(myid())
                    put!(df3, 14)

                    io = IOBuffer()
                    serialize(io, df3)
                    df3_string = take!(io)
                    close(io)

                    return df3_string
                end

                @test isready(df1) == true
                @test fetch(df1) == 37

                @test isready(df2) == false

                @test df3_string != ""

            finally
                rmprocs(bottom)
            end

            io = IOBuffer()
            write(io, df3_string)
            seekstart(io)
            bottom_df3 = deserialize(io)
            close(io)

            @test_broken isready(bottom_df3) == true
            @test_broken fetch(bottom_df3) == 14
        end

        @testset "DeferredChannel serialization on same process" begin
            dc = DeferredChannel()

            io = IOBuffer()
            serialize(io, dc)
            seekstart(io)
            deserialized_dc = deserialize(io)
            close(io)

            @test deserialized_dc == dc
        end

        @testset "DeferredChannel serialization on a cluster" begin
            dc1 = DeferredChannel()
            dc2 = DeferredChannel()

            io = IOBuffer()
            serialize(io, dc1)
            dc1_string = take!(io)
            close(io)

            put!(dc2, 28)

            io = IOBuffer()
            serialize(io, dc2)
            dc2_string = take!(io)
            close(io)

            bottom = addprocs(1)[1]
            @everywhere using DeferredFutures
            @everywhere using Serialization

            dc3_string = ""
            try
                dc3_string = @fetchfrom bottom begin
                    io = IOBuffer()
                    write(io, dc1_string)
                    seekstart(io)
                    bottom_dc1 = deserialize(io)
                    close(io)

                    put!(bottom_dc1, 37)

                    io = IOBuffer()
                    write(io, dc2_string)
                    seekstart(io)
                    bottom_dc2 = deserialize(io)
                    close(io)

                    @test isready(bottom_dc2) == true
                    @test fetch(bottom_dc2) == 28
                    reset!(bottom_dc2)

                    dc3 = DeferredChannel()
                    put!(dc3, 14)

                    io = IOBuffer()
                    serialize(io, dc3)
                    dc3_string = take!(io)
                    close(io)

                    return dc3_string
                end

                @test isready(dc1) == true
                @test fetch(dc1) == 37

                @test isready(dc2) == false

                @test dc3_string != ""

            finally
                rmprocs(bottom)
            end

            io = IOBuffer()
            write(io, dc3_string)
            seekstart(io)
            bottom_dc3 = deserialize(io)
            close(io)

            @test_broken isready(bottom_dc3) == true
            @test_broken fetch(bottom_dc3) == 14
        end

        @testset "DeferredFuture serialization as part of another object" begin
            pnums = addprocs(1)
            @everywhere using DeferredFutures

            try
                x = ()->3
                df = DeferredFuture()
                result = @fetch (df, x)

                @test result[1] == df
                @test result[2]() == 3
            finally
                rmprocs(pnums)
            end
        end

        @testset "DeferredChannel serialization as part of another object" begin
            pnums = addprocs(1)
            @everywhere using DeferredFutures

            try
                x = ()->3
                dc = DeferredChannel()
                result = @fetch (dc, x)

                @test result[1] == dc
                @test result[2]() == 3
            finally
                rmprocs(pnums)
            end
        end
    end
end
