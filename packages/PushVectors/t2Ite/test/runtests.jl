using PushVectors, Test, BenchmarkTools

@testset "implementation sanity checks" begin

    # create
    v = PushVector{Int}()
    @test v.len == 0
    @test v.parent isa Vector{Int}
    @test v == Int[]

    # add one element
    push!(v, 1)
    @test @inferred(v[1]) == 1
    @test v.len == 1 == length(v)
    @test size(v) == (1, )
    @test v == Int[1]

    # empty
    @test empty!(v) == Int[] == v

    # make it double
    for i in 1:5
        push!(v, i)
    end
    @test v == 1:5
    @test v.len == 5 == length(v)
    @test size(v) == (5, )
    @test length(v.parent) > 4
    @test @inferred setindex!(v, 9, 3) == 9
    w = [1, 2, 9, 4, 5]

    # sizehint!
    sizehint!(v, 20)            # up
    @test length(v.parent) == 20
    @test v == w

    sizehint!(v, 10)            # down
    @test v == w
    @test length(v.parent) == 10

    sizehint!(v, 3)             # ignored
    @test v == w
    @test length(v.parent) == 10

    @test @inferred(finish!(v)) == w
end

@testset "append!" begin
    v = Vector{Float64}()
    pv = PushVector{Float64}()
    for _ in 1:1000
        z = randn(rand(1:10))
        @test append!(v, z) == @inferred append!(pv, z)
        @test v == pv
    end
end

function pushit!(v)
    for i in 1:10^4
        push!(v, i)
    end
end

function appendit!(v, cycled)
    n = length(cycled)
    for i in 1:1000
        append!(v, cycled[(i % n) + 1])
    end
end

@testset "relative benchmarking" begin
    T_PushVector = @belapsed begin
        p = PushVector{Int64}()
        pushit!(p)
        finish!(p)
    end

    T_Vector = @belapsed begin
        p = Vector{Int64}()
        pushit!(p)
    end

    cycled = [randn(i) for i in 1:5:(5*17)]

    A_PushVector = @belapsed begin
        p = PushVector{Float64}()
        appendit!(p, $cycled)
        finish!(p)
    end

    A_Vector = @belapsed begin
        p = Vector{Float64}()
        appendit!(p, $cycled)
    end

    @info "benchmarks" T_PushVector T_Vector
    @test T_PushVector ≤ T_Vector
    @info "benchmarks" A_PushVector A_Vector
    # here just ensure that it is not much worse, testing is noisy
    @test A_PushVector ≤ A_Vector * 1.1
end
