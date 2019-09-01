"""
Implementation of local response normalization.
"""
module LRNs
using Flux

export LRN

"""
    LRN{T,I}

Local response normalization layer. Input `i` is processed according to
out(x,y,f,b) = x * [b + α * sum( i(x, y, f-k÷2:f+k÷2, b)^2 )]^(-β)

Todo: β is currently ignored (always set to 0.5)
"""
struct LRN{T,I}
    b::T
    α::T
    β::T
    k::I
end

"""
    (l::LRN)(i)

Applies a local response normalization layer according to:
out(x,y,f,b) = x * [c + α * sum( i(x, y, f-k÷2:f+k÷2, b)^2 )]^(-β)

Todo: β is currently ignored (always set to 0.5)
"""
function (l::LRN)(x)
    ω = similar(x)
    fsize = size(x, 3)
    depth = l.k ÷ 2
    buffer = similar(x, size(x, 1), size(x, 2), 2*depth+1, size(x, 4))
    for i ∈ 1:fsize
        f_min = max(1, i - depth)
        f_max = min(fsize, i + depth)
        buffer = Flux.Tracker.data(x[:, :, f_min:f_max, :])
        ω[:, :, i, :] = sum(buffer.^2, dims=3)
    end
    return x ./ sqrt.(l.b .+ l.α .* ω)
end # function (l::LRN)

Flux.@treelike LRN

# convenience constructor with default arguments
function LRN(; b=1.0, α=1.0, β=0.5, k=5)
    return LRN(b, α, β, k)
end # function LRN
end # module LRNs
