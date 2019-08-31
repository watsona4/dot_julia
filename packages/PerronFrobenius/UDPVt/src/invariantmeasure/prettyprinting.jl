
####################
# Pretty printing
####################
function summarise(iv::AbstractInvariantDistribution)
    invdist_type = typeof(iv)
    n_bins = length(iv.dist)
    n_nonzero = length(iv.nonzero_inds)
    invdist_str = "$invdist_type where $n_nonzero out of $n_bins bins have positive measure\n"
    return invdist_str
end

function summarise(invm::RectangularInvariantMeasure)
    D = size(invm.pts, 1)
    npts = size(invm.pts, 2)

    pts_str = "  pts: $npts $D-dimensional points\n"

    # Discretization
    ϵ = invm.ϵ

    ϵ_str = "  ϵ: $ϵ\n"
    n_visited_bins = size(unique(invm.visited_bins_inds, dims = 2), 2)
    coord_minima = tuple(minimum(invm.visited_bins_coordinates, dims = 2)...,)
    coord_maxima = tuple(maximum(invm.visited_bins_coordinates, dims = 2)...,)

    inds_str = "  visited_bins_inds: $n_visited_bins unique bins (rectangular boxes) are visited by the points\n"
    coords_str = "  visited_bins_coords: Bins are distributed within the hypoercube enclosing \n\tx_{min} =$coord_minima to \n\tx_{max} = $coord_maxima\n"
    bv = invm.binvisits
    binvisits_str = "  binvisits: $bv"

    TO = invm.transfermatrix
    iv = invm.measure
    transfermatrix_str = "  transfermatrix: $TO"
    measure_str = "  measure: $iv"
    return join(["RectangularInvariantMeasure\n", pts_str, ϵ_str, inds_str, coords_str,
                binvisits_str, transfermatrix_str, measure_str])
end

Base.show(io::IO, iv::AbstractInvariantDistribution) = println(io, summarise(iv))
Base.show(io::IO, invm::RectangularInvariantMeasure) = println(io, summarise(invm))
