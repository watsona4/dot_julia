unpack(v::StaticVector{2}) = @inbounds return v[1], v[2]

@inline function cross2(v1::StaticVector{2}, v2::StaticVector{2})
    x1, y1 = unpack(v1)
    x2, y2 = unpack(v2)
    x1 * y2 - x2 * y1
end

normsquared(x) = sum(y -> y^2, x)
