using Statistics, LinearAlgebra, SpatialJackknife, Test


"""
This function generates a set of points with random coordinates in the plane
between values of zero and one. Each point has an associated value drawn from
a standard normal distribution.
"""
function grf_2d(npoints::Int = 10000)::Array{Float64, 2}
    xyval = Array{Float64}(undef, npoints, 3)
    xyval[:, 1:2] = rand(npoints, 2)
    xyval[:, 3] = randn(npoints)
    xyval
end


"""
Here we generate points in known quadrants in 2d space so that we can test
if the correct subvolume indices are assigned by get_subvols()
"""
function fixed_quadrants_pts(quadpts::Int = 2500)::Tuple{Array{Float64, 2},
                                                         Array{Float64, 1},
                                                         Array{Int, 1}}
    npts = quadpts * 4
    pts = zeros(npts, 2)
    vals = zeros(npts)
    quads = ones(Int, npts)

    for i in 1:4
        xyvals = grf_2d(quadpts)

        xth = i > 2 ? 1 : 0
        yth = i % 2 == 0 ? 1 : 0

        pts[((i - 1) * quadpts + 1):(i * quadpts), 1] = xyvals[:, 1] .+ xth
        pts[((i - 1) * quadpts + 1):(i * quadpts), 2] = xyvals[:, 2] .+ yth

        vals[((i - 1) * quadpts + 1):(i * quadpts)] = xyvals[:, 3]
        quads[((i - 1) * quadpts + 1):(i * quadpts)] .= i
    end

    pts ./= 2

    pts, vals, quads
end


"""
This function uses the previous ones to generate points in a unit square and
tests if the random mask subvolume finder can allocate the correct quadrants.
"""
function test_2d_randmask_subvols()::Bool

    quadpts = 30
    nrands = quadpts * 4 * 3000

    datpts, datvals, true_quads = fixed_quadrants_pts(quadpts)
    randpts = rand(nrands, 2)

    subvols = get_subvols(datpts, randpts, 2)

    all(true_quads .== subvols)
end


"""
This function tests if the unit square points can be assigned to the correct
quadrants by the other method of get_subvol, which assumes a regular cube.
"""
function test_2d_cube_subvols()::Bool

    quadpts = 250
    datpts, datvals, true_quads = fixed_quadrants_pts(quadpts)

    subvols = get_subvols(datpts, side_divs = 2, edges = [[0.0, 1.0]])

    all(true_quads .== subvols)
end


"""
This tests whether the jackknife can find the mean and covariance of a set of
observables made from points distributed in a unit square. The points have
vector quantities associated with them distributed according to a mean and
covariance
"""
function test_meancovars(means::Array{Float64, 1},
                         covar::Array{Float64, 2},
                         npts::Int = 1000,
                         side_divs::Int = 3)::Tuple

    # get cholesky decomposition to transform data
    A = cholesky(covar)

    # generate datapoints
    ys = randn(npts, 2)
    zs = A.L * ys'
    zs = collect(zs')
    zs = zs .+ means'

    # get positions on square and compute subvols
    xs = rand(npts, 2)
    subvols = get_subvols(xs, side_divs = side_divs, edges = [[0.0, 1.0]])

    function compute_mean(dat)
        return [mean(dat[:, 1]), mean(dat[:, 2])]
    end

    function compute_covar(dat)
        ndims = size(dat)[2]
        return reshape(cov(dat), ndims^2)
    end

    # and compute estimates for mean and covariance
    outmeans, mean_error = jackknife(compute_mean, zs, subvols)
    outcovar, covar_error = jackknife(compute_covar, zs, subvols, covar = false)

    (outmeans, mean_error), (outcovar, covar_error)
end


@testset "Running tests" begin

    @test test_2d_randmask_subvols()
    @test test_2d_cube_subvols()

    testnpts = 1000
    side_divs = 5
    testmeans = [52.7, 79.3]
    testcovar = [15.1 4.9; 4.9 8.6]

    mean_errs, cov_errs = test_meancovars(testmeans, testcovar, testnpts, side_divs)

    testcovar = reshape(testcovar, 4)

    mean_bias = mean_errs[1] .- testmeans
    covar_bias = cov_errs[1] .- testcovar


    @test mean_errs[1] ≈ testmeans atol = maximum(sqrt.(diag(mean_errs[2]) + mean_bias .^ 2))
    @test cov_errs[1] ≈ testcovar atol = maximum(sqrt.(cov_errs[2] .+ covar_bias .^ 2))
end
