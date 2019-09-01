using Destruct
using BenchmarkTools

function unpack_bc(w::Array{<:Tuple})
    Tuple((v->v[i]).(w) for i=1:length(w[1]))
end

# some transform
f(a, b) = a+b, a*b, a-b
# some transform with different return types
g(a, b) = a+b+1im*(a-b), a*b, convert(Int, round(a-b))

shape = (10,10)
a_1 = rand(shape)
a_2 = rand(shape)
a_3 = rand(shape)
unpacked = (a_1, a_2, a_3)
packed = collect(zip(a_1, a_2, a_3))

@assert unpack_bc(packed) == unpacked
@assert destruct(packed) == unpacked

println("Array of NTuple")
println("---------------")
for sz=[10 100 200]
    packed = f.(rand(sz,sz,1), rand(1,1,sz))
    shape = size(packed)
    println("shape: $shape")
    println("broadcast")
    @btime unpack_bc($packed)
    println("cartesian")
    @btime destruct($packed)
    println("")
end
println("Array of Tuple")
println("--------------")
for sz=[10 100 200]
    packed = g.(rand(sz,sz,1), rand(1,1,sz))
    shape = size(packed)
    println("shape: $shape")
    println("broadcast")
    @btime unpack_bc($packed)
    println("cartesian")
    @btime destruct($packed)
    println("")
end
