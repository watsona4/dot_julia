import Random
using LinearAlgebra
using Random

"""
    bilinearInterpolation(field, x_tilde, y_tilde, i, j, k, it)

Use bilinear interpolation to interpolate a staggered grid to an arbitrary 
position in a cell.  Assumes south-west convention, i.e. (i,j) is located at the 
south-west (-x, -y)-facing corner.

# Arguments
* `field::Array{Float64, 4}`: a scalar field to interpolate from
* `x_tilde::Float64`: x point position [0;1]
* `y_tilde::Float64`: y point position [0;1]
* `i::Int`: i-index of cell containing point
* `j::Int`: j-index of scalar field to interpolate from
* `it::Int`: time step from scalar field to interpolate from
"""
@inline function bilinearInterpolation!(interp_val::Vector{Float64},
                                field_x::Array{Float64, 2},
                                field_y::Array{Float64, 2},
                                x_tilde::Float64,
                                y_tilde::Float64,
                                i::Int,
                                j::Int)

    #if x_tilde < 0. || x_tilde > 1. || y_tilde < 0. || y_tilde > 1.
        #error("relative coordinates outside bounds ($(x_tilde), $(y_tilde))")
    #end

    @views interp_val .= 
    (field_x[i+1, j+1]*x_tilde + field_x[i, j+1]*(1. - x_tilde))*y_tilde + 
    (field_x[i+1, j]*x_tilde + field_x[i, j]*(1. - x_tilde))*(1. - y_tilde),
    (field_y[i+1, j+1]*x_tilde + field_y[i, j+1]*(1. - x_tilde))*y_tilde + 
    (field_y[i+1, j]*x_tilde + field_y[i, j]*(1. - x_tilde))*(1.  - y_tilde)

    nothing
end
@inbounds @inline function bilinearInterpolation!(interp_val::Vector{Float64},
                                                  field_x::Array{Float64, 4},
                                                  field_y::Array{Float64, 4},
                                                  x_tilde::Float64,
                                                  y_tilde::Float64,
                                                  i::Int,
                                                  j::Int,
                                                  k::Int,
                                                  it::Int)

    #if x_tilde < 0. || x_tilde > 1. || y_tilde < 0. || y_tilde > 1.
        #error("relative coordinates outside bounds ($(x_tilde), $(y_tilde))")
    #end

    @views interp_val .= 
    (field_x[i+1, j+1, k, it]*x_tilde + 
     field_x[i, j+1, k, it]*(1. - x_tilde))*y_tilde + 
    (field_x[i+1, j, k, it]*x_tilde + 
     field_x[i, j, k, it]*(1. - x_tilde))*(1. - y_tilde),
    (field_y[i+1, j+1, k, it]*x_tilde + 
     field_y[i, j+1, k, it]*(1. - x_tilde))*y_tilde + 
    (field_y[i+1, j, k, it]*x_tilde + 
     field_y[i, j, k, it]*(1. - x_tilde))*(1. - y_tilde)

    nothing
end

"""
    curl(grid, x_tilde, y_tilde, i, j, k, it)

Use bilinear interpolation to interpolate curl value for a staggered velocity 
grid to an arbitrary position in a cell.  Assumes south-west convention, i.e.  
(i,j) is located at the south-west (-x, -y)-facing corner.

# Arguments
* `grid::Any`: grid for which to determine curl
* `x_tilde::Float64`: x point position [0;1]
* `y_tilde::Float64`: y point position [0;1]
* `i::Int`: i-index of cell containing point
* `j::Int`: j-index of scalar field to interpolate from
* `it::Int`: time step from scalar field to interpolate from
"""
function curl(grid::Any,
              x_tilde::Float64,
              y_tilde::Float64,
              i::Int,
              j::Int,
              k::Int,
              it::Int,
              sw::Vector{Float64} = Vector{Float64}(undef, 2),
              se::Vector{Float64} = Vector{Float64}(undef, 2),
              ne::Vector{Float64} = Vector{Float64}(undef, 2),
              nw::Vector{Float64} = Vector{Float64}(undef, 2))

    #sw, se, ne, nw = getCellCornerCoordinates(grid.xq, grid.yq, i, j)
    sw[1] = grid.xq[  i,   j]
    sw[2] = grid.yq[  i,   j]
    se[1] = grid.xq[i+1,   j]
    se[2] = grid.yq[i+1,   j]
    ne[1] = grid.xq[i+1, j+1]
    ne[2] = grid.yq[i+1, j+1]
    nw[1] = grid.xq[  i, j+1]
    nw[2] = grid.yq[  i, j+1]
    sw_se = norm(sw - se)
    se_ne = norm(se - ne)
    nw_ne = norm(nw - ne)
    sw_nw = norm(sw - nw)

    @views @inbounds return (
    ((grid.v[i+1, j  , k,it] - grid.v[i  , j  , k,it])/sw_se*(1. - y_tilde) +
     ((grid.v[i+1, j+1, k,it] - grid.v[i  , j+1, k,it])/nw_ne)*y_tilde) -
    ((grid.u[i  , j+1, k,it] - grid.u[i  , j  , k,it])/sw_nw*(1. - x_tilde) +
     ((grid.u[i+1, j+1, k,it] - grid.u[i+1, j  , k,it])/se_ne)*x_tilde))
