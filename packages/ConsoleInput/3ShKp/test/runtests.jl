using Test, ConsoleInput

origin_stdin = stdin
test_in = open("./test.txt", "r")
redirect_stdin(test_in)

@testset "DlmType" begin
    @test isa(' ', ConsoleInput.DlmType)
    @test isa("abc", ConsoleInput.DlmType)
    @test isa(r"^\s*(?:#|$)", ConsoleInput.DlmType)

    function dlm()::String
            "false"
    end
    @test isa(dlm(), ConsoleInput.DlmType)
end

@testset "readInt" begin
    @test ConsoleInput.readInt(test_in) == 1
    @test ConsoleInput.readInt(test_in) == [1, 2, 3, 4, 5]
    @test ConsoleInput.readInt(test_in, ",") == [6, 7, 8, 9, 10]
end

@testset "readString" begin
    @test ConsoleInput.readString(test_in) == "Lorem"
    @test ConsoleInput.readString(test_in) == ["Lorem", "ipsum", "es", "simplemente"]
    @test ConsoleInput.readString(test_in, ";") == ["consectetur", "adipiscing", "elit"]
end

@testset "readGeneral" begin
    @test ConsoleInput.readGeneral(Float64, test_in) == 0.0012
    @test ConsoleInput.readGeneral(Complex{Float64}, test_in) == 0.32 + 4.5im
    @test ConsoleInput.readGeneral(Complex{Int}, test_in) == [1+5im, 10-4im, -9+8im]
end
close(test_in)
redirect_stdin(origin_stdin)
