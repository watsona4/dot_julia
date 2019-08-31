using StaticArrays
using Distributions
using DelayEmbeddings
#2D 

# Create some example points
npts = 500
d = MvNormal(rand(Uniform(-1, 1), 2), rand(Uniform(0.1, 0.9), 2))
draws = [rand(2) for i = 1:npts]
pts = Dataset([SVector{2, Float64}(pt) for pt in draws])

# Evaulate the density at a subset of those points given all the points
gridpts = Dataset([SVector{2, Float64}(pt) for pt in pts[1:5:end]])

kdens_box = kerneldensity(pts, gridpts, BoxKernel(), normalise = true);
#kdens2 = kerneldensity(pts, gridpts, GaussianKernel(), normalise = true);

@test sum(kdens_box) ≈ 1.0
#sum(kdens2) ≈ 1.0

#3D
d = MvNormal(rand(Uniform(-1, 1), 3), rand(Uniform(0.1, 0.9), 3))
draws = [rand(d) for i = 1:npts]
pts = [SVector{3, Float64}(pt) for pt in draws];

gridpts = [SVector{3, Float64}(pt) for pt in pts[1:5:end]];

kdens_box = kerneldensity(pts, gridpts, BoxKernel(), normalise = true);
#kdens2 = kerneldensity(spts, sgridpts, GaussianKernel(), normalise = true);

@test sum(kdens_box) ≈ 1.0
#sum(kdens2) ≈ 1.0


#5D
d = MvNormal(rand(Uniform(-1, 1), 5), rand(Uniform(0.1, 0.9), 5))
draws = [rand(5) for i = 1:npts]
pts = [SVector{5, Float64}(pt) for pt in draws];
gridpts = [SVector{5, Float64}(pt) for pt in pts[1:5:end]];

kdens_box = kerneldensity(pts, gridpts, BoxKernel(), normalise = true);
#kdens2 = kerneldensity(spts, sgridpts, GaussianKernel(), normalise = true);

@test sum(kdens_box) ≈ 1.0
#sum(kdens2) ≈ 1.0