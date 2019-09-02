using LayerDicts
using Test

# Write your own tests here.
@testset "LayerDicts" begin

@testset "Constructors" begin
    # Parameters matching
    @test LayerDict(Dict{Int, Int}(), Dict{Int, Int}()) isa LayerDict{Int, Int}
    @test LayerDict((Dict{Int, Int}(), Dict{Int, Int}())) isa LayerDict{Int, Int}
    @test LayerDict([Dict{Int, Int}(), Dict{Int, Int}()]) isa LayerDict{Int, Int}

    # One parameter matching
    @test LayerDict(Dict{Int, Int}(), Dict{String, Int}()) isa LayerDict{Any, Int}
    @test LayerDict((Dict{Int, Int}(), Dict{String, Int}())) isa LayerDict{Any, Int}
    @test LayerDict([Dict{Int, Int}(), Dict{String, Int}()]) isa LayerDict{Any, Int}

    # One parameter promoting
    @test LayerDict(Dict{Int, Int}(), Dict{Float64, Int}()) isa LayerDict{Real, Int}
    @test LayerDict((Dict{Int, Int}(), Dict{Float64, Int}())) isa LayerDict{Real, Int}
    @test LayerDict([Dict{Int, Int}(), Dict{Float64, Int}()]) isa LayerDict{Real, Int}

    # Promoting to Any
    @test LayerDict(Dict{Any, Int}(), Dict{Float64, Any}(), Dict{Float64, Int}()) isa LayerDict{Any, Any}
    @test LayerDict((Dict{Any, Int}(), Dict{Float64, Any}(), Dict{Float64, Int}())) isa LayerDict{Any, Any}
    @test LayerDict([Dict{Any, Int}(), Dict{Float64, Any}(), Dict{Float64, Int}()]) isa LayerDict{Any, Any}

    # No dicts
    @test LayerDict() isa LayerDict{Any, Any}
    @test LayerDict(()) isa LayerDict{Any, Any}
    @test LayerDict(AbstractDict[]) isa LayerDict{Any, Any}
end

dict1 = Dict{Symbol, Int}(:foo => 1, :bar => 1)
dict2 = Dict{Symbol, Int}()
dict3 = Dict{Symbol, Int}(:bar => 3, :baz => 3)

ld = LayerDict{Symbol, Int}([dict1, dict2, dict3])

@testset "Getters" begin
    @testset "getindex" begin
        @test ld[:foo] == 1
        @test ld[:bar] == 1
        @test ld[:baz] == 3
        @test_throws KeyError ld[:quuz]
    end

    @testset "get (default value)" begin
        default = 4
        @test get(ld, :foo, default) == 1
        @test get(ld, :bar, default) == 1
        @test get(ld, :baz, default) == 3
        @test get(ld, :quuz, default) == 4
    end

    @testset "get (default function)" begin
        default = () -> 4
        @test get(default, ld, :foo) == 1
        @test get(default, ld, :bar) == 1
        @test get(default, ld, :baz) == 3
        @test get(default, ld, :quuz) == 4
    end

    @testset "haskey" begin
        @test haskey(ld, :foo)
        @test haskey(ld, :bar)
        @test haskey(ld, :baz)
        @test !haskey(ld, :quuz)
    end

    @testset "in" begin
        @test (:foo => 1) in ld
        @test (:bar => 1) in ld
        @test (:baz => 3) in ld
        @test !((:foo => 2) in ld)
        @test !((:bar => 3) in ld)
        @test !((:quuz => 4) in ld)
    end
end

@testset "Iterators" begin
    @testset "Pairs" begin
        pair_vec = collect(ld)
        @test length(pair_vec) == 3
        pair_set = Set(pair_vec)
        @test pair_set == Set([:foo => 1, :bar => 1, :baz => 3])
    end

    @testset "Keys" begin
        key_vec = collect(keys(ld))
        @test length(key_vec) == 3
        key_set = Set(key_vec)
        @test key_set == Set([:foo, :bar, :baz])
    end

    @testset "Values" begin
        val_vec = sort!(collect(values(ld)))
        @test val_vec == [1, 1, 3]
    end
end

end
