@testset "Splitters" begin
    name = "testname"
    s = Splitter(name)
    @test s.name == name
    @test splitname(s) == name
end # @testset "Splitters"
