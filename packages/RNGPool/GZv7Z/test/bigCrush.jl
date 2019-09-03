using RNGTest
include("circularRNG.jl")

@time out = RNGTest.bigcrushJulia(generator)
println("\nBig Crush p-values:\n")
for i in eachindex(out)
  println(out[i])
end
minpv = 1.0
for i in eachindex(out)
  minpv = min(minpv, minimum(out[i]))
end
println("\nSmallest p-value = ", minpv)
