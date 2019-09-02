using FileIO
using Test

@testset "Basic checks" begin
  fname = tempname()*".gslib"

  prop1 = rand(10,10,10)
  prop2 = rand(10,10,10)

  save(fname, [prop1,prop2])
  grid = load(fname)
  @test grid[:prop1] == prop1
  @test grid[:prop2] == prop2

  save(fname, grid)
  grid = load(fname)
  @test grid[:prop1] == prop1
  @test grid[:prop2] == prop2

  save(fname, prop1)
  grid = load(fname)
  @test grid[:prop1] == prop1

  rm(fname)
end
