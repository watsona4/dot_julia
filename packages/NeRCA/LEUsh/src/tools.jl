"""
    function most_frequent(f::Function, iterable)

Return the most frequent value of a given iterable.
"""
function most_frequent(f::Function, iterable)
    d = Dict{Int, Int}()
    for element ∈ iterable
        v = f(element)
        if haskey(d, v)
            d[v] += 1
        else
            d[v] = 1
        end
    end
    candidate = 0
    key = 0
    for (k, v) in d
        if v > candidate
            key = k
            candidate = v
        end
    end
    return key
end