end

export sortGrainsInGrid!
"""
Find grain positions in grid, based on their center positions.
"""
function sortGrainsInGrid!(simulation::Simulation, grid::Any; verbose=true)

    if simulation.time_iteration == 0
        grid.grain_list =
            Array{Array{Int, 1}}(undef, size(grid.xh, 1), size(grid.xh, 2))

        for i=1:size(grid.xh, 1)
            for j=1:size(grid.xh, 2)
                @inbounds grid.grain_list[i, j] = Int[]
            end
        end
    else
        for i=1:size(grid.xh, 1)
            for j=1:size(grid.xh, 2)
                @inbounds empty!(grid.grain_list[i, j])
            end
        end
    end

    sw = Vector{Float64}(undef, 2)
    se = Vector{Float64}(undef, 2)
    ne = Vector{Float64}(undef, 2)
    nw = Vector{Float64}(undef, 2)

    for idx=1:length(simulation.grains)

        @inbounds if !simulation.grains[idx].enabled
            continue
        end

        # After first iteration, check if grain is in same cell before 
        # traversing entire grid
        if typeof(grid) == Ocean
            @inbounds i_old, j_old = simulation.grains[idx].ocean_grid_pos
        elseif typeof(grid) == Atmosphere
            @inbounds i_old, j_old = 
                simulation.grains[idx].atmosphere_grid_pos
        else
            error("grid type not understood.")
        end

        if simulation.time > 0. &&
            !grid.regular_grid &&
            i_old > 0 && j_old > 0 &&
            isPointInCell(grid, i_old, j_old,
                          simulation.grains[idx].lin_pos[1:2], sw, se, ne, nw)
            i = i_old
            j = j_old

        else

            if grid.regular_grid
                i, j = Int.(floor.((simulation.grains[idx].lin_pos[1:2]
                                    - grid.origo)
                                   ./ grid.dx[1:2])) + [1,1]
            else

                # Search for point in 8 neighboring cells
                nx = size(grid.xh, 1)
                ny = size(grid.xh, 2)
                found = false
                for i_rel=-1:1
                    for j_rel=-1:1
                        if i_rel == 0 && j_rel == 0
                            continue  # cell previously searched
                        end
                        i_t = max(min(i_old + i_rel, nx), 1)
                        j_t = max(min(j_old + j_rel, ny), 1)
                        
                        @inbounds if isPointInCell(grid, i_t, j_t,
                                                   simulation.grains[idx].
                                                   lin_pos[1:2],
                                                   sw, se, ne, nw)
                            i = i_t
                            j = j_t
                            found = true
                            break
                        end
                    end
                    if found
                        break
                    end
                end

                if !found
                    i, j = findCellContainingPoint(grid,
                                                   simulation.grains[idx].
                                                   lin_pos[1:2],
                                                   sw, se, ne, nw)
                end
            end

            # remove grain if it is outside of the grid
            if (!grid.regular_grid && 
                 (i < 1 || j < 1 || 
                  i > size(grid.xh, 1) || j > size(grid.xh, 2))) ||
                (grid.regular_grid &&
                 (i < 1 || j < 1 || 
                  i > grid.n[1] || j > grid.n[2]))

                if verbose
                    @info "Disabling grain $idx at pos (" *
                         "$(simulation.grains[idx].lin_pos))"
                end
                disableGrain!(simulation, idx)
                continue
            end

            # add cell to grain
            if typeof(grid) == Ocean
                @inbounds simulation.grains[idx].ocean_grid_pos[1] = i
                @inbounds simulation.grains[idx].ocean_grid_pos[2] = j
            elseif typeof(grid) == Atmosphere
                @inbounds simulation.grains[idx].atmosphere_grid_pos[1] = i
                @inbounds simulation.grains[idx].atmosphere_grid_pos[2] = j
            else
                error("grid type not understood.")
            end
        end

        # add grain to cell
        @inbounds push!(grid.grain_list[i, j], idx)
    end
    nothing
end

export findCellContainingPoint
"""
    findCellContainingPoint(grid, point[, method])

Returns the `i`, `j` index of the grid cell containing the `point`.
The function uses either an area-based approach (`method = "Area"`), or a 
conformal mapping approach (`method = "Conformal"`).  The area-based approach is 
more robust.  This function returns the coordinates of the cell.  If no match is 
found the function returns `(0,0)`.

# Arguments
* `grid::Any`: grid object containing ocean or atmosphere data.
* `point::Vector{Float64}`: two-dimensional vector of point to check.
* `method::String`: approach to use for determining if point is inside cell or 
    not, can be "Conformal" (default) or "Area".
"""
function findCellContainingPoint(grid::Any, point::Vector{Float64},
                                 sw = Vector{Float64}(undef, 2),
                                 se = Vector{Float64}(undef, 2),
                                 ne = Vector{Float64}(undef, 2),
                                 nw = Vector{Float64}(undef, 2);
                                 method::String="Conformal")
    for i=1:size(grid.xh, 1)
        for j=1:size(grid.yh, 2)
            if isPointInCell(grid, i, j, point,
                             sw, se, ne, nw,
                             method=method)
                return i, j
            end
        end
    end
    return 0, 0
