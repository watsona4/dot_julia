@testset "Cross mapping" begin
	@testset "Find nearest indices within exclusion radius" begin
	    some_idxs = 1:21 |> collect
	    some_dists = rand(length(some_idxs))
	    d = 3
	    exclusion_radius = 7
	    dists = rand(length(some_idxs))
	    idxs, dists = [some_idxs, some_idxs.+1], [some_dists, some_dists]
	    libsize = length(some_idxs)
	    pt_time_idx = 10
	    nearest_idxs = [Vector{Int32}(undef, d + 1) for i = 1:2]
	    nearest_dists = [Vector{Float64}(undef, d + 1) for i = 1:2]
	    find_nearest!(nearest_idxs, nearest_dists, pt_time_idx, idxs, dists, d, exclusion_radius)
	    @test nearest_idxs[1] == [2, 18, 19, 20]
	    @test nearest_idxs[2] == [18, 19, 20, 21]

	    # Too large exclusion radius
	    @test_throws DomainError find_nearest!(nearest_idxs, nearest_dists, 12, idxs, dists, d, exclusion_radius + 10)
	end

	@testset "Prediction lags" begin
	    x, y = rand(100), rand(100)
	    crossmap(x, y, ν = 1)
	    crossmap(x, y, ν = -1)
	    crossmap(x, y, ν = 5)
	    crossmap(x, y, ν = -5)
	end

	@testset "Embedding params" begin
	    x, y = rand(100), rand(100)
	    @test_throws DomainError crossmap(x, y, dim = -3)
	    @test_throws DomainError crossmap(x, y, dim = 100, τ = 2)
	    crossmap(x, y, dim = 3)
	    crossmap(x, y, dim = 10, τ = 2)
	end

	@testset "Exclusion radii" begin
	    x, y = rand(100), rand(100)
	    [crossmap(x, y, exclusion_radius = i) for i in rand(1:25, 10)]
	    #@test_throws DomainError crossmap(x, y, exclusion_radius = -1)
	end

	@testset "Replacements" begin
	    x, y = rand(100), rand(100)
	    crossmap(x, y, replace = false)
	    crossmap(x, y, replace = true)
	end

	@testset "Surrogates" begin
    x, y = rand(100), rand(100)
	    @testset "Surrogate types" begin
	        surrogate_funcs = [TimeseriesSurrogates.randomshuffle,
	                            TimeseriesSurrogates.randomphases,
	                            TimeseriesSurrogates.randomamplitudes,
	                            TimeseriesSurrogates.aaft,
	                            TimeseriesSurrogates.iaaft]
	        [crossmap(x, y, surr_func = surr_func) for surr_func in surrogate_funcs]
	        @test_throws DomainError crossmap(x, y, surr_func = StatsBase.cor)
	    end
	    @testset "Which is surrogated" begin
	        which_surr = [:none, :both, :driver, :response]
	        [crossmap(x, y, which_is_surr = surr) for surr in which_surr]
	        @test_throws DomainError crossmap(x, y, which_is_surr = :aksdj)
	    end
	end

	@testset "Correspondence measures" begin
	    @testset "$i" for i in 1:100
	        x, y = rand(100), rand(100)
	        @test all(crossmap(x, y, correspondence_measure = StatsBase.rmsd) .>= 0)
	        @test all([-1 <= x <= 1 for x in crossmap(x, y, correspondence_measure = StatsBase.cor)])
	    end
	end

end
