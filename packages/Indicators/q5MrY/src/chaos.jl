# #TODO: finish
# function hilbert_transform(x::Array{Float64}; n::Int=10)
# end

function estimate_rsrange(x::Vector{T})::Float64 where T<:Real
    n = size(x,1)
    @assert n>2 "need more than two elements, have $x"
    m = sum(x)/n
    y = x .- m
    z = cumsum(y)
    r = maximum(z) - minimum(z)
    s = sqrt(sum((x.-m).^2)/n)
    return r/s
end

function npieces(x::Vector{T}, minsize::Int=8)::Int where {T<:Real}
    i = 0
    n = size(x,1)
    while n > minsize
        i += 1
        n = fld(n, 2)
    end
    return i
end

function genrsdata(x::Vector{T})::Matrix{Float64} where {T<:Real}
    depth = npieces(x)
    if depth == 0
        return [size(x,1) estimate_rsrange(x)]
    end
    rsdata = zeros(0,2)
    rsdata = [rsdata; [size(x,1) estimate_rsrange(x)]]
    a, b = divide(x)
    rsdata = [rsdata; genrsdata(a)]
    rsdata = [rsdata; genrsdata(b)]
    return rsdata
end

function divide(x::A)::Tuple{A, A} where {A<:AbstractArray}
    n = size(x,1)
    @assert n>=2
    h = n/2
    a = x[1:floor(Int,h)]
    if floor(h) == h
        b = x[(ceil(Int,h)+1):end]
    else
        b = x[ceil(Int,h):end]
    end
    return a, b
end

function estimate_hurst(x; intercept::Bool=false)::Float64
    RS = genrsdata(x)
    RS = RS[sortperm(RS[:,1]),:]
    xx = log2.(RS[:,1])
    yy = log2.(RS[:,2])
    if intercept
        _, beta = [ones(size(xx)) xx]\yy
    else
        beta = xx\yy
    end
    return beta
end

"""
```
rsrange(x::Array{Float64}; n::Int=100, cumulative::Bool=false, intercept::Bool=true)
```

Compute the rescaled range of a time series
"""
function rsrange(x::Array{Float64}; n::Int=100, cumulative::Bool=false, intercept::Bool=true)
    @assert size(x,1) >= n
    return runfun(x, estimate_rsrange; n=n, cumulative=cumulative)
end

"""
```
hurst(x::Array{Float64}; n::Int=100, cumulative::Bool=false, intercept::Bool=false)
```

Compute the Hurst exponent of a time series
"""
function hurst(x::Array{Float64}; n::Int=100, cumulative::Bool=false, intercept::Bool=false)
    @assert size(x,1) >= n
    return runfun(x, estimate_hurst; n=n, cumulative=cumulative, intercept=intercept)
end
