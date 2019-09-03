function memcalloc(p, zs, yv)
    maxobs  = maximum(length.(yv))
    memc = Array{Array{Float64, 2}, 1}(undef, maxobs)
    memc2 = Array{Array{Float64, 2}, 1}(undef, maxobs)
    memc3 = Array{Array{Float64, 1}, 1}(undef, maxobs)
    for i = 1:maxobs
        memc[i] = zeros(i, zs)
        memc2[i] = zeros(p, i)
        memc3[i] = zeros(i)
    end
    memc4 = zeros(p, p)
    return memc, memc2, memc3, memc4
end
