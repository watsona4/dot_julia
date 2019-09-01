using ExtensibleUnions
using Test
using Traceur

macro genstruct!(list)
    x = gensym()
    y = quote
        struct $(x) end
        push!($(list), $(x))
    end
    return y
end

# macro genfunc!(list)
#     x = gensym()
#     y = quote
#         function $(x) end
#         push!($(list), $(x))
#     end
#     return y
# end

@testset "ExtensibleUnions.jl" begin
    @testset "Unit tests" begin
        @testset "test_code_transformation.jl" begin
            include("test_code_transformation.jl")
        end
        @testset "test_extensible_functions.jl" begin
            include("test_extensible_functions.jl")
        end
        @testset "test_extensible_unions.jl" begin
            include("test_extensible_unions.jl")
        end
        @testset "test_inferred.jl" begin
            include("test_inferred.jl")
        end
        @testset "test_traceur.jl" begin
            include("test_traceur.jl")
        end
        @testset "test_update_methods.jl" begin
            include("test_update_methods.jl")
        end
    end
    @testset "Integration tests" begin
        @testset "test_examples.jl" begin
            include("test_examples.jl")
        end
    end
    @testset "reset.jl" begin
        @testset "ExtensibleUnions._unsafe_reset!()" begin
            ExtensibleUnions._unsafe_reset!()
            @test isempty(ExtensibleUnions._registry_extensibleunion_to_genericfunctions)
            @test isempty(ExtensibleUnions._registry_extensibleunion_to_members)
            @test isempty(ExtensibleUnions._registry_genericfunctions_to_extensibleunions)
        end
    end
end
