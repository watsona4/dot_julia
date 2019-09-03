
include("../src/RawArray.jl")
using .RawArray
using Test

print("raquery ... ")
s = raquery("../examples/test.ra")
@test s == "---\nname: ../examples/test.ra\nendian: little\ncompressed: 0\nbits: 0\ntype: Complex{Float32}\nsize: 96\ndimension: 2\nshape:\n  - 3\n  - 4\n..."
println("PASS")


function test_wr(t, dims; compress=false)
  testfile = "tmp.ra"
  n = length(dims)
  print("Testing $n-d $t $(compress ? "compressed" : "uncompressed") ... ")
  if t == BitArray
    data = BitArray(rand(Bool, dims...))
  else
    data = rand(t, dims...)
  end
  rawrite(data, testfile; compress=compress)
  data2 = raread(testfile)
  @test isequal(data, data2)
  rm(testfile)
  println("PASS")
end

typelist = [Float16, Float32, Float64, Complex{Float16}, Complex{Float32}, Complex{Float64}, Int8, Int16, Int32, Int64, UInt8, UInt16, UInt32, UInt64, Bool, BitArray]
maxdims = 4
for t in typelist, n in 1:maxdims
  test_wr(t, collect(2:n+1))
  if t <: Integer && t != BitArray
    test_wr(t, collect(2:n+1); compress=true)
  end
end
