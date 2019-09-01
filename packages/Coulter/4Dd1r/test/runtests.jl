using Coulter
using Test
using Dates
using Distributions
using KernelDensity
using StatsBase
using Random

@testset "Loading" begin
    data = loadZ2("testdata/b_0_1.=#Z2", "blank")

    @test data.timepoint == DateTime(2017, 12, 22, 17, 46, 58)
    @test all(data.binheights .== 0.0)

    run = loadZ2("testdata/lat0um_0_1.=#Z2")

    @test mode(run.data) == run.binvols[findmax(run.binheights)[2]]
    @test minimum(run.data) == run.binvols[findfirst(!iszero, run.binheights)]
    @test maximum(run.data) == run.binvols[findlast(!iszero, run.binheights)]

    run2 = loadZ2("testdata/wt_0min_0_1.=#Z2", "wt")

    # correct values from Coulter software

    # make sure the common volume is in position 76
    @test findmax(run2.binheights)[2] == 76
    @test all(run2.binheights[75:77] .== [281, 326, 289])

    # load in total volume mode where the y axis is now counts*volume
    # this prevents overweighting of small volume objects
    run3 = loadZ2("testdata/wt_0min_0_1.=#Z2", "wt"; yvariable=:volume)

    # the coulter rounds to 4 digits
    @test all(map(x->round(x, digits=-2), run3.binheights[75:77]) .== [113.7e3, 133.6e3, 120.0e3])

    # test loading whole folders
    runs = Coulter.load_folder("testdata/")

    @test "wt" in keys(runs)
    @test sum(runs["wt"][1].data) == sum(run3.data)
end

@testset "Analysis" begin
    @testset "Peak-finding" begin
        # flat line, no peaks
        ys = fill(0.1, 20)
        xs = collect(1.0:20)

        @test length(Coulter._find_peaks(xs, ys, minx=0.0)) == 0

        # add two peaks at 10.5 and 16
        ys[1] = 0.0
        ys[10] = 0.2
        ys[11] = 0.2
        ys[16] = 0.4
        ys[17] = 0.3
        ys[18] = 0.1
        ys[20] = 0.0

        @test all(Coulter._find_peaks(xs, ys, minx=0.0) .== [10.5, 16.0])

        # more realistic example
        dist = MixtureModel([Normal(8.2, 0.75), Normal(9.6, 0.5)], [0.6, 0.4])
        xs = range(7, stop=17, length=400)
        ys = pdf.(dist, xs)

        Random.seed!(1234)
        sim_data = volume.(rand(dist, 10000))
        Random.seed!()

        kd_est = kde(sim_data)
        peaks = Coulter._find_peaks(collect(kd_est.x), kd_est.density, minx=0.0)
        @test all((peaks .- [289.325, 446.655]) .< 0.01)

        @test Coulter.extract_peak(sim_data) ≈ 446.654739
    end
end

@testset "Misc" begin
    @test volume(0.0) == 0.0
    @test volume(10.0) ≈ 523.59878
    @test diameter(0.0) == 0.0
    @test diameter(523.59878) ≈ 10.0
end
