function binarySearch(f, key, low, high)
    #given monotonically increasing function f, find lowest index i such that
    #f(i) >= key. For monotonically decreasing simply negate f and key, and this
    #will return lowest i such that f(i) <= key
    low > high && error("binarySearch: low > high")
    f(high) < key && error("binarySearch: search area does not include value")
    val = 0
    mid = 0
    while low != high
        #compute function
        mid = div(low + high, 2);
        val = f(mid)
        if val <= key
            low = mid + 1
        else
            high = mid
        end
    end
    if low > mid
        return low,-f(low) #have to recompute in case we're done after "low=mid+1"
    else
        return low,-val
    end
end

function pLeftOfLine(p, l1, l2)
    #tests if a point p is left (>0), on (0) or right (<0) of line between l1
    #and l2
    return ((l2[1] - l1[1])*(p[2] - l1[2])
            - (p[1] - l1[1])*(l2[2] - l1[2]))
end

function pInPolygon(p, ft)
    #use winding number algorithm to test if a point p is in polygon a.
    #returns 1 if it is in, -1 if out, 0 if on.
    #TODO: Currently returns false if it is on a corner, fix this...
    wn = Int(0)
    n = size(ft,1)
    for i = 1:n
        i_1 = i == n ? 1 : i + 1
        if (ft[i,2] <= p[2])
            #if point is between points of line, and to the left of it, +1
            if (ft[i_1,2] > p[2])
                ret = pLeftOfLine(p, ft[i,:], ft[i_1,:])
                (ret > 0) && (wn += 1)
            end
        else
            #if point is between points of line, and to the right of it, -1
            if (ft[i_1,2] <= p[2])
                ret = pLeftOfLine(p, ft[i,:], ft[i_1,:])
                (ret < 0) && (wn -= 1)
            end
        end
    end
    wn != 0
end

"""
    uniqueind(v::Vector{T}) where T <: Number -> inds,u

Given a vector of numbers `v` of length `n`, returns the unique subset `u` as
well as a vector of indices `inds` of length `n` such that `v == u[inds]`.
"""
function uniqueind(v::Vector{T}) where T <: Number
    #returns inds,vals such that vals[inds[i]] == v[i]
    inds = Array{Int}(undef, 0)
    u = Array{T}(undef, 0)
    k = 0
    for val in v
        ind = findfirst(isequal(val), u)
        if ind == nothing
            k += 1
            push!(u, val)
            push!(inds, k)
        else
            push!(inds, ind)
        end
    end
    inds,u
end

"""
    find_border(sp::ScatteringProblem) -> [x_min; x_max; y_min; y_max]

Returns bounding box that contains all of the shapes in `sp`.
"""
function find_border(sp::ScatteringProblem)
    Rmax = maximum(s.R for s in sp.shapes)
    x_max,y_max = maximum(sp.centers, dims=1) .+ 2*Rmax
    x_min,y_min = minimum(sp.centers, dims=1) .- 2*Rmax
    border = [x_min; x_max; y_min; y_max]
end

"""
    find_border(sp::ScatteringProblem, points::Array{Float64,2}) -> [x_min; x_max; y_min; y_max]

Returns bounding box that contains all of the shapes in `sp` as well as specified
`points`.
"""
function find_border(sp::ScatteringProblem, points::Array{Float64,2})
    Rmax = maximum(s.R for s in sp.shapes)
    x_max,y_max = maximum([sp.centers;points], dims=1) .+ 2*Rmax
    x_min,y_min = minimum([sp.centers;points], dims=1) .- 2*Rmax
    border = [x_min; x_max; y_min; y_max]
end

function cartesianrotation(φ)
    [cos(φ) -sin(φ);
     sin(φ) cos(φ)]
end
