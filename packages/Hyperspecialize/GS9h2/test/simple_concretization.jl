@testset "Simple Concretization Gala" begin
  # Did you pregame the gala?
  @test @concretization(Pregame) == Set{Type}([String])
end

module SimpleConcretization

using Test
using Hyperspecialize


@testset "Simple Concretization" begin

  # Can we concretize an abstract type to a subset of its concrete types?
  @test (@concretize Integer [Int64]) == Set{Type}([Int64])
  @test @concretization(Integer) == Set{Type}([Int64])
  # Can we widen our type?
  @test @widen(Integer, Int8) == Set{Type}([Int8, Int64])
  @test @concretization(Integer) == Set{Type}([Int8, Int64])
  # If we widen again with a duplicate type, it's not repeated right?
  @test (@widen Integer (Int8, Int16)) == Set{Type}([Int8, Int16, Int64])
  @test @concretization(Integer) == Set{Type}([Int8, Int16, Int64])

  # What is the concretization without any previous calls to concretize?
  @test @concretization(Unsigned) == nothing
  # We should be able to widen the concretization of an abstract type to include a non-subtype.
  @test @widen(Unsigned, Bool) == Set{Type}([UInt128, UInt16, UInt32, UInt64, UInt8, Bool])
  @test @concretization(Unsigned) == Set{Type}([UInt128, UInt16, UInt32, UInt64, UInt8, Bool])

  # Can we concretize a non-type without any previous calls to concretize?
  @test_throws ErrorException @concretize(NotAType)
  @test @concretize(NotAType, []) == Set{Type}()
  # We should be able to widen the concretization of a non-type
  @test @widen(NotAType, Bool) == Set{Type}([Bool])
  @test @concretization(NotAType) == Set{Type}([Bool])

  # What happens if we widen a non-concretized type?
  @test @widen(Signed, Bool) == Set{Type}([BigInt, Int128, Int16, Int32, Int64, Int8, Bool])
  @test @concretization(Signed) == Set{Type}([BigInt, Int128, Int16, Int32, Int64, Int8, Bool])

  # Can we concretize a concrete type to be something else?
  @test @concretize(Int8, Bool) == Set{Type}([Bool])
  @test @concretization(Int8) == Set{Type}([Bool])

  # Can we widen a non-existent non-concretized type?
  @test_throws ErrorException @widen(StillNotAType, Float32)
  @test @concretize(StillNotAType, []) == Set{Type}([])
  @test @widen(StillNotAType, Float32) == Set{Type}([Float32])
  @test @concretization(StillNotAType) == Set{Type}([Float32])

  # Can we concretize a type to be nothing?
  @test @concretize(Int16, []) == Set{Type}()
  @test @concretization(Int16) == Set{Type}()

  # We can concretize using a variable.
  x = Int64
  @test @concretize(Int32, [x]) == Set{Type}([Int64])
  @test @concretization(Int32) == Set{Type}([Int64])

  # We cannot concretize the contents of a variable.
  x = Int64
  @test @concretize(x, (Int32,)) == Set{Type}([Int32])
  @test @concretization(x) == Set{Type}([Int32])
  @test @concretization(Int64) == nothing

  # What if we set the concretization before we define the type?
  @test @concretize(Wobble, []) == Set{Type}([])
  @test @concretization(Wobble) == Set{Type}([])

  # Cannot reconcretize
  @test_throws ErrorException (@concretize Signed Int64)

end

struct Wobble
  w::Float32
end

@testset "Simple Concretization Afterparty" begin

  # Concretization is still messed up.
  @test @concretization(Wobble) == Set{Type}([])

  # We can add the type after...
  @test @widen(Wobble, Wobble) == Set{Type}([Wobble])

end

end #module
