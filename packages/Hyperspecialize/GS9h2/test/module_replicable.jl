module ModuleReplicable

using Test
using Hyperspecialize

global A = Set{Type}([])

struct Weeble <: Real
  x::Int
end

f(::Real) = false

using Qux
import Qux.h

Qux.h(::Weeble, ::Real) = true

@testset "Module Replicable" begin

  # First, a test for module local widening

  @concretize TypicalTag []
  @replicable f(::@hyperspecialize(TypicalTag)) = true

  @test !f(1)
  @test !f(1.0)
  @test !Qux.f(1)
  @test !Qux.f(1.0)

  @widen TypicalTag Int
  @widen Qux.TypicalTag Float64

  @test f(1)
  @test !f(1.0)
  @test !Qux.f(1)
  @test Qux.f(1.0)

  # Do all methods corresponding to a type get widened?

  @test !Qux.g(1)
  @test Qux.g(1.0)

  # Can we resolve ambiguities?

  @test_throws MethodError h(Weeble(1), Wobble(2))

  @replicable h(::Weeble, ::@hyperspecialize(Real)) = true

  @test h(Weeble(1), Wobble(2))

end

end #module
