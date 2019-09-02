module SimpleReplicable

using Test
using Hyperspecialize

global A = Set{Type}([])

f(::Real) = false
g(::Signed, ::Unsigned) = false
h(::Signed, ::Signed, ::Unsigned) = false

@testset "Simple Replicable" begin

  # First, checking if the hyperspecialization works like concretization
  empty!(A)

  @replicable begin
    push!(A, @hyperspecialize Real)
  end

  @test A == Set{Type}(Hyperspecialize.concretesubtypes(Real))

  empty!(A)

  @concretize NotAType []

  @replicable begin
    push!(A, @hyperspecialize NotAType)
  end

  @test A == Set{Type}()

  @test_throws ErrorException (@concretize NotAType Int8)

  @widen NotAType Int8

  @test A == Set{Type}([Int8])

  empty!(A)

  # Can we widen and then get replicables to follow?

  @replicable function f(::@hyperspecialize(NotAType))
    return true
  end

  @test !f(1.0)
  @test f(Int8(1))

  @widen NotAType Float64

  @test f(1.0)

  # What happens if a replicable has no hyperspecializes?

  @replicable function f(::String)
    return true
  end

  @test f("hello")

  # How does specialization interact with multiple hyperspecials?

  @concretize Signed (Int8, Int16)
  @concretize Unsigned []

  @replicable function g(::@hyperspecialize(Signed), ::@hyperspecialize(Unsigned))
    return true
  end

  @test !g(Int8(1), UInt8(1))
  @test !g(Int16(1), UInt8(1))
  @test !g(Int8(1), UInt16(1))
  @test !g(Int16(1), UInt16(1))

  @widen Unsigned [UInt8, UInt16]

  @test g(Int8(1), UInt8(1))
  @test g(Int16(1), UInt8(1))
  @test g(Int8(1), UInt16(1))
  @test g(Int16(1), UInt16(1))

  @test !h(Int8(1), Int8(1), UInt8(1))
  @test !h(Int16(1), Int8(1), UInt8(1))
  @test !h(Int8(1), Int16(1), UInt8(1))
  @test !h(Int16(1), Int16(1), UInt8(1))
  @test !h(Int8(1), Int8(1), UInt16(1))
  @test !h(Int16(1), Int8(1), UInt16(1))
  @test !h(Int8(1), Int16(1), UInt16(1))
  @test !h(Int16(1), Int16(1), UInt16(1))

  @replicable function h(::@hyperspecialize(Signed), ::@hyperspecialize(Signed), ::@hyperspecialize(Unsigned))
    return true
  end

  @test h(Int8(1), Int8(1), UInt8(1))
  @test h(Int16(1), Int8(1), UInt8(1))
  @test h(Int8(1), Int16(1), UInt8(1))
  @test h(Int16(1), Int16(1), UInt8(1))
  @test h(Int8(1), Int8(1), UInt16(1))
  @test h(Int16(1), Int8(1), UInt16(1))
  @test h(Int8(1), Int16(1), UInt16(1))
  @test h(Int16(1), Int16(1), UInt16(1))

  @test !h(Int32(1), Int16(1), UInt16(1))
  @test !h(Int16(1), Int16(1), UInt64(1))

end

end #module