end

export getNonDimensionalCellCoordinates
"""
Returns the non-dimensional conformal mapped coordinates for point `point` in 
cell `i,j`, based off the coordinates in the grid.

This function is a wrapper for `getCellCornerCoordinates()` and 
`conformalQuadrilateralCoordinates()`.
"""
function getNonDimensionalCellCoordinates(grid::Any, i::Int, j::Int,
                                          point::Vector{Float64})
    if grid.regular_grid
        return (point[1:2] - Float64.([i-1,j-1]).*grid.dx[1:2])./grid.dx[1:2]
    else
        sw, se, ne, nw = getCellCornerCoordinates(grid.xq, grid.yq, i, j)
        return conformalQuadrilateralCoordinates(sw, se, ne, nw, point[1:2])
    end
end

export isPointInCell
"""
Check if a 2d point is contained inside a cell from the supplied grid.
The function uses either an area-based approach (`method = "Area"`), or a 
conformal mapping approach (`method = "Conformal"`).  The area-based approach is 
more robust.  This function returns `true` or `false`.
"""
function isPointInCell(grid::Any, i::Int, j::Int,
                       point::Vector{Float64},
                       sw::Vector{Float64} = Vector{Float64}(undef, 2),
                       se::Vector{Float64} = Vector{Float64}(undef, 2),
                       ne::Vector{Float64} = Vector{Float64}(undef, 2),
                       nw::Vector{Float64} = Vector{Float64}(undef, 2);
                       method::String="Conformal")

    if grid.regular_grid
        if [i,j] == Int.(floor.((point[1:2] - grid.origo) ./ grid.dx[1:2])) + [1,1]
            return true
        else
            return false
        end
    end

    @views sw .= grid.xq[   i,   j], grid.yq[   i,   j]
    @views se .= grid.xq[ i+1,   j], grid.yq[ i+1,   j]
    @views ne .= grid.xq[ i+1, j+1], grid.yq[ i+1, j+1]
    @views nw .= grid.xq[   i, j+1], grid.yq[   i, j+1]

    if method == "Area"
        if areaOfQuadrilateral(sw, se, ne, nw) ≈
            areaOfTriangle(point, sw, se) +
            areaOfTriangle(point, se, ne) +
            areaOfTriangle(point, ne, nw) +
            areaOfTriangle(point, nw, sw)
            return true
        else
            return false
        end

    elseif method == "Conformal"
        x_tilde, y_tilde = conformalQuadrilateralCoordinates(sw, se, ne, nw,
                                                             point)
        if x_tilde >= 0. && x_tilde <= 1. && y_tilde >= 0. && y_tilde <= 1.
            return true
        else
            return false
        end
    else
        error("method not understood")
    end
end

export isPointInGrid
"""
Check if a 2d point is contained inside the grid.  The function uses either an
area-based approach (`method = "Area"`), or a conformal mapping approach
(`method = "Conformal"`).  The area-based approach is more robust.  This
function returns `true` or `false`.
"""
function isPointInGrid(grid::Any, point::Vector{Float64},
                       sw::Vector{Float64} = Vector{Float64}(undef, 2),
                       se::Vector{Float64} = Vector{Float64}(undef, 2),
                       ne::Vector{Float64} = Vector{Float64}(undef, 2),
                       nw::Vector{Float64} = Vector{Float64}(undef, 2);
                       method::String="Conformal")

    #sw, se, ne, nw = getCellCornerCoordinates(grid.xq, grid.yq, i, j)
    nx, ny = size(grid.xq)
    @views sw .= grid.xq[  1,  1], grid.yq[  1,  1]
    @views se .= grid.xq[ nx,  1], grid.yq[ nx,  1]
    @views ne .= grid.xq[ nx, ny], grid.yq[ nx, ny]
    @views nw .= grid.xq[  1, ny], grid.yq[  1, ny]

    if method == "Area"
        if areaOfQuadrilateral(sw, se, ne, nw) ≈
            areaOfTriangle(point, sw, se) +
            areaOfTriangle(point, se, ne) +
            areaOfTriangle(point, ne, nw) +
            areaOfTriangle(point, nw, sw)
            return true
        else
            return false
        end

    elseif method == "Conformal"
        x_tilde, y_tilde = conformalQuadrilateralCoordinates(sw, se, ne, nw,
                                                             point)
        if x_tilde >= 0. && x_tilde <= 1. && y_tilde >= 0. && y_tilde <= 1.
            return true
        else
            return false
        end
    else
        error("method not understood")
    end
end

export getGridCornerCoordinates
"""
    getGridCornerCoordinates(xq, yq)

Returns grid corner coordinates in the following order (south-west corner, 
south-east corner, north-east corner, north-west corner).

# Arguments
* `xq::Array{Float64, 2}`: nominal longitude of q-points [degrees_E]
* `yq::Array{Float64, 2}`: nominal latitude of q-points [degrees_N]
"""
@inline function getGridCornerCoordinates(xq::Array{Float64, 2}, 
                                          yq::Array{Float64, 2})
    nx, ny = size(xq)
    @inbounds return Float64[xq[  1,   1], yq[  1,   1]],
        Float64[xq[ nx,  1], yq[ nx,   1]],
        Float64[xq[ nx, ny], yq[ nx, ny]],
        Float64[xq[  1, ny], yq[  1, ny]]
