"""
    ellipsoid_pointwise(T, r, shift)

Compute all lattice points in the ellipsoid ``\\{ n∈ \\mathbb{Z}^g \\,:\\, ||v(n)|| < r, v(n) = √π T(n+[[Y⁻¹y]])\\}``.

# Arguments
- `T::Array{<:Real}`: basis of lattice
- `r::Real`: radius of ellipsoid
- `shift::Array{<:Real}`: ``[[Y⁻¹y]]``.
"""
function ellipsoid_pointwise(T::Array{<:Real}, r::Real, shift::Array{<:Real})
    L = Lattice(T);
    z = zeros(Int64, L.m);
    points = enum_ellipsoid(L, z, L.m, r^2/π, 0.0, shift);
    if ~(z in points)
        push!(points, z);
    end
    return points;
end

"""
    ellipsoid_uniform(T, r)

Compute all lattice points in the deformed ellipsoid ``\\{ n ∈\\mathbb{Z}^g\\,:\\, π (n-c)^t Y (n-c) < r^2\\,,
|c\\_j|<1\\,,\\forall j=1,\\ldots,g\\}``.
"""
function ellipsoid_uniform(T::Array{<:Real}, r::Real)
    L = Lattice(T);
    # compute union of pointwise ellipsoids centered at the vertices of a unit hypercube of dimension m
    pointset = Set();
    for i = 0:2^L.m-1
        shift = [(-1)^j for j in digits(i, base = 2, pad = L.m)];
        points = enum_ellipsoid(L, zeros(Int64,L.m), L.m, r^2/π, 0.0, shift);
        union!(pointset, points);
    end
    union!(pointset, [zeros(Int64, L.m)]);
    return collect(pointset);
end

"""
    enum_ellipsoid(L, x, i, radius, l, shift)

Enumerates all lattice points in subtree at height i, where parent nodes are defined by x. Helper method for [`ellipsoid_pointwise`](@ref) and [`ellipsoid_uniform`](@ref).
"""
function enum_ellipsoid(L::Lattice, x::Array{<:Integer}, i::Integer, radius::Real, l::Real, shift::Array{<:Real})
    points = Array{Int64}[];
    sol = copy(x);
    c = -sum(Float64[(x[j]+shift[j])*L.μ[j,i] for j=i+1:L.m]) - shift[i];
    interval = sqrt((radius-l)/L.r[i]); # interval of possibilities for x[i]
    for k = floor(Int64, c - interval) : ceil(Int64, c + interval)
        l_new = l + (k-c)^2*L.r[i];
        if l_new <= radius # possible new solution found
            sol[i] = k;
            if i == 1 & ~(l_new == 0) # leaf of enumeration tree
                push!(points, copy(sol));
            elseif i > 1 # solve subtree enumeration recursively
                subtree_points = enum_ellipsoid(L, sol, i-1, radius, l_new, shift);
                append!(points, subtree_points);
            end
        end
    end
    return points;
end

