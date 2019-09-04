type Dimension
    size::Int64
    regions
    types
end

function dim_rand_sample(dim::Dimension)
    x = []
    for i = 1:dim.size
        value = 0
        if dim.types[i] == true
            value = rand(rng, Float64) * (dim.regions[i][2] - dim.regions[i][1]) + dim.regions[i][1]
        else
            value = rand(rng, dim.regions[i][1]:dim.regions[i][2])
        end
        append!(x, value)
    end
    return x
end

function dim_limited_space(dim::Dimension)
    number = 1
    for i = 1:dim.size
        if dim.types[i] == true
            return false, 0
        else
            number = number * (dim.regions[i][2] - dim.regions[i][1] + 1)
        end
    end
    return true, number
end

function dim_print(dim::Dimension)
    zoolog("dim size $(dim.size)")
    zoolog("dim regions is: ")
    zoolog("$(dim.regions)")
    zoolog("dim types is: ")
    zoolog("$(dim.types)")
end

function is_discrete(dim::Dimension)
    for i in 1:length(dim.types)
        if dim.types[i] == true
            return false
        end
    end
    return true
end
