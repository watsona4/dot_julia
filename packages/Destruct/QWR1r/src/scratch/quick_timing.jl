using Unpack
using BenchmarkTools

function unpack_bc(w::Array{<:Tuple})
    Tuple((v->v[i]).(w) for i=1:length(w[1]))
end

g(a, b) = a+1im*b, a*b, convert(Int, round(a-b))
packed = g.(rand(100,100,1), rand(1,1,100))
println("Broadcast")
@btime unpack_bc($packed)
println("Cartesian")
@btime unpack($packed)