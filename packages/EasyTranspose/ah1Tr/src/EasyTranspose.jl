module EasyTranspose

export ᵀ

struct ᵀ end
Base.:(*)(arr::AbstractVecOrMat,::typeof(ᵀ)) = permutedims(arr)

end # module
