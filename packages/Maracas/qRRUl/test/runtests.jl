using Maracas
import Maracas: AbstractTestSet, rm_spec_char, rpad_title
@testset "Maracas" begin
    @testset "'describe' returns a TestSet" begin
        @test isa(@describe("description", begin end), AbstractTestSet)
    end

    @testset "'describe' TestSet contains description" begin
        expected = "expected description"
        ts = @describe("expected description", begin end)
        @test occursin( expected, ts.description)
    end

    @testset "'describe' TestSet description is colored within 'title' env var" begin
        ts = @describe("description", begin end)
        @test occursin( MARACAS_SETTING[:title], ts.description)
    end

    @testset "'describe' TestSet description color can be changed" begin
        title_color = MARACAS_SETTING[:title]
        set_title_style(:blue)
        ts = @describe("description", begin end)
        @test occursin( Base.text_colors[:blue], ts.description)
        MARACAS_SETTING[:title] = title_color
    end

    @testset "'it' returns a TestSet" begin
        @test isa(@it("description", begin end), AbstractTestSet)
    end

    @testset "'it' TestSet contains description" begin
        expected = "expected description for it"
        ts = @it("expected description for it", begin end)
        @test occursin( expected, ts.description)
    end

    @testset "'it' TestSet contains [Spec]" begin
        ts = @it("description", begin end)
        @test occursin( "[Spec]", ts.description)
    end

    @testset "'it' TestSet description is colored within 'spec' env var" begin
        ts = @it("description", begin end)
        @test occursin( MARACAS_SETTING[:spec], ts.description)
    end

    @testset "'test' returns a TestSet" begin
        @test isa(@unit("description", begin end), AbstractTestSet)
    end

    @testset "'test' TestSet contains description" begin
        expected = "expected description for unit"
        ts = @unit("expected description for unit", begin end)
        @test occursin( expected, ts.description)
    end

    @testset "'test' TestSet contains [Test]" begin
        ts = @unit("description", begin end)
        @test occursin( "[Test]", ts.description)
    end

    @testset "'test' TestSet description is colored within 'test' env var" begin
        ts = @unit("description", begin end)
        @test occursin( MARACAS_SETTING[:test], ts.description)
    end

    @testset "padding results and descriptions" begin
        @testset "remove special chars returns empty string when special char is given" begin
            @test rm_spec_char(MARACAS_SETTING[:spec]) == ""
        end
        @testset "remove special chars returns a string with special chars removed" begin
            given = string("maracas : ", MARACAS_SETTING[:spec], "do tchik tchik tchik")
            expected = "maracas : do tchik tchik tchik"
            @test rm_spec_char(given) == expected
        end
        @testset "rpad_title of a special char returns :title_length spaces" begin
            given = MARACAS_SETTING[:test]
            expected = " "^MARACAS_SETTING[:title_length]
            @test rm_spec_char(rpad_title(given)) == expected
        end
        @testset "test title is cut when too long" begin
            given = "-"^(MARACAS_SETTING[:title_length] + 10)
            @test length(rm_spec_char(rpad_title(given))) == MARACAS_SETTING[:title_length]
        end
        @testset "test title end is replaced with ellipsis when too long" begin
            given = "-"^(MARACAS_SETTING[:title_length] + 10)
            @test rpad_title(given)[end-3:end-1] == "..."
        end

    end
end

include("doc_examples.jl")
