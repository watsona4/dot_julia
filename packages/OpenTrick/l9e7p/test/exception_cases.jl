using Test
using OpenTrick


@testset "open failed" begin
    @debug "open failed test"
    @test_throws SystemError opentrick(open, "nosuchfile.txt")
    @debug "before test length"
    @test length(OpenTrick.tasks_pending) == 0
end