using ModelSanitizer
using Test

function _inner_runtests()::Nothing
    @testset "Unit tests" begin
        @debug("Running unit tests...")
        @testset "unit-tests/test-dataframes.jl" begin
            @debug("unit-tests/test-dataframes.jl")
            include("unit-tests/test-dataframes.jl")
        end
        @testset "unit-tests/test-elements.jl" begin
            @debug("unit-tests/test-elements.jl")
            include("unit-tests/test-elements.jl")
        end
        @testset "unit-tests/test-sanitize.jl" begin
            @debug("unit-tests/test-sanitize.jl")
            include("unit-tests/test-sanitize.jl")
        end
        @testset "unit-tests/test-utils.jl" begin
            @debug("unit-tests/test-utils.jl")
            include("unit-tests/test-utils.jl")
        end
        @testset "unit-tests/test-zero.jl" begin
            @debug("unit-tests/test-zero.jl")
            include("unit-tests/test-zero.jl")
        end
    end
    @testset "Integration tests" begin
        @debug("Running integration tests...")
        @testset "integration-tests/test-proof-of-concept-dataframes.jl" begin
            @debug("integration-tests/test-proof-of-concept-dataframes.jl")
            include("integration-tests/test-proof-of-concept-dataframes.jl")
        end
        @testset "integration-tests/test-proof-of-concept-linearmodel" begin
            @debug("integration-tests/test-proof-of-concept-linearmodel.jl")
            include("integration-tests/test-proof-of-concept-linearmodel.jl")
        end
        if Base.JLOptions().can_inline > 0
            @testset "integration-tests/test-proof-of-concept-mlj.jl" begin
                @debug("integration-tests/test-proof-of-concept-mlj.jl")
                include("integration-tests/test-proof-of-concept-mlj.jl")
            end
        end
    end
    return nothing
end

function runtests()::Nothing
    @sync begin
        _test_runner = @async begin
            _inner_runtests()
        end
        @async begin
            while !istaskdone(_test_runner)
                sleep(60)
                @debug("[[ModelSanitizer tests are still running...]]")
            end
        end
    end
    return nothing
end

@testset "ModelSanitizer.jl" begin
    runtests()
end
