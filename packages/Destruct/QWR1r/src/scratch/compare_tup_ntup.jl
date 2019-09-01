using Base.Cartesian
using BenchmarkTools

@generated function unpack_n(v::Array{T, N}) where {M, U, T <: NTuple{M, U}, N}
    quote
        @nexprs $M i -> out_i = similar(v,U)
        @inbounds @nloops $N j v begin
            @nexprs $M i -> ((@nref $N out_i j) = (@nref $N v j)[i])
        end
        return @ntuple $M out
    end
end

@generated function unpack_t(v::Array{T,N}) where {T <: Tuple, N}
    TT = T.types
    M = length(TT)
    quote
        @nexprs $M i -> out_i = similar(v,$TT[i])
        @inbounds @nloops $N j v begin
            @nexprs $M i -> ((@nref $N out_i j) = (@nref $N v j)[i])
        end
        return @ntuple $M out
    end
end

f(a, b) = a+b, a*b, a-b

for sz in [10 50 100 200]
    packed = f.(rand(sz,sz,1), rand(1,1,sz))
    r = (@belapsed unpack_t($packed))/(@belapsed unpack_n($packed))
    println("$sz^3 : $r")
end