module ModuleConcretization

using Test
using Hyperspecialize

@testset "Module Concretization" begin

  # Let's concretize a couple things, then load a module and see what happens
  @test (@concretize NotAType [Int32]) == Set{Type}([Int32])
  @test (@concretize Float32 [Float64]) == Set{Type}([Float64])
  @test (@concretize AlsoNotAType []) == Set{Type}([])
  @test (@widen AlsoNotAType Int32) == Set{Type}([Int32])
  @test (@widen Float64 (Float32)) == Set{Type}([Float32, Float64])
  @test (@concretization NotAType) == Set{Type}([Int32])
  @test (@concretization Float32) == Set{Type}([Float64])
  @test (@concretization AlsoNotAType) == Set{Type}([Int32])
  @test (@concretization Float64) == Set{Type}([Float32, Float64])

end

import Foo

@testset "Module Concretization Afterparty" begin
  foo = Foo
  bar = Foo.Bar

  # Just checking out the concretizations of these packages.
  @test (@concretization NotAType) == Set{Type}([Int32])
  @test (@concretization Float32) == Set{Type}([Float64])
  @test (@concretization ModuleConcretization.AlsoNotAType) == Set{Type}([Int32])
  @test (@concretization Float64) == Set{Type}([Float32, Float64])
  @test (@concretization Foo.Bar.NotAType) == Set{Type}([UInt64])
  @test (@concretization foo.Bar.Float32) == Set{Type}([UInt128])
  @test (@concretization bar.AlsoNotAType) == Set{Type}([Int64])
  @test (@concretization Foo.Bar.Float64) == Set{Type}([UInt16, Float32])

  # Cannot reconcretize or concretize in other packages
  @test_throws ErrorException @concretize(Foo.NotAType)
  @test_throws ErrorException @concretize foo.Float32
  @test_throws ErrorException (@concretize foo.Float32 Int64)

  # Let's make sure that changes to modules are module-local
  @test @widen(Foo.Bar.NotAType, Bool) == Set{Type}([UInt64, Bool])
  @test (@concretization NotAType) == Set{Type}([Int32])
  @test @concretization(Foo.Bar.NotAType) == Set{Type}([UInt64, Bool])
end

import Foo.Bar

@testset "Module Concretization Late Night" begin
  # Let's make sure that modules have a unique storage for concretization
  @test @concretization(Bar.NotAType) == Set{Type}([UInt64, Bool])
end

end #module
