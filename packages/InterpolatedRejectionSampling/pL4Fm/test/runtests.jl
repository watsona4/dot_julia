using InterpolatedRejectionSampling
using InterpolatedRejectionSampling: get_knots, integrate, normalize_interp,
    is_normalized, get_interp, maxmapreduce, Cells, sample, Support, iterate,
    propose_sample, get_extrema, Envelope, rsample, irsample, irsample!

using Test
using Interpolations

using Random: seed!
seed!(1234)

slice = [missing,missing,0.3]
knots = (π.*[0.0, sort(rand(20))..., 1.0],
         π.*[0.0, sort(rand(19))..., 1.0],
         π.*[0.0, sort(rand(18))..., 1.0])

coefs = [sin(x)*sin(y)*sin(z) for x=knots[1],y=knots[2],z=knots[3]]
interp = LinearInterpolation(knots,coefs)


ranges = (range(0, stop=π, length=20),
          range(0, stop=π, length=19),
          range(0, stop=π, length=18))
coefs_ranges = [sin(x)*sin(y)*sin(z) for x=ranges[1],y=ranges[2],z=ranges[3]]
interp_ranges = LinearInterpolation(ranges,coefs_ranges)

@testset "Utilities" begin
    @test get_knots(interp) === knots
    @test isapprox(integrate(interp), 8.0; atol = 0.5)

    @test get_knots(interp_ranges) === ranges
    @test isapprox(integrate(interp_ranges), 8.0; atol = 0.5)

    ninterp = normalize_interp(interp)
    @test isa(ninterp, AbstractExtrapolation)
    @test isapprox(integrate(ninterp), one(Float64))
    @test is_normalized(ninterp)

    ninterp = normalize_interp(interp_ranges)
    @test isa(ninterp, AbstractExtrapolation)
    @test isapprox(integrate(ninterp), one(Float64))
    @test is_normalized(ninterp)

    pnt = (0.2,1.0,0.9)
    @test get_interp(interp, pnt) === interp(pnt...)
    @test get_interp(interp_ranges, pnt) === interp_ranges(pnt...)
    @test maxmapreduce(x -> x^2, [0.0, 0.5, -2.0, 1.5]) == 4.0
end

@testset "Cells" begin
    cells = Cells(interp)
    @test isa(cells, Cells)

    s = sample(cells)
    @test isa(s, CartesianIndex{3})

    cells = Cells(interp,slice)
    @test isa(cells, Cells)

    s = sample(cells)
    @test isa(s, CartesianIndex{3})

    cells = Cells(interp_ranges)
    @test isa(cells, Cells)
end

@testset "Support" begin
    cells = Cells(interp)
    s = sample(cells)
    supp = Support(cells, s)
    @test isa(supp, Support{Float64,3})

    @test isa(iterate(supp), Tuple{NTuple{2,Float64}, Int})
    @test isa(iterate(supp,2), Tuple{NTuple{2,Float64}, Int})
    @test isa(iterate(supp,3), Tuple{NTuple{2,Float64}, Int})
    @test isa(iterate(supp,4), Nothing)

    samp = propose_sample(supp)
    @test isa(samp, NTuple{3,Float64})

    spnts = get_extrema(supp)
    @test length(spnts) == 8
    @test eltype(spnts) == NTuple{3,Float64}
end

@testset "Envelope/rsample" begin
    cells = Cells(interp)
    s = sample(cells)
    envelope = Envelope(cells, s)
    @test isa(envelope, Envelope)
    @test isa(rsample(envelope), NTuple{3,Float64})
    @test isa(rsample(interp), NTuple{3,Float64})
    @test isa(rsample(interp, slice), NTuple{3,Float64})
end

@testset "irsample/irsample!" begin
    @test isa(irsample(knots, coefs), NTuple{3,Float64})

    samp = irsample(knots, coefs, 2)
    @test isa(samp, Matrix{Float64})
    @test size(samp) == (3,2)

    slices = Matrix{Union{Missing,Float64}}(missing, 3, 3)
    slices[1,1], slices[1,2], slices[2,2] = 0.2, 0.3, 0.4
    @test !iszero(count(ismissing, slices))

    irsample!(slices, knots, coefs)
    @test iszero(count(ismissing, slices))
    @test isa(convert(Matrix{Float64}, slices), Matrix{Float64})


    @test isa(irsample(ranges, coefs_ranges), NTuple{3,Float64})

    samp = irsample(ranges, coefs_ranges, 2)
    @test isa(samp, Matrix{Float64})
    @test size(samp) == (3,2)

    slices = Matrix{Union{Missing,Float64}}(missing, 3, 3)
    slices[1,1], slices[1,2], slices[2,2] = 0.2, 0.3, 0.4
    @test !iszero(count(ismissing, slices))

    irsample!(slices, ranges, coefs_ranges)
    @test iszero(count(ismissing, slices))
    @test isa(convert(Matrix{Float64}, slices), Matrix{Float64})
end