end


export getCellCornerCoordinates
"""
    getCellCornerCoordinates(xq, yq, i, j)

Returns grid-cell corner coordinates in the following order (south-west corner, 
south-east corner, north-east corner, north-west corner).

# Arguments
* `xq::Array{Float64, 2}`: nominal longitude of q-points [degrees_E]
* `yq::Array{Float64, 2}`: nominal latitude of q-points [degrees_N]
* `i::Int`: x-index of cell.
* `j::Int`: y-index of cell.
"""
@inline function getCellCornerCoordinates(xq::Array{Float64, 2}, 
                                          yq::Array{Float64, 2},
                                          i::Int, j::Int)
    @inbounds return Float64[xq[  i,   j], yq[  i,   j]],
        Float64[xq[i+1,   j], yq[i+1,   j]],
        Float64[xq[i+1, j+1], yq[i+1, j+1]],
        Float64[xq[  i, j+1], yq[  i, j+1]]
end

export getCellCenterCoordinates
"""
    getCellCenterCoordinates(grid.xh, grid.yh, i, j)

Returns grid center coordinates (h-point).

# Arguments
* `xh::Array{Float64, 2}`: nominal longitude of h-points [degrees_E]
* `yh::Array{Float64, 2}`: nominal latitude of h-points [degrees_N]
* `i::Int`: x-index of cell.
* `j::Int`: y-index of cell.
"""
function getCellCenterCoordinates(xh::Array{Float64, 2}, yh::Array{Float64, 2}, 
                                  i::Int, j::Int)
    return [xh[i, j], yh[i, j]]
end

export areaOfTriangle
"Returns the area of an triangle with corner coordinates `a`, `b`, and `c`."
function areaOfTriangle(a::Vector{Float64},
                        b::Vector{Float64},
                        c::Vector{Float64})
    return abs(
               (a[1]*(b[2] - c[2]) +
                b[1]*(c[2] - a[2]) +
                c[1]*(a[2] - b[2]))/2.
              )
end

export areaOfQuadrilateral
"""
Returns the area of a quadrilateral with corner coordinates `a`, `b`, `c`, and 
`d`.  Corners `a` and `c` should be opposite of each other, the same must be 
true for `b` and `d`.  This is true if the four corners are passed as arguments 
in a "clockwise" or "counter-clockwise" manner.
"""
function areaOfQuadrilateral(a::Vector{Float64},
                             b::Vector{Float64},
                             c::Vector{Float64},
                             d::Vector{Float64})
    return areaOfTriangle(a, b, c) + areaOfTriangle(c, d, a)
end

export conformalQuadrilateralCoordinates
"""
Returns the non-dimensional coordinates `[x_tilde, y_tilde]` of a point `p` 
within a quadrilateral with corner coordinates `A`, `B`, `C`, and `D`.
Points must be ordered in counter-clockwise order, starting from south-west 
corner.
"""
function conformalQuadrilateralCoordinates(A::Vector{Float64},
                                           B::Vector{Float64},
                                           C::Vector{Float64},
                                           D::Vector{Float64},
                                           p::Vector{Float64})

    if !(A[1] < B[1] && B[2] < C[2] && C[1] > D[1])
        error("corner coordinates are not passed in the correct order")
    end
    alpha = B[1] - A[1]
    delta = B[2] - A[2]
    beta = D[1] - A[1]
    epsilon = D[2] - A[2]
    gamma = C[1] - A[1] - (alpha + beta)
    kappa = C[2] - A[2] - (delta + epsilon)
    a = kappa*beta - gamma*epsilon
    dx = p[1] - A[1]
    dy = p[2] - A[2]
    b = (delta*beta - alpha*epsilon) - (kappa*dx - gamma*dy)
    c = alpha*dy - delta*dx
    if abs(a) > 0.
        d = b^2. / 4. - a*c
        if d >= 0.
            yy1 = -(b / 2. + sqrt(d)) / a
            yy2 = -(b / 2. - sqrt(d)) / a
            if abs(yy1 - .5) < abs(yy2 - .5)
                y_tilde = yy1
            else
                y_tilde = yy2
            end
        else
            error("could not perform conformal mapping\n" *
                  "A = $(A), B = $(B), C = $(C), D = $(D), point = $(p),\n" *
                  "alpha = $(alpha), beta = $(beta), gamma = $(gamma), " *
                  "delta = $(delta), epsilon = $(epsilon), kappa = $(kappa)")
        end
    else
        if !(b ≈ 0.)
            y_tilde = -c/b
        else
            y_tilde = 0.
        end
    end
    a = alpha + gamma*y_tilde
    b = delta + kappa*y_tilde
    if !(a ≈ 0.)
        x_tilde = (dx - beta*y_tilde)/a
    elseif !(b ≈ 0.)
        x_tilde = (dy - epsilon*y_tilde)/b
    else
        error("could not determine non-dimensional position in quadrilateral " *
              "(a = 0. and b = 0.)\n" *
              "A = $(A), B = $(B), C = $(C), D = $(D), point = $(p),\n" *
              "alpha = $(alpha), beta = $(beta), gamma = $(gamma), " *
              "delta = $(delta), epsilon = $(epsilon), kappa = $(kappa)")
    end
    return Float64[x_tilde, y_tilde]
