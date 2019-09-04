using Dates: Millisecond
using TimeToLive: TTL, Node
using Test

const p = Millisecond(250)

@testset "TimeToLive.jl" begin
    @testset "Constructors" begin
        t = TTL(p)
        @test t.ttl == p
        @test t.d isa Dict{Any, Node{Any}}
        t = TTL{Int, String}(p)
        @test t.d isa Dict{Int, Node{String}}
    end

    @testset "Basic expiry" begin
        t = TTL(p)
        t[0] = "!"
        @test get(t, 0, nothing) == "!"
        sleep(2p)
        @test isempty(t)
    end

    @testset "Refreshing expiry" begin
        t = TTL(p)
        t[0] = "!"
        sleep(p/2)
        touch(t, 0)
        sleep(p)
        @test get(t, 0, nothing) == "!"
        sleep(2p)
        @test isempty(t)
    end

    @testset "Iteration" begin
        t = TTL(p)
        t[1] = t[2] = t[3] = t[4] = t[5] = "!"
        count = 0
        for pair in t
            @test pair isa Pair{Int, String}
            count += 1
        end
        @test count == 5
    end

    @testset "Refresh on access" begin
        t = TTL(p; refresh_on_access=true)
        t[0] = "!"
        sleep(p/2)
        t[0]
        sleep(p)
        @test get(t, 0, nothing) == "!"
    end

    @testset "Disabled refresh on access" begin
        t = TTL(p; refresh_on_access=false)
        t[0] = "!"
        sleep(p/2)
        t[0]
        sleep(p)
        @test get(t, 0, nothing) === nothing
    end

    @testset "Troublesome Base methods" begin
        t = TTL{Int, Int}(p)
        t[1] = 2
        t[2] = 3
        t[3] = 4
        t[4] = 5
        t[5] = 6

        @test all(v -> v isa Int, values(t))
        pair = pop!(t)
        @test pair isa Pair{Int, Int}
        t[pair.first] = pair.second
        @test pop!(t, 4) == 5
        @test !haskey(t, 4)
        @test length(filter!(p -> p.second > 2, t)) == 3
        @test !haskey(t, 1)
    end
end
