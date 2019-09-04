using TenPuzzle
using Test

@testset "Basic fetures" begin
  @testset "Typical problems" begin
      @test maketen(10) == "10"
      @test maketen(5, 5) == "5 + 5"
      
      @test maketen(1, 1, 9, 9) in (
          "(1 + 1 / 9) * 9", "(1 / 9 + 1) * 9",
          "9 * (1 + 1 / 9)", "9 * (1 / 9 + 1)"
      )
  end

end
