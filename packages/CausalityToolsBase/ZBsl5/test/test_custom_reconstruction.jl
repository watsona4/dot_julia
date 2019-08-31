spts = [SVector{4, Float64}(rand(4)) for i = 1:100];
mpts = [MVector{4, Float64}(rand(4)) for i = 1:100];
pts = [rand(4) for i = 1:100];

@test customembed(pts, Positions(3, 2, 1), Lags(-1, -5, 2)) isa CustomReconstruction{3,Float64}
@test customembed(spts, Positions(3, 2, 1), Lags(-1, -5, 2)) isa CustomReconstruction{3,Float64}
@test customembed(mpts, Positions(3, 2, 1), Lags(-1, -5, 2)) isa CustomReconstruction{3,Float64}
@test customembed(Dataset(mpts), Positions(3, 2, 1), Lags(-1, -5, 2)) isa CustomReconstruction{3,Float64}
@test customembed(pts) isa CustomReconstruction{4,Float64}

@test CustomReconstruction(pts) isa CustomReconstruction{4,Float64}
@test CustomReconstruction(spts) isa CustomReconstruction{4,Float64}
@test CustomReconstruction(mpts) isa CustomReconstruction{4,Float64}
@test CustomReconstruction(Dataset(pts)) isa CustomReconstruction{4,Float64}
@test CustomReconstruction(Dataset(spts)) isa CustomReconstruction{4,Float64}
@test CustomReconstruction(Dataset(mpts)) isa CustomReconstruction{4,Float64}

@test CustomReconstruction(rand(10, 3)) isa CustomReconstruction{3,Float64}
@test CustomReconstruction(rand(4, 20)) isa CustomReconstruction{4,Float64}
@test CustomReconstruction(Dataset(pts), Positions(3, 2, 1), Lags(-1, -5, 2)) isa CustomReconstruction{3,Float64}
@test CustomReconstruction(pts, Positions(3, 2, 1), Lags(-1, -5, 2)) isa CustomReconstruction{3,Float64}
@test CustomReconstruction(rand(4, 20), Positions(3, 2, 1), Lags(-1, -5, 2)) isa CustomReconstruction{3,Float64}
@test CustomReconstruction(rand(10, 3), Positions(3, 2, 1), Lags(-1, -5, 2)) isa CustomReconstruction{3,Float64}