end

export findEmptyPositionInGridCell
"""
    findEmptyPositionInGridCell(simulation, grid, i, j, r[, n_iter, seed,
                                verbose])

Attempt locate an empty spot for an grain with radius `r` with center 
coordinates in a specified grid cell (`i`, `j`) without overlapping any other 
grains in that cell or the neighboring cells.  This function will stop 
attempting after `n_iter` iterations, each with randomly generated positions.

This function assumes that existing grains have been binned according to the 
grid (e.g., using `sortGrainsInGrid()`).

If the function sucessfully finds a position it will be returned as a
two-component Vector{Float64}.  If a position is not found, the function will
return `false`.

# Arguments
* `simulation::Simulation`: the simulation object to add grains to.
* `grid::Any`: the grid to use for position search.
* `i::Int`: the grid-cell index along x.
* `j::Int`: the grid-cell index along y.
* `r::Float64`: the desired grain radius to fit into the cell.
* `n_iter::Int = 30`: the number of attempts for finding an empty spot.
* `seed::Int = 1`: seed for the pseudo-random number generator.
* `verbose::Bool = false`: print diagnostic information.
"""
function findEmptyPositionInGridCell(simulation::Simulation,
                                     grid::Any,
                                     i::Int,
                                     j::Int,
                                     r::Float64;
                                     n_iter::Int = 30,
                                     seed::Int = 1,
                                     verbose::Bool = false)
    overlap_found = false
    spot_found = false
    i_iter = 0
    pos = [NaN, NaN]

    nx, ny = size(grid.xh)

    for i_iter=1:n_iter

        overlap_found = false
        Random.seed!(i*j*seed*i_iter)
        # generate random candidate position
        x_tilde = rand()
        y_tilde = rand()
        bilinearInterpolation!(pos, grid.xq, grid.yq, x_tilde, y_tilde, i, j)
        if verbose
            @info "trying position $pos in cell $i,$j"
        end

        # do not penetrate outside of grid boundaries
        if i == 1 && pos[1] - r < grid.xq[1,1] ||
            j == 1 && pos[2] - r < grid.yq[1,1] ||
            i == nx && pos[1] + r > grid.xq[end,end] ||
            j == ny && pos[2] + r > grid.yq[end,end]
            overlap_found = true
        end

        # search for contacts in current and eight neighboring cells
        if !overlap_found
            for i_neighbor_corr=[0 -1 1]
                for j_neighbor_corr=[0 -1 1]

                    # target cell index
                    it = i + i_neighbor_corr
                    jt = j + j_neighbor_corr

                    # do not search outside grid boundaries
                    if it < 1 || it > nx || jt < 1 || jt > ny
                        continue
                    end

                    # traverse list of grains in the target cell and check 
                    # for overlaps
                    for grain_idx in grid.grain_list[it, jt]
                        overlap = norm(simulation.grains[grain_idx].
                                       lin_pos[1:2] - pos) -
                        (simulation.grains[grain_idx].contact_radius + r)

                        if overlap < 0.
                            if verbose
                                @info "overlap with $grain_idx in cell $i,$j"
                            end
                            overlap_found = true
                            break
                        end
                    end
                end
                if overlap_found == true
                    break
                end
            end
        end
        if overlap_found == false
            break
        end
    end
    if overlap_found == false
        spot_found = true
    end

    if spot_found
        if verbose
            @info "Found position $pos in cell $i,$j"
        end
        return pos
    else
        if verbose
            @warn "could not insert an grain into " *
                 "$(typeof(grid)) grid cell ($i, $j)"
        end
        return false
    end
end

"""
Copy grain related information from ocean to atmosphere grid.  This is useful 
when the two grids are of identical geometry, meaning only only one sorting 
phase is necessary.
"""
function copyGridSortingInfo!(ocean::Ocean, atmosphere::Atmosphere,
                              grains::Array{GrainCylindrical, 1})

    for grain in grains
        grain.atmosphere_grid_pos = deepcopy(grain.ocean_grid_pos)
    end
    atmosphere.grain_list = deepcopy(ocean.grain_list)
    nothing
end

