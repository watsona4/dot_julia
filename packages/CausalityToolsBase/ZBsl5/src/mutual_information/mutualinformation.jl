
export mutualinfo

Dataset(cr::CustomReconstruction{D, T}) where {D, T} = Dataset(cr.reconstructed_pts)

"""
    mutualinfo(pts, marginalinds_x, marginalinds_y, kernel::BoxKernel; 
        b = 2, kwargs...)
    
Estimate the mutual information using a kernel density estimator [1].

# Arguments 

- **`pts`**: The points in the joint space. If computing the mutual information between 
    two scalar data series `X` and `Y`, the points would be 2-dimensional. It is also 
    possible to provide higher-dimensional points and compute the mutual information 
    between only some of the coordinate axes, using `marginalinds_x` and `marginalinds_y`
    to indicate which marginals to consider. 

- **`marginalinds_x`**: The indices of the first marginal.

- **`marginalinds_y`**: The indices of the second marginal.

- **`kernel`**: An instance of a valid kernel. Defaults to `BoxKernel()`.

# Keyword arguments

- **`b`**: The base of the logarithm, which determines the unit of information (e.g. 
    `b = 2` gives the information in bits).

# References 

[1] [Steuer, R., Kurths, J., Daub, C.O., Weise, J. and Selbig, J., 2002. The mutual information: detecting and evaluating dependencies between variables. Bioinformatics, 18(suppl_2), pp.S231-S240](https://academic.oup.com/bioinformatics/article/18/suppl_2/S231/190783).

"""
function mutualinfo(pts, marginalinds_x, marginalinds_y, kernel::BoxKernel; 
        b = 2, normalise = true, kwargs...)
    n_pts = length(pts)
    X = Dataset(pts[:, marginalinds_x])
    Y = Dataset(pts[:, marginalinds_y])
    XY = Dataset(pts[:, [marginalinds_x; marginalinds_y]])

    # gridpoints equal the points themselves, so both arguments are equal
    density_X = kerneldensity(X, X, kernel, normalise = normalise; kwargs...)
    density_Y = kerneldensity(Y, Y, kernel, normalise = normalise; kwargs...)
    density_XY = kerneldensity(XY, XY, kernel, normalise = normalise; kwargs...)

    P_X = density_X ./ n_pts 
    P_Y = density_Y ./ n_pts 
    P_XY = density_XY ./ n_pts

    # Entropies are averages over probability distributions, so we may 
    # do a simple normalised sum if the data accurately represent the 
    # underlying distribution.
    MI = sum(log.(P_XY, b) .- (log.(P_X, b) .+ log.(P_Y, b))) / n_pts
end

