pts = [rand(3) for i = 1:100]
spts = [SVector{3, Float64}(pt) for pt in pts]
mpts = [MVector{3, Float64}(pt) for pt in pts]

D = Dataset(pts)
@test get_minmaxes(pts) isa Vector{Tuple{Float64, Float64}}
@test get_minmaxes(spts) isa Vector{Tuple{Float64, Float64}}
@test get_minmaxes(mpts) isa Vector{Tuple{Float64, Float64}}
@test get_minmaxes(D) isa Vector{Tuple{Float64, Float64}}

@test get_minima(pts) isa SVector{3, Float64}
@test get_minima(D) isa SVector{3, Float64}
@test get_minima(spts) isa SVector{3, Float64}
@test get_minima(mpts) isa SVector{3, Float64}

@test get_maxima(pts) isa SVector{3, Float64}
@test get_maxima(D) isa SVector{3, Float64}
@test get_maxima(spts) isa SVector{3, Float64}
@test get_maxima(mpts) isa SVector{3, Float64}


pts = [rand(5) for i = 1:1000];
spts = [SVector{5, Float64}(pt) for pt in pts]
mpts = [MVector{5, Float64}(pt) for pt in pts]
D = Dataset(pts);

ϵs = [5, 0.5, [0.3 for i = 1:5], [10 for i = 1:5], (get_minmaxes(pts), 10)]


refpoint = [0, 0, 0]
steps = [0.2, 0.2, 0.3]
@test encode(rand(3), refpoint, steps) isa Vector{Int}
@test encode(SVector{3, Float64}(rand(3)), refpoint, steps) isa Vector{Int}
@test encode(MVector{3, Float64}(rand(3)), refpoint, steps) isa Vector{Int}

@test encode([rand(3) for i = 1:20], [0, 0, 0], [0.1, 0.1, 0.1]) isa Vector{Vector{Int}}
@test encode([SVector{3, Float64}(rand(3)) for i = 1:20], [0, 0, 0], [0.1, 0.1, 0.1]) isa Vector{Vector{Int}}
@test encode([MVector{3, Float64}(rand(3)) for i = 1:20], [0, 0, 0], [0.1, 0.1, 0.1]) isa Vector{Vector{Int}}

pts = [rand(5) for i = 1:1000];
spts = [SVector{5, Float64}(pt) for pt in pts]
mpts = [MVector{5, Float64}(pt) for pt in pts]
D = Dataset(pts);

ϵs = [5, 0.5, [0.3 for i = 1:5], [10 for i = 1:5], (get_minmaxes(pts), 10)]

for ϵ in ϵs
    ϵx = RectangularBinning(ϵ)
    
    @test get_edgelengths(pts, ϵx) isa Vector{Float64}
    @test get_edgelengths(D, ϵx) isa Vector{Float64}
    @test get_edgelengths(spts, ϵx) isa Vector{Float64}
    @test get_edgelengths(mpts, ϵx) isa Vector{Float64}

    @test get_minima_and_edgelengths(pts, ϵx) isa Tuple{Vector{Float64}, Vector{Float64}}
    @test get_minima_and_edgelengths(D, ϵx) isa Tuple{Vector{Float64}, Vector{Float64}}
    @test get_minima_and_edgelengths(spts, ϵx) isa Tuple{Vector{Float64}, Vector{Float64}}
    @test get_minima_and_edgelengths(mpts, ϵx) isa Tuple{Vector{Float64}, Vector{Float64}}
end

@testset "Data-informed ranges are expanded properly when splitting axes into N intervals" begin 
    pts = Dataset([rand(3) for i = 1:100])
    mins, maxs = minmaxima(pts)
    
    axisminima, edgelengths = get_minima_and_edgelengths(pts, RectangularBinning([3, 3, 3]))
    @test all((mins .+ edgelengths .* 3) .> maxs)
    @test isapprox((mins .+ edgelengths .* 3) .- maxs, edgelengths ./ 100, atol = 1e-4)
    
    axisminima, edgelengths = get_minima_and_edgelengths(pts, RectangularBinning(5))
    @test all((mins .+ edgelengths .* 5) .> maxs)
    @test isapprox((mins .+ edgelengths .* 5) .- maxs, edgelengths ./ 100, atol = 1e-4)

end