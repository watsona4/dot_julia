# Duck typing, v1 and v2 have to implement addition/substraction and scalar multiplication
function midpoint(v1, v2, dom::Domain, tol)
    # There has to be a midpoint
    @assert in(v2,dom) != in(v1,dom)
    if in(v2,dom)
        min=v1
        max=v2
    else
        min=v2
        max=v1
    end
    mid = NaN
    while sum(abs.(max-min)) > tol
        step = (max-min)/2
        mid = min+step
        in(mid,dom) ? max=mid : min=mid
    end
    mid
end

## Avoid ambiguity (because everything >=2D is tensor but 1D is not)
function boundary(g::ProductGrid{TG,T,N},dom::Domain{<:Number}) where {TG,T,N}
    println("This method being called means there is a 1D ProductGrid.")
end

function boundary(g::MaskedGrid{G,M},dom::Domain{<:Number}) where {G,M}
  # TODO merge supergrid?
    boundary(grid(g),dom)
end

"""
    boundary(g::AbstractGrid{TG,T},dom::Domain{N},tol=1e-12)

Create a grid on the boundary of the domain.
The grid determines the resolution of the boundary.
"""
function boundary(g::ProductGrid{TG,T},dom::EuclideanDomain{N},tol=1e-12) where {TG,N,T}
    # Initialize neighbours
    CartesianNeighbours = CartesianIndices(ntuple(k->-1:1,Val(N)))
    periodic = map(isperiodic, elements(g))
    midpoints = eltype(g)[]
    # for each element
    for i in eachindex(g)
        # for all neighbours
        for neighbourindex in CartesianNeighbours
            neighbour = ModCartesianIndicesBase.add_offset_mod((neighbourindex+i).I, ntuple(k->1, Val(N)), size(g), periodic)
            # check if any are on the other side of the boundary
            try
                if in(g[i],dom) != in(g[neighbour...],dom)
                    # add the midpoint to the grid
                    push!(midpoints, midpoint(g[i],g[neighbour...],dom,tol))
                end
            catch y
                isa(y,BoundsError) || rethrow(y)
            end
        end
    end
    ScatteredGrid(midpoints)
end

function boundary(g::AbstractGrid{T},dom::Domain{T},tol=1e-12) where {T <: Number}
    midpoints = T[]
    # for each element
    for i in eachindex(g)
        # check if any are on the other side of the boundary
        try
            if in(g[i],dom) != in(g[i+1],dom)
                # add the midpoint to the grid
                push!(midpoints, midpoint(g[i],g[i+1],dom,tol))
            end
        catch y
            isa(y,BoundsError) || rethrow(y)
        end
    end
    ScatteredGrid(midpoints)
end


function boundary(g::MaskedGrid{G,M},dom::EuclideanDomain{N}) where {G,M,N}
    boundary(supergrid(g),dom)
end

"""
A Masked grid that contains the elements of grid that are on the boundary of the domain
"""
function boundary_grid(grid::AbstractGrid, domain::Domain)
    mask = boundary_mask(grid, domain);
    MaskedGrid(grid,mask,domain);
end

isperiodics(g::ProductGrid) = map(isperiodic,elements(g))
isperiodics(g::AbstractGrid) = ntuple(k->false, Val(dimension(g)))

function boundary_mask(grid::AbstractGrid, domain::Domain, periodic=isperiodics(grid))
    S = size(grid)
    m = BitArray(undef,S)
    m[:] .= 0
    for i in eachindex(grid)
        if grid[i]∈domain
            t = true
            for bi in ModCartesianIndicesBase.nbindexlist(i, S, periodic)
                if !(grid[bi]∈domain)
                    t = false
                    break
                end
            end
            m[i] = !t
        end
    end
    m
end
