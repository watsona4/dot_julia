using Pushover
using Pushover: _sanitize_priority, _crop
using Test
#using Lint  # unsupported Julia 0.7 version as of 2018/08/19

@testset "Pushover" begin
    @testset "_sanitize_priority" begin
        @test _sanitize_priority(-2) == -2
        @test _sanitize_priority(-1) == -1
        @test _sanitize_priority(0) == 0
        @test _sanitize_priority(1) == 1

        @test _sanitize_priority(100) == 0
        @test _sanitize_priority(-100) == 0
        @test _sanitize_priority("abc") == 0
    end

    @testset "_crop" begin
        max_len = 30
        msg = "Lorem ipsum dolor sit amet"
        cropped_msg = _crop(msg, max_len)
        @test cropped_msg == msg
        @test length(cropped_msg) == length(msg)
        @test length(cropped_msg) <= max_len

        msg = "Lorem ipsum dolor sit amet, consectetur adipiscing elit."
        cropped_msg = _crop(msg, max_len)
        @test length(cropped_msg) == max_len
        @test cropped_msg[end-2:end] == "..."
    end

    #@testset "lint" begin
    #    @test isempty(lintpkg("Pushover"))
    #end
end
