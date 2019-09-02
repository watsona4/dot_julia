"""
Renko chart patterns

# Methods

- Traditional (Constant Box Size): `renko(x::Array{Float64}; box_size::Float64=10.0)::Array{Int}`
- ATR Dynamic Box Size: `renko(hlc::Matrix{Float64}; box_size::Float64=10.0, use_atr::Bool=false, n::Int=14)::Array{Int}`

# Output

`Array{Int}` object of size Nx1 (where N is the number rows in `x`) where each element gives the Renko bar number of the corresponding row in `x`.

"""
function renko(x::Array{Float64}; box_size::Float64=10.0)::Array{Int}
    # Renko chart bar identification with traditional methodology (constant box size)
    @assert box_size != 0
    "Argument `box_size` must be nonzero."
    if box_size < 0.0
        box_size = abs(box_size)
    end
    bar_id = ones(Int, size(x,1))
    ref_pt = x[1]
    @inbounds for i in 2:size(x,1)
        if abs(x[i]-ref_pt) >= box_size
            ref_pt = x[i]
            bar_id[i:end] .+= 1
        end
    end
    return bar_id
end

function renko(hlc::Matrix{Float64}; box_size::Float64=10.0, use_atr::Bool=false, n::Int=14)::Array{Int}
    # Renko chart bar identification with option to use ATR or traditional method (constant box size)
    if use_atr
        bar_id = ones(Int, size(hlc,1))
        box_sizes = atr(hlc, n=n)
        x = hlc[:,3]
        ref_pt = x[1]
        @inbounds for i in 2:size(x,1)
            if abs(x[i]-ref_pt) >= box_sizes[i]
                ref_pt = x[i]
                bar_id[i:end] .+= 1
            end
        end
        return bar_id
    else
        return renko(hlc[:,3], box_size=box_size)
    end
end

