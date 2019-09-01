function scale_value(k::T1, from::NTuple{2,T2}, to::NTuple{2,T3}) where {T1 <: Number, T2 <: Number, T3 <: Number}
    m, M = from
    l, U = to
    inter = (k-m)/(M-m)
    return inter*(U-l)+l
end

function finish_layout!(L; link=false)
    x = getfield.(values(L), :x)
    y = getfield.(values(L), :y)
    range_x = (minimum(x), maximum(x))
    range_y = (minimum(y), maximum(y))
    range_total = (minimum([range_x..., range_y...]), maximum([range_x..., range_y...]))
    if link
        range_x = range_total
        range_y = range_total
    end
    distribute_layout!(L, range_x, range_y)
end

function distribute_layout!(L, X::NTuple{2,T}, Y::NTuple{2,T}) where {T <: Number}
    x = getfield.(values(L), :x)
    y = getfield.(values(L), :y)
    range_x = (minimum(x), maximum(x))
    range_y = (minimum(y), maximum(y))
    for k in keys(L)
        L[k].x = EcologicalNetworksPlots.scale_value(L[k].x, range_x, X)
        L[k].y = EcologicalNetworksPlots.scale_value(L[k].y, range_y, Y)
    end
end

function spread_levels!(L; ratio::Float64=1.0)
    for s in keys(L)
        L[s].y *= ratio
    end
end
