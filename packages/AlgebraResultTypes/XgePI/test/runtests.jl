using AlgebraResultTypes: result_field, result_ring, number_type
using Test, Random
import ForwardDiff

####
#### add to this list to test for more types
####

TEST_TYPES = (# Base
              Float64, Int, Rational{Int}, Complex{Float64}, Rational{Int16}, Int8,
              Float32,
              # packages -- ADD TESTS HERE
              ForwardDiff.Dual{:foo,Float64,3})

####
#### deterministic tests
####

function test_field(a)
    abs2(a + a + one(a))/(-a)
end

function test_field(a, b)
    abs2(a + a + one(a))/(-a) + (a/b - b/a + a/a + b/b)
end

function test_ring(a)
    abs2(a + a + one(a))*(-a)
end

function test_ring(a, b)
    abs2(a + a + one(a))*(-a) + (a*b - b*a + a - b)
end

@testset "result_field deterministic tests" begin
    @test result_field(Real) ≡ Number
    for T in TEST_TYPES
        @test typeof(test_field(one(T))) ≡ result_field(T)
        @test result_field(T, Real) ≡ Number
        for S in TEST_TYPES
            @test typeof(test_field(one(T), one(S))) ≡ result_field(T, S)
            @test result_field(T, S, Real) ≡ Number
            for Z in TEST_TYPES
                @test typeof(test_field(one(T), test_field(one(S), one(Z)))) ≡ result_field(T, S, Z)
            end
        end
    end
end

@testset "result_ring deterministic tests" begin
    @test result_ring(Real) ≡ Number
    for T in TEST_TYPES
        @test typeof(test_ring(one(T))) ≡ result_ring(T)
        @test result_ring(T, Real) ≡ Number
        for S in TEST_TYPES
            @test typeof(test_ring(one(T), one(S))) ≡ result_ring(T, S)
            @test result_ring(T, S, Real) ≡ Number
            for Z in TEST_TYPES
                @test typeof(test_ring(one(T), test_ring(one(S), one(Z)))) ≡ result_ring(T, S, Z)
            end
        end
    end
end

####
#### random tests
####

function all_combinations(ops, types)
    A = [op(one(T), one(S)) for T in types, S in types, op in ops]
    reduce(-, A)                # NOTE: avoid `sum` as it widens
end

RING_OPS = (+, -, *)
FIELD_OPS = (RING_OPS..., /)

randsub(x) = shuffle([x...])[1:rand(1:length(x))]

@testset "ring random tests" begin
    for _ in 1:10000
        Ts = randsub(TEST_TYPES)
        y = all_combinations(RING_OPS, Ts)
        T = result_ring(Ts...)
        @test y isa T
        y isa T || @info "test failure ring" Ts y T
    end
end

@testset "field random tests" begin
    for _ in 1:10000
        Ts = randsub(TEST_TYPES)
        y = all_combinations(FIELD_OPS, Ts)
        T = result_field(Ts...)
        @test y isa T
        y isa T || @info "test failure field" Ts y T
    end
end

####
#### utilities
####

@testset "number type" begin
    @test number_type(1) ≡ Int
    @test number_type([2.0, 4.0]) ≡ Float64
    @test number_type(Real[3.0]) ≡ Real
    @test_throws MethodError number_type(Any[1.0])
end
