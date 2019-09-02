# test file for LittleEndianBase128.jl
using Test

include("../src/LittleEndianBase128.jl")
using .LittleEndianBase128

println("Testing LittleEndianBase128 encoding and decoding.")

print("Known results ... ")
@test encode(UInt32(624485)) ==  UInt8[0xe5,0x8e,0x26]
@test encode(UInt64(2147483647)) == UInt8[0xff,0xff,0xff,0xff,0x07]
@test encode(-1) == UInt8[0x01]
@test encode(0) == UInt8[0x00]
@test encode(2147483647) == UInt8[0xfe,0xff,0xff,0xff,0x0f]
@test encode(-2147483647) == UInt8[0xfd,0xff,0xff,0xff,0x0f]
@test decodesigned(encode(-2147483647)) == [-2147483647]
@test decode(UInt8(0x01)) == [0x01]
println("PASS")

println("Type min and max ...")
types = [UInt8, UInt16, UInt32, UInt64, UInt64, Int8, Int16, Int32, Int64, Int64, Bool]
n = 3
for t in types
  a = typemin(t)
  b = typemax(t)
  print("$t min ... ")
  u = decode(encode(a),t)[1]
  @test u == a
  @test typeof(u) == typeof(a)
  println("PASS")
  print("$t max ... ")
  u = decode(encode(b),t)[1]
  @test u == b
  @test typeof(u) == typeof(b)
  println("PASS")
  print("$t random $n x $n matrix ...")
  x = rand(a:b, n, n)
  y = reshape(decode(encode(x),t), n, n)
  @test x == y
  println("PASS")
end
