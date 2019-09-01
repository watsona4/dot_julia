using Destruct
using BenchmarkTools

unpack_bc(w::Array{<:Tuple}) = Tuple((v->v[i]).(w) for i=1:length(w[1]))

f(a, b) = a+b, a*b, a-b
println("getindex-broadcast / destruct")
println("  Homogeneous types")
packed = f.(rand(2,2,1), rand(1,1,2))
println("$(typeof(packed))")
for sz in [10 50 100]
    packed = f.(rand(sz,sz,1), rand(1,1,sz))
    r = (@belapsed unpack_bc($packed))/(@belapsed destruct($packed))
    println("    $sz^3 : $r")
end
println("")

g(a, b) = a+b+1im*(a-b), a*b, convert(Int, round(a-b))

println("  Heterogeneous types")
packed = g.(rand(2,2,1), rand(1,1,2))
println("$(typeof(packed))")
for sz in [10 50 100]
    packed = g.(rand(sz,sz,1), rand(1,1,sz))
    r = (@belapsed unpack_bc($packed))/(@belapsed destruct($packed))
    println("    $sz^3 : $r")
end