export setGridBoundaryConditions!
"""
    setGridBoundaryConditions!(grid, grid_face, mode)

Set boundary conditions for the granular phase at the edges of `Ocean` or
`Atmosphere` grids.  The target boundary can be selected through the `grid_face`
argument, or the same boundary condition can be applied to all grid boundaries
at once.

When the center coordinate of grains crosses an inactive boundary (`mode =
"inactive"`), the grain is disabled (`GrainCylindrical.enabled = false`).  This
keeps the grain in memory, but stops it from moving or interacting with other
grains.  *By default, all boundaries are inactive*.

If the center coordinate of a grain crosses a periodic boundary (`mode =
periodic`), the grain is repositioned to the opposite side of the model domain.
Grains can interact mechanically across the periodic boundary.

# Arguments
* `grid::Any`: `Ocean` or `Atmosphere` grid to apply the boundary condition to.
* `grid_face::String`: Grid face to apply the boundary condition to.  Valid
    values are any combination and sequence of `"west"` (-x), `"south"` (-y),
    `"east"` (+x), `"north"` (+y), or simply any combination of `"-x"`, `"+x"`,
    `"-y"`, and `"+y"`.  The specifiers may be delimited in any way.
    Also, and by default, all boundaries can be selected with `"all"` (-x, -y,
    +x, +y), which overrides any other face selection.
* `mode::String`: Boundary behavior, accepted values are `"inactive"`,
    `"periodic"`, and `"impermeable"`.  You cannot specify more than one mode at
    a time, so if several modes are desired as boundary conditions for the grid,
    several calls to this function should be made.
* `verbose::Bool`: Confirm boundary conditions by reporting values to console.

# Examples
Set all boundaries for the ocean grid to be periodic:

    setGridBoundaryConditions!(ocean, "periodic", "all")

Set the south-north boundaries to be inactive, but the west-east boundaries to
be periodic:

    setGridBoundaryConditions!(ocean, "inactive", "south north")
    setGridBoundaryConditions!(ocean, "periodic", "west east")

or specify the conditions from the coordinate system axes:

    setGridBoundaryConditions!(ocean, "inactive", "-y +y")
    setGridBoundaryConditions!(ocean, "periodic", "-x +x")

"""
function setGridBoundaryConditions!(grid::Any,
                                    mode::String,
                                    grid_face::String = "all";
                                    verbose::Bool=true)

    something_changed = false

    if length(mode) <= 1
        error("The mode string is required ('$mode')")
    end

    if !(mode in grid_bc_strings)
        error("Mode '$mode' not recognized as a valid boundary condition type")
    end

    if occursin("west", grid_face) || occursin("-x", grid_face)
        grid.bc_west = grid_bc_flags[mode]
        something_changed = true
    end

    if occursin("south", grid_face) || occursin("-y", grid_face)
        grid.bc_south = grid_bc_flags[mode]
        something_changed = true
    end

    if occursin("east", grid_face) || occursin("+x", grid_face)
        grid.bc_east = grid_bc_flags[mode]
        something_changed = true
    end

    if occursin("north", grid_face) || occursin("+y", grid_face)
        grid.bc_north = grid_bc_flags[mode]
        something_changed = true
    end

    if grid_face == "all"
        grid.bc_west  = grid_bc_flags[mode]
        grid.bc_south = grid_bc_flags[mode]
        grid.bc_east  = grid_bc_flags[mode]
        grid.bc_north = grid_bc_flags[mode]
        something_changed = true
    end

    if !something_changed
        error("grid_face string '$grid_face' not understood, " *
              "must be east, west, north, south, -x, +x, -y, and/or +y.")
    end

    if verbose
        reportGridBoundaryConditions(grid)
    end
    nothing
end

export reportGridBoundaryConditions
"""
    reportGridBoundaryConditions(grid)

Report the boundary conditions for the grid to the console.
"""
function reportGridBoundaryConditions(grid::Any)
    println("West  (-x): " * grid_bc_strings[grid.bc_west] * 
            "\t($(grid.bc_west))")
    println("East  (+x): " * grid_bc_strings[grid.bc_east] * 
            "\t($(grid.bc_east))")
    println("South (-y): " * grid_bc_strings[grid.bc_south] * 
            "\t($(grid.bc_south))")
    println("North (+y): " * grid_bc_strings[grid.bc_north] * 
            "\t($(grid.bc_north))")
    nothing
end

"""
    moveGrainsAcrossPeriodicBoundaries!(simulation::Simulation)

If the ocean or atmosphere grids are periodic, move grains that are placed
outside the domain correspondingly across the domain.  This function is to be
called after temporal integration of the grain positions.
"""
function moveGrainsAcrossPeriodicBoundaries!(sim::Simulation)

    # return if grids are not enabled
    if typeof(sim.ocean.input_file) == Bool && 
        typeof(sim.atmosphere.input_file) == Bool
        return nothing
    end

    # return immediately if no boundaries are periodic
    if sim.ocean.bc_west != 2 && 
        sim.ocean.bc_south != 2 && 
        sim.ocean.bc_east != 2 && 
        sim.ocean.bc_north != 2
        return nothing
    end

    # throw error if ocean and atmosphere grid BCs are different and both are
    # enabled
    if (typeof(sim.ocean.input_file) != Bool &&
        typeof(sim.atmosphere.input_file) != Bool) &&
        (sim.ocean.bc_west != sim.atmosphere.bc_west &&
         sim.ocean.bc_south != sim.atmosphere.bc_south &&
         sim.ocean.bc_east != sim.atmosphere.bc_east &&
         sim.ocean.bc_north != sim.atmosphere.bc_north)
        error("Ocean and Atmosphere grid boundary conditions differ")
    end

    for grain in sim.grains

        # -x -> +x
        if sim.ocean.bc_west == 2 && grain.lin_pos[1] < sim.ocean.xq[1]
            grain.lin_pos[1] += sim.ocean.xq[end] - sim.ocean.xq[1]
        end

        # -y -> +y
        if sim.ocean.bc_south == 2 && grain.lin_pos[2] < sim.ocean.yq[1]
            grain.lin_pos[2] += sim.ocean.yq[end] - sim.ocean.yq[1]
        end

        # +x -> -x
        if sim.ocean.bc_east == 2 && grain.lin_pos[1] > sim.ocean.xq[end]
            grain.lin_pos[1] -= sim.ocean.xq[end] - sim.ocean.xq[1]
        end

        # +y -> -y
        if sim.ocean.bc_north == 2 && grain.lin_pos[2] > sim.ocean.yq[end]
            grain.lin_pos[2] -= sim.ocean.yq[end] - sim.ocean.yq[1]
        end
    end
    nothing
