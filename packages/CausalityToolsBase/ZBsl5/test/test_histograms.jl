pts = [rand(5) for i = 1:100];
spts = [SVector{5, Float64}(pt) for pt in pts]
mpts = [MVector{5, Float64}(pt) for pt in pts]
D = Dataset(pts);


@test joint_visits(spts, RectangularBinning(0.2)) isa Vector{Vector{Int}}
@test joint_visits(spts, RectangularBinning(5)) isa Vector{Vector{Int}}

@test marginal_visits(pts, RectangularBinning(0.2), [4, 2, 3]) isa Vector{Vector{Int}}
@test marginal_visits(pts, RectangularBinning(5), [4, 2, 3]) isa Vector{Vector{Int}}

@test marginal_visits(joint_visits(spts, RectangularBinning(0.2)), 1:4) isa Vector{Vector{Int}}

# Histograms directly from points
@test non0hist(spts, RectangularBinning(0.2), 1:3) |> sum ≈ 1.0
@test non0hist(spts, RectangularBinning(0.2), [1, 2]) |> sum≈ 1.0
@test non0hist(spts, RectangularBinning(0.5), 1:5) |> sum≈ 1.0
@test non0hist(mpts, RectangularBinning(0.2), 1:3) |> sum≈ 1.0
@test non0hist(mpts, RectangularBinning(0.2), [1, 2]) |> sum≈ 1.0
@test non0hist(mpts, RectangularBinning(0.5), 1:5) |> sum≈ 1.0
@test non0hist(pts, RectangularBinning(0.2), 1:3) |> sum≈ 1.0
@test non0hist(pts, RectangularBinning(0.2), [1, 2]) |> sum≈ 1.0
@test non0hist(pts, RectangularBinning(0.5), 1:5) |> sum≈ 1.0
@test non0hist(D, RectangularBinning(0.2), 1:3) |> sum≈ 1.0
@test non0hist(D, RectangularBinning(0.2), [1, 2]) |> sum≈ 1.0
@test non0hist(D, RectangularBinning(0.5), 1:5) |> sum≈ 1.0

# Histograms from precomputed joint/marginal visitations 
@test non0hist(joint_visits(spts, RectangularBinning(0.2))) |> sum ≈ 1.0
@test non0hist(marginal_visits(pts, RectangularBinning(0.2), [4, 2, 3])) |> sum ≈ 1.0