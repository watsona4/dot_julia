using RemoteSemaphores
using RemoteSemaphores: _current_count
using Test

using Dates
using Distributed

include("utils.jl")

@testset "RemoteSemaphores.jl" begin

@testset "Single Process" begin
    @test_throws ArgumentError RemoteSemaphore(0)

    rsem = RemoteSemaphore(2)
    @test _current_count(rsem) == 0
    @test string(rsem) == "$(typeof(rsem))(2, pid=$(myid()))"

    try
        asynctimedwait(1.0; kill=true) do
            release(rsem)
        end
        @test "Expected error but no error thrown" == nothing
    catch err
        @test err isa RemoteException

        if VERSION >= v"1.2.0-DEV.28"
            expected = ErrorException
            @test err.captured.ex isa expected
            @test occursin("release count must match acquire count", err.captured.ex.msg)
        else
            expected = AssertionError
            @test err.captured.ex isa expected
        end

        if !isa(err, RemoteException) || !isa(err.captured.ex, expected)
            rethrow(err)
        end
    end

    @test asynctimedwait(1.0; kill=true) do
        acquire(rsem)
    end
    @test _current_count(rsem) == 1

    @test asynctimedwait(1.0; kill=true) do
        acquire(rsem)
    end
    @test _current_count(rsem) == 2

    acquired = false
    @test asynctimedwait(1.0) do
        acquire(rsem)
        acquired = true
    end == false
    @test !acquired
    @test _current_count(rsem) == 2

    @test asynctimedwait(1.0; kill=true) do
        release(rsem)
    end
    @test acquired
    @test _current_count(rsem) == 2

    @test asynctimedwait(10.0; kill=true) do
        @sync for i = 1:100
            @async (isodd(i) ? acquire(rsem) : release(rsem))
        end
    end

    @test _current_count(rsem) == 2
end

@testset "Multiple Processes" begin
    @testset "Simple remote" begin
        worker_pid = addprocs(1)[1]
        @everywhere using RemoteSemaphores
        @everywhere include("utils.jl")

        rsem = RemoteSemaphore(2, worker_pid)
        @test _current_count(rsem) == 0
        @test string(rsem) == "$(typeof(rsem))(2, pid=$worker_pid)"

        try
            asynctimedwait(1.0; kill=true) do
                release(rsem)
            end
            @test "Expected error but no error thrown" == nothing
        catch err
            @test err isa RemoteException

            if VERSION >= v"1.2.0-DEV.28"
                expected = ErrorException
                @test err.captured.ex isa expected
                @test occursin("release count must match acquire count", err.captured.ex.msg)
            else
                expected = AssertionError
                @test err.captured.ex isa expected
            end

            if !isa(err, RemoteException) || !isa(err.captured.ex, expected)
                rethrow(err)
            end
        end

        @test asynctimedwait(1.0; kill=true) do
            acquire(rsem)
        end
        @test _current_count(rsem) == 1

        @test asynctimedwait(1.0; kill=true) do
            acquire(rsem)
        end
        @test _current_count(rsem) == 2

        acquired = false
        @test asynctimedwait(1.0) do
            acquire(rsem)
            acquired = true
        end == false
        @test !acquired
        @test _current_count(rsem) == 2

        @test asynctimedwait(1.0; kill=true) do
            release(rsem)
        end
        @test acquired
        @test _current_count(rsem) == 2

        @test asynctimedwait(10.0; kill=true) do
            @sync for i = 1:100
                @async (isodd(i) ? acquire(rsem) : release(rsem))
            end
        end

        @test _current_count(rsem) == 2
    end

    @testset "Multiple processes" begin
        addprocs(3 - nprocs())
        worker1_pid, worker2_pid = workers()
        @everywhere using RemoteSemaphores
        @everywhere using RemoteSemaphores: _current_count
        @everywhere include("utils.jl")

        rsem = RemoteSemaphore(3, worker1_pid)
        @test _current_count(rsem) == 0
        @test (@fetchfrom worker1_pid _current_count(rsem)) == 0
        @test (@fetchfrom worker2_pid _current_count(rsem)) == 0

        @test asynctimedwait(10.0; kill=true) do
            acquire(rsem)
        end
        @test _current_count(rsem) == 1
        @test (@fetchfrom worker1_pid _current_count(rsem)) == 1
        @test (@fetchfrom worker2_pid _current_count(rsem)) == 1

        @test @fetchfrom worker2_pid asynctimedwait(1.0; kill=true) do
            acquire(rsem)
        end
        @test _current_count(rsem) == 2
        @test (@fetchfrom worker1_pid _current_count(rsem)) == 2
        @test (@fetchfrom worker2_pid _current_count(rsem)) == 2

        @test @fetchfrom worker1_pid asynctimedwait(1.0; kill=true) do
            acquire(rsem)
        end
        @test _current_count(rsem) == 3
        @test (@fetchfrom worker1_pid _current_count(rsem)) == 3
        @test (@fetchfrom worker2_pid _current_count(rsem)) == 3

        acquired1 = false
        @test asynctimedwait(10.0) do
            acquire(rsem)
            acquired1 = true
        end == false

        acquired2 = Future()
        @test @fetchfrom worker1_pid begin
            asynctimedwait(10.0) do
                acquire(rsem)
                put!(acquired2, true)
            end
        end == false

        acquired3 = Future()
        @test @fetchfrom worker2_pid begin
            asynctimedwait(10.0) do
                acquire(rsem)
                put!(acquired3, true)
            end
        end == false

        conditions_hit() = acquired1 + isready(acquired2) + isready(acquired3)

        sleep(10)

        @test conditions_hit() == 0
        @test asynctimedwait(10.0; kill=true) do
            release(rsem)
        end

        sleep(2)

        @test conditions_hit() == 1
        @test asynctimedwait(10.0; kill=true) do
            release(rsem)
        end

        sleep(2)

        @test conditions_hit() == 2
        @test asynctimedwait(10.0; kill=true) do
            release(rsem)
        end

        sleep(2)

        @test conditions_hit() == 3
        @test acquired1
        @test isready(acquired2)
        @test isready(acquired3)
    end
end

end