end

export reflectGrainsFromImpermeableBoundaries!
"""
    reflectGrainsFromImpermeableBoundaries!(simulation::Simulation)

If the ocean or atmosphere grids are impermeable, reflect grain trajectories by
reversing the velocity vectors normal to the boundary.  This function is to be
called after temporal integration of the grain positions.
"""
function reflectGrainsFromImpermeableBoundaries!(sim::Simulation)

    # return if grids are not enabled
    if typeof(sim.ocean.input_file) == Bool && 
        typeof(sim.atmosphere.input_file) == Bool
        return nothing
    end

    # return immediately if no boundaries are periodic
    if sim.ocean.bc_west != 3 && 
        sim.ocean.bc_south != 3 && 
        sim.ocean.bc_east != 3 && 
        sim.ocean.bc_north != 3
        return nothing
    end

    # throw error if ocean and atmosphere grid BCs are different and both are
    # enabled
    if (typeof(sim.ocean.input_file) != Bool &&
        typeof(sim.atmosphere.input_file) != Bool) &&
        (sim.ocean.bc_west != sim.atmosphere.bc_west &&
         sim.ocean.bc_south != sim.atmosphere.bc_south &&
         sim.ocean.bc_east != sim.atmosphere.bc_east &&
         sim.ocean.bc_north != sim.atmosphere.bc_north)
        error("Ocean and Atmosphere grid boundary conditions differ")
    end

    for grain in sim.grains

        # -x
        if sim.ocean.bc_west == 3 && 
            grain.lin_pos[1] - grain.contact_radius < sim.ocean.xq[1]

            grain.lin_vel[1] *= -1.
        end

        # -y
        if sim.ocean.bc_south == 3 && 
            grain.lin_pos[2] - grain.contact_radius < sim.ocean.yq[1]

            grain.lin_vel[2] *= -1.
        end

        # +x
        if sim.ocean.bc_east == 3 &&
            grain.lin_pos[1] + grain.contact_radius > sim.ocean.xq[end]

            grain.lin_vel[1] *= -1.
        end

        # +y
        if sim.ocean.bc_east == 3 && 
            grain.lin_pos[2] + grain.contact_radius > sim.ocean.yq[end]

            grain.lin_vel[2] *= -1.
        end
    end
    nothing
end

