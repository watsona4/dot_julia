using RNGTest
using Test

include("circularRNG.jl")

@time out = RNGTest.smallcrushJulia(generator)
println("\nSmall Crush p-values:\n")
for i in eachindex(out)
  println(out[i])
end
minpv = 1.0
for i in eachindex(out)
  global minpv = min(minpv, minimum(out[i]))
  @test minimum(out[i]) > 1e-4
end
println("Smallest p-value = ", minpv)
