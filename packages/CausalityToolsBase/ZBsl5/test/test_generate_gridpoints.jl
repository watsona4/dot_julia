using DelayEmbeddings
pts = Dataset(rand(100, 3))

@test generate_gridpoints(pts, RectangularBinning(3), OnGrid()) isa Vector{SVector{3, Float64}}
@test generate_gridpoints(pts, RectangularBinning(3), OnCell()) isa Vector{SVector{3, Float64}}
@test generate_gridpoints(pts, RectangularBinning(3)) isa Vector{SVector{3, Float64}}
