@testset "LightObservable" begin

    @testset "General" begin

        # constructor
        @test typeof(LightObservable(Float64)) == LightObservable{Float64, 10}
        @test typeof(LightObservable(ComplexF64)) == LightObservable{ComplexF64, 10}
        @test typeof(LightObservable(zeros(2,2))) == LightObservable{Matrix{Float64}, 10}
        @test typeof(LightObservable(zeros(ComplexF64, 2,2))) == LightObservable{Matrix{ComplexF64}, 10}

        @test typeof(LightObservable(Int64)) == LightObservable{Float64, 10}
        @test typeof(LightObservable(zeros(Int64, 2,2))) == LightObservable{Matrix{Float64}, 10}

        # size etc.
        @test size(LightObservable(rand(10))) == () # TODO
        @test size(LightObservable([rand(2,2) for _ in 1:3])) == (2,2)
        @test ndims(LightObservable(rand(10))) == 0
        @test ndims(LightObservable([rand(2,2) for _ in 1:3])) == 2

        # name
        obs = LightObservable(Float64, name="myobs")
        @test name(obs) == "myobs"
        @test name(LightObservable(ComplexF64, name="julia")) == "julia"

        # adding and reading
        obs = LightObservable(Float64)
        @test inmemory(obs)
        @test isempty(obs)
        @test push!(obs, 1.0) == nothing
        @test length(obs) == 1
        @test append!(obs, 2.0:4.0) == nothing
        @test length(obs) == 4
        @test append!(obs, 5.0:9.0) == nothing
        @test length(obs) == 9
        @test push!(obs, 10.0) == nothing
        @test length(obs) == 10
        @test !isempty(obs)

        # more than alloc test
        @test typeof(LightObservable(Float64, alloc=1023)) == LightObservable{Float64,10}
        @test typeof(LightObservable(Float64, alloc=2^2 - 1)) == LightObservable{Float64,2}
        @test typeof(LightObservable(Float64, alloc=2^5 - 1)) == LightObservable{Float64,5}


        # adding matrix observables
        ots = [rand(ComplexF64, 2,2) for _ in 1:3]
        obs = LightObservable(zero(ots[1]))
        @test push!(obs, ots[1]) == nothing
        @test append!(obs, ots[2:3]) == nothing
        @test_throws MethodError push!(obs, rand(["a", "b"]))
        @test_throws DimensionMismatch push!(obs, rand(ComplexF64, 2,2,3,4))

        # adding vector observables
        ots = [rand(ComplexF64, 3) for _ in 1:3]
        obs = LightObservable(zero(ots[1]))
        @test push!(obs, ots[1]) == nothing
        @test append!(obs, ots[2:3]) == nothing
        @test_throws MethodError push!(obs, rand(["a", "b"]))
        @test_throws DimensionMismatch push!(obs, rand(ComplexF64, 4))
    end


    @testset "Statistics" begin
        @testset "Real Observables" begin
            ots = [0.00124803, 0.643089, 0.183268, 0.799899, 0.0857666, 0.955348, 0.165763, 0.765998, 0.63942, 0.308818]
            obs = LightObservable(ots)
            @test isapprox(mean(ots), mean(obs))
            @test isapprox(std(ots), std(obs))
            @test isapprox(var(ots), var(obs))

            @test_deprecated error(obs)
            @test std_error(obs) == 0.1083461975750141
            @test tau(obs) == 0.0
        end

        @testset "Complex Observables" begin
            ots = Complex{Float64}[0.458585+0.676913im, 0.41603+0.0800011im, 0.439703+0.472044im, 0.86602+0.756838im, 0.615955+0.312498im, 0.916813+0.150829im, 0.434218+0.839293im, 0.888952+0.648892im, 0.799521+0.734382im, 0.678336+0.810805im]
            obs = LightObservable(ots)
            @test isapprox(mean(ots), mean(obs))
            @test isapprox(std(ots), std(obs))
            @test isapprox(var(ots), var(obs))

            @test_deprecated error(obs)
            @test std_error(obs) == 0.10946759231383459
            @test tau(obs) == 0.0
        end

        @testset "Matrix Observables" begin
            ots = Array{Float64,2}[[0.127479 0.144452; 0.0934332 0.465612], [0.716647 0.576685; 0.44389 0.256331], [0.811945 0.457262; 0.634971 0.188656]]
            obs = LightObservable(ots)
            @test isapprox(mean(ots), mean(obs))
            @test isapprox(std(ots), std(obs))
            @test isapprox(var(ots), var(obs))

            @test_deprecated error(obs)
            @test all(isapprox.(std_error(obs), [0.214048 0.128871; 0.158569 0.083361], atol=1e-6))
            @test all(isapprox.(tau(obs), [0.0 0.0; 0.0 0.0], atol=1e-6))
        end
    end






    @testset "IO" begin
        mktempdir() do d
            cd(d) do
                obs = LightObservable(rand(10))

                @test export_result(obs, "myresults.jld", "myobservables") == nothing
                or = load_result("myresults.jld", "myobservables")
                @test typeof(or) == ObservableResult{Float64,Float64}
                rm("myresults.jld")

                # import BinningAnalysis # necessary! can we avoid this?
                # saveobs(obs, "myobs.jld", "myobservables/obs")
                # saveobs(obs, "myobs.jld", "myobservables/obs_again") # test writing to already existing file
                # x = loadobs("myobs.jld", "myobservables/obs")
                # @test mean(x) == mean(obs)
                # @test std_error(x) == std_error(obs)
                # @test "obs" in listobs("myobs.jld", "myobservables/")
                # rmobs("myobs.jld", "obs", "myobservables/")
                # @test !("obs" in listobs("myobs.jld", "myobservables/"))
                # rm("myobs.jld")
            end
        end
    end

end