export fitGridToGrains!
"""
    fitGridToGrains!(simulation, grid[, padding])

Fit the ocean or atmosphere grid for a simulation to the current grains and
their positions.

# Arguments
* `simulation::Simulation`: simulation object to manipulate.
* `grid::Any`: Ocean or Atmosphere grid to manipulate.
* `padding::Real`: optional padding around edges [m].
* `verbose::Bool`: show grid information when function completes.
"""
function fitGridToGrains!(simulation::Simulation, grid::Any;
                          padding::Real=0., verbose::Bool=true)

    if typeof(grid) != Ocean && typeof(grid) != Atmosphere
        error("grid must be of Ocean or Atmosphere type")
    end

    min_x = Inf
    min_y = Inf
    max_x = -Inf
    max_y = -Inf
    max_radius = 0.

    if length(simulation.grains) < 1
        error("Grains need to be initialized before calling fitGridToGrains")
    end

    r = 0.
    for grain in simulation.grains
        r = grain.contact_radius

        if grid.bc_west == grid_bc_flags["periodic"]
            if grain.lin_pos[1] < min_x
                min_x = grain.lin_pos[1] - r
            end
        else
            if grain.lin_pos[1] - r < min_x
                min_x = grain.lin_pos[1] - r
            end
        end

        if grid.bc_east == grid_bc_flags["periodic"]
            if grain.lin_pos[1] > max_x
                max_x = grain.lin_pos[1] + grain.contact_radius
            end
        else
            if grain.lin_pos[1] + r > max_x
                max_x = grain.lin_pos[1] + grain.contact_radius
            end
        end

        if grid.bc_south == grid_bc_flags["periodic"]
            if grain.lin_pos[2] < min_y
                min_y = grain.lin_pos[2] - grain.contact_radius
            end
        else
            if grain.lin_pos[2] - r < min_y
                min_y = grain.lin_pos[2] - grain.contact_radius
            end
        end

        if grid.bc_north == grid_bc_flags["periodic"]
            if grain.lin_pos[2] > max_y
                max_y = grain.lin_pos[2] + grain.contact_radius
            end
        else
            if grain.lin_pos[2] + r > max_y
                max_y = grain.lin_pos[2] + grain.contact_radius
            end
        end

        if r > max_radius
            max_radius = r
        end
    end
    min_x -= padding
    min_y -= padding
    max_x += padding
    max_y += padding

    L::Vector{Float64} = [max_x - min_x, max_y - min_y]
    dx::Float64 = 2. * max_radius
    n = convert(Vector{Int}, floor.(L./dx))
    if 0 in n || 1 in n
        println("L = $L")
        println("dx = $dx")
        println("n = $n")
        error("Grid is too small compared to grain size (n = $n). " *
              "Use all-to-all contact search instead.")
    end


    if typeof(grid) == Ocean
        simulation.ocean = createRegularOceanGrid(vcat(n, 1), vcat(L, 1.),
                                                  origo=[min_x, min_y],
                                                  time=[0.], name="fitted",
                                                  bc_west  = grid.bc_west,
                                                  bc_south = grid.bc_south,
                                                  bc_east  = grid.bc_east,
                                                  bc_north = grid.bc_north)
    elseif typeof(grid) == Atmosphere
        simulation.atmosphere = createRegularAtmosphereGrid(vcat(n, 1),
                                                            vcat(L, 1.),
                                                            origo=[min_x,
                                                                   min_y],
                                                            time=[0.],
                                                            name="fitted",
                                                            bc_west  = grid.bc_west,
                                                            bc_south = grid.bc_south,
                                                            bc_east  = grid.bc_east,
                                                            bc_north = grid.bc_north)
    end

    if verbose
        @info "Created regular $(typeof(grid)) grid from " *
             "[$min_x, $min_y] to [$max_x, $max_y] " *
             "with a cell size of $dx ($n)."
    end

    nothing
end

function findPorosity!(sim::Simulation, grid::Any; verbose::Bool=true)

    if !isassigned(grid.grain_list)
        @info "Sorting grains in grid"
        sortGrainsInGrid!(sim, grid, verbose=verbose)
    end

    sw = Vector{Float64}(undef, 2)
    se = Vector{Float64}(undef, 2)
    ne = Vector{Float64}(undef, 2)
    nw = Vector{Float64}(undef, 2)
    cell_area = 0.0
    p = zeros(2)
    r = 0.0
    A = 0.0

    for ix in 1:size(grid.xh, 1)
        for iy in 1:size(grid.xh, 2)

            @views sw .= grid.xq[   ix,   iy], grid.yq[   ix,   iy]
            @views se .= grid.xq[ ix+1,   iy], grid.yq[ ix+1,   iy]
            @views ne .= grid.xq[ ix+1, iy+1], grid.yq[ ix+1, iy+1]
            @views nw .= grid.xq[   ix, iy+1], grid.yq[   ix, iy+1]
            cell_area = areaOfQuadrilateral(sw, se, ne, nw)

            # Subtract grain area from cell area
            particle_area = 0.0
            for ix_ = -1:1
                for iy_ = -1:1

                    # Make sure cell check is within grid
                    if ix + ix_ < 1 || ix + ix_ > size(grid.xh, 1) ||
                        iy + iy_ < 1 || iy + iy_ > size(grid.xh, 2)
                        continue
                    end

                    # Traverse grain list
                    for i in grid.grain_list[ix + ix_, iy + iy_]

                        # Grain geometry
                        p = sim.grains[i].lin_pos
                        r = sim.grains[i].areal_radius
                        A = grainHorizontalSurfaceArea(sim.grains[i])

                        #= if sw[1] <= p[1] - r && =#
                        #=     sw[2] <= p[2] - r && =#
                        #=     ne[1] >= p[1] + r && =#
                        #=     ne[2] >= p[2] + r =#
                        if sw[1] <= p[1] &&
                            sw[2] <= p[2] &&
                            ne[1] >= p[1] &&
                            ne[2] >= p[2]
                            # If particle is entirely contained within cell,
                            # assuming a regular and orthogonal grid
                            # TODO: Adjust coordinates with conformal mapping
                            # for irregular grids.
                            particle_area += A

                        #= elseif sw[1] >= p[1] + r || =#
                        #=     sw[2] >= p[2] + r || =#
                        #=     ne[1] <= p[1] - r || =#
                        #=     ne[2] <= p[2] - r =#
                        #=     # particle does not intersect with cell [ix,iy] =#
                        #=     continue =#


                        #= else =#
                        #=     continue =#
                            # (likely) intersection between grid and grain

                            # 1. There is an intersection if one of the cell
                            # corners lies within the circle. This occurs if the
                            # distance between the cell center and corner is
                            # less than the radii.

                            # 2. There is an intersection if one of the cell
                            # edges comes to a closer distance to the cell
                            # center than the radius.

                        end
                    end
                end
            end

            grid.porosity[ix, iy] = (cell_area - particle_area)/cell_area
        end
    end
end
