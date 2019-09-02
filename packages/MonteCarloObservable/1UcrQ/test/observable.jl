@testset "Observable" begin
    
    @testset "General" begin

        # constructor
        @test typeof(Observable(Float64, "myobs")) == Observable{Float64, Float64, true}
        @test typeof(Observable(ComplexF64, "myobs")) == Observable{ComplexF64, ComplexF64, true}
        @test typeof(Observable(Matrix{Float64}, "myobs")) == Observable{Matrix{Float64}, Matrix{Float64}, true}
        @test typeof(Observable(Matrix{ComplexF64}, "myobs")) == Observable{Matrix{ComplexF64}, Matrix{ComplexF64}, true}

        @test typeof(Observable(Int64, "myobs")) == Observable{Int64, Float64, true}
        @test typeof(Observable(Int64, "myobs"; meantype=Int64)) == Observable{Int64, Int64, true}
        @test typeof(Observable(Matrix{Int64}, "myobs")) == Observable{Matrix{Int64}, Matrix{Float64}, true}

        @test eltype(Observable(Int64, "myobs")) == Int64
        @test eltype(Observable(Matrix{Int64}, "myobs")) == Matrix{Int64}

        # macro
        @test (@obs rand(10)) isa Observable{Float64, Float64}
        @test (@obs [rand(2,2) for _ in 1:3]) isa Observable{Array{Float64, 2}, Array{Float64, 2}}

        # size etc.
        @test size(@obs rand(10)) == () # TODO
        @test size(@obs [rand(2,2) for _ in 1:3]) == (2,2)
        @test ndims(@obs rand(10)) == 0
        @test ndims(@obs [rand(2,2) for _ in 1:3]) == 2

        # name
        obs = Observable(Float64, "myobs")
        @test name(obs) == "myobs"
        @test name(Observable(ComplexF64, "julia")) == "julia"
        rename(obs, "juhu")
        @test name(obs) == "juhu"

        # adding and reading
        obs = Observable(Float64, "myobs")
        @test inmemory(obs)
        @test isinmemory(obs)
        @test push!(obs, 1.0) == nothing
        @test obs[1] == 1.0
        @test length(obs) == 1
        @test push!(obs, 2.0:4.0) == nothing
        @test length(obs) == 4
        @test push!(obs, 5.0:9.0) == nothing
        @test length(obs) == 9
        @test push!(obs, 10.0) == nothing
        @test length(obs) == 10
        @test timeseries(obs) == 1.0:10.0
        @test obs[3] == 3.0
        @test obs[2:4] == 2.0:4.0
        @test obs[:] == timeseries(obs)
        @test_throws BoundsError obs[length(obs)+1]
        @test view(obs, 3)[1] == 3.0 # view is 0-dimensional
        @test view(obs, 2:4) == 2.0:4.0
        @test view(obs, :) == timeseries(obs)
        @test_throws BoundsError view(obs, length(obs)+1)
        @test typeof(view(obs, 1:3)) <: SubArray
        @test !isempty(obs)
        @test obs == (@obs 1.0:10.0)

        # more than alloc test
        obs = Observable(Float64, "alloctest"; alloc=2)
        obsts = rand(3)
        @test push!(obs, obsts) == nothing
        @test ts(obs) == obsts

        # adding matrix observables
        ots = Array{Complex{Float64},2}[[0.756093+0.842213im 0.229536+0.982145im; 0.996734+0.104368im 0.198649+0.601362im], [0.66988+0.916039im 0.804259+0.976707im; 0.554345+0.249875im 0.369942+0.297061im], [0.714291+0.158981im 0.220397+0.845512im; 0.0493697+0.543434im 0.0556234+0.993021im], [0.319155+0.733874im 0.998182+0.729351im; 0.263825+0.568651im 0.848669+0.694285im]]
        obs = Observable(Matrix{ComplexF64}, "mcxobs")
        @test push!(obs, ots[1]) == nothing
        @test push!(obs, ots[1]) == nothing
        @test push!(obs, ots[2:3]) == nothing
        @test push!(obs, ots[2:3]) == nothing
        @test push!(obs, rand(ComplexF64, 2,2,3)) == nothing
        @test_throws MethodError push!(obs, rand(["a", "b"], 2,2,3))
        @test_throws DimensionMismatch push!(obs, rand(ComplexF64, 2,2,3,4))
        @test_throws ErrorException push!(obs, rand(ComplexF64, 3,4,3))

        # adding vector observables
        ots = Array{Complex{Float64},1}[[0.256218+0.421853im, 0.233299+0.525431im], [0.551768+0.0536659im, 0.0137919+0.656025im], [0.467164+0.0565131im, 0.720137+0.486299im], [0.953352+0.694809im, 0.334231+0.56174im], [0.634737+0.88592im, 0.308682+0.944125im]]
        obs = Observable(Vector{ComplexF64}, "vcxobs")
        @test push!(obs, ots[1]) == nothing
        @test push!(obs, ots[1]) == nothing
        @test push!(obs, ots[2:3]) == nothing
        @test push!(obs, ots[2:3]) == nothing
        @test push!(obs, rand(ComplexF64, 2,3)) == nothing
        @test_throws MethodError push!(obs, rand(["a", "b"], 2,3))
        @test_throws DimensionMismatch push!(obs, rand(ComplexF64, 2,3,4))
        @test_throws ErrorException push!(obs, rand(ComplexF64, 3,3))

        # reset
        reset!(obs)
        @test length(obs) == 0
        @test isempty(obs)

        # meantype
        obs = Observable(Int8, "MyObs"; meantype=Float32)
        push!(obs, Int8[1,2,3])
        @test typeof(mean(obs)) == Float32

        # iterator interface
        ots = [1,4,5,2]
        obs = @obs ots
        f = o -> begin
            for (idx, val) in enumerate(obs)
                ots[idx] == val || (return false)
            end
            return true
        end
        @test f(obs)
    end


    @testset "Statistics" begin
        @testset "Real Observables" begin
            ots = [0.00124803, 0.643089, 0.183268, 0.799899, 0.0857666, 0.955348, 0.165763, 0.765998, 0.63942, 0.308818]
            obs = @obs ots
            @test mean(ots) == mean(obs)
            @test mean(obs) == 0.454861763
            @test std(ots) == std(obs)
            @test std(obs) == 0.3426207601556565
            @test var(obs) == var(ots)
            @test var(obs) == 0.1173889852896399

            @test std_error(obs) ≈ 0.1083461975750141
            @test std_error(ots) ≈ 0.1083461975750141
            @test tau(obs) == 0.0
            @test tau(ots) == 0.0

            # jackknife
            @test jackknife(identity, obs)[2] ≈ 0.10834619757501414
            @test jackknife(identity, 1 ./ ts(obs))[2] ≈ 79.76537738034833
            @test jackknife(identity, ts(obs))[1] ≈ 0.45486176300000025
            ots2 = [0.606857, 0.0227746, 0.805997, 0.978731, 0.0853112, 0.311463, 0.628918, 0.0190664, 0.515998, 0.0223728]
            g(ots1, ots2) = ots1^2 - ots2
            @test jackknife(g, ots, ots2 .^2)[2] ≈ 0.14501699232741938

            # scalar
            @test !iswithinerrorbars(3.123,3.12,0.001)
            @test !iswithinerrorbars(3.123,3.12,0.001, true) # print=true
            @test iswithinerrorbars(3.123,3.12,0.004)
            @test iswithinerrorbars(0.0,-0.1,0.1)
            # TODO: fix method first (make it reasonable)
            # obs2 = @obs ots .+ 0.02
            # @test iswithinerrorbars(obs, obs2, 0.03)
        end

        @testset "Complex Observables" begin
            ots = Complex{Float64}[0.458585+0.676913im, 0.41603+0.0800011im, 0.439703+0.472044im, 0.86602+0.756838im, 0.615955+0.312498im, 0.916813+0.150829im, 0.434218+0.839293im, 0.888952+0.648892im, 0.799521+0.734382im, 0.678336+0.810805im]
            obs = @obs ots
            @test mean(ots) == mean(obs)
            @test mean(obs) == 0.6514133 + 0.54824951im
            @test std(ots) == std(obs)
            @test std(obs) == 0.34616692168645863
            @test var(obs) == var(ots)
            @test var(obs) == 0.11983153766987877

            @test std_error(obs) ≈ 0.1094675923138345
            @test std_error(ots) ≈ 0.1094675923138345
            @test tau(obs) ≈ 0.0
            @test tau(ots) ≈ 0.0

            # jackknife
            @test jackknife(identity, obs)[2] ≈ 0.10946759231383452
            @test jackknife(identity, 1 ./ ots)[2] ≈ 0.1930517185451075
            @test jackknife(identity, ts(obs))[1] ≈ 0.6514132999999989 + 0.5482495099999998im

            # scalar
            @test !iswithinerrorbars(0.195 + 0.519im, 0.196 + 0.519im ,0.001)
            @test iswithinerrorbars(0.195 + 0.519im, 0.196 + 0.519im, 0.01)
            @test !iswithinerrorbars(0.195 + 0.519im, 0.195 + 0.520im, 0.001)
            @test iswithinerrorbars(0.195 + 0.519im, 0.195 + 0.520im, 0.01)
        end

        @testset "Matrix Observables" begin
            ots = Array{Float64,2}[[0.127479 0.144452; 0.0934332 0.465612], [0.716647 0.576685; 0.44389 0.256331], [0.811945 0.457262; 0.634971 0.188656]]
            obs = @obs ots
            @test mean(ots) == mean(obs)
            @test isapprox(mean(obs), [0.552024 0.3928; 0.390765 0.303533], atol=1e-6)
            @test std(ots) == std(obs)
            @test isapprox(std(obs), [0.370741 0.22321; 0.27465 0.144386], atol=1e-6)
            @test var(obs) == var(ots)
            @test isapprox(var(obs), [0.137449 0.0498229; 0.0754325 0.0208472], atol=1e-6)

            @test isapprox(std_error(obs), [0.214048 0.128871; 0.158569 0.083361], atol=1e-6)
            @test isapprox(std_error(ots), [0.214048 0.128871; 0.158569 0.083361], atol=1e-6)
            @test isapprox(tau(obs), [0.0 0.0; 0.0 0.0], atol=1e-6)
            @test isapprox(tau(ots), [0.0 0.0; 0.0 0.0], atol=1e-6)

            # jackknife
            # TODO: not supported by BinningAnalysis.jl?

            A = rand(2,2)
            B = A .+ 0.02
            @test iswithinerrorbars(A,B,fill(0.1, 2,2))
            @test !iswithinerrorbars(A,B,fill(0.01, 2,2))
            @test !iswithinerrorbars(A,B,fill(0.01, 2,2), true)
            A = rand(ComplexF64, 2,2)
            B = A .+ 0.02
            @test_logs (:warn, "Unfortunately print=true is only supported for real input.") !iswithinerrorbars(A,B,fill(0.01, 2,2), true)
        end
    end


    @testset "Disk observables" begin
        @testset "Real Observables" begin
            mktempdir() do d
                cd(d) do
                    # constructor
                    obs = Observable(Float64, "myobs"; inmemory=false, alloc=10)
                    @test !inmemory(obs)

                    # macro
                    @test !inmemory(@diskobs rand(5))

                    push!(obs, 1.0:9.0)
                    @test !isfile(obs.outfile)
                    @test timeseries(obs) == 1.0:9.0
                    @test obs[1] == 1.0
                    @test obs[1:3] == 1.0:3.0
                    push!(obs, 10.0)
                    @test isfile(obs.outfile)

                    @test timeseries_frommemory("Observables.jld", "myobs") == 1.0:10.0
                    @test timeseries_frommemory_flat("Observables.jld", "myobs") == 1.0:10.0
                    @test timeseries("Observables.jld", "myobs") == 1.0:10.0
                    @test timeseries_flat("Observables.jld", "myobs") == 1.0:10.0
                    @test ts("Observables.jld", "myobs") == 1.0:10.0
                    @test ts_flat("Observables.jld", "myobs") == 1.0:10.0
                    x = loadobs_frommemory("Observables.jld", "myobs")
                    @test x == obs
                    @test x[1:end] == ts(obs)
                    for i in 1:length(x)
                        @test x[i] == obs[i]
                    end


                    push!(obs, 11.0:20.0)
                    @test ts(obs) == 1.0:20.0
                    @test obs[1:3] == 1.0:3.0 # slice within chunk
                    @test obs[9:13] == 9.0:13.0 # slice spanning multiple chunks
                    @test obs[18:end] == 18.0:20.0
                    @test obs[3] == 3.0
                    @test obs[:] == timeseries(obs)
                    @test_throws BoundsError obs[length(obs)+1]
                    @test_throws BoundsError obs[1:length(obs)+1]
                    @test_throws BoundsError obs[-1:2]

                    @test_throws ErrorException view(obs, 1:3) # views not yet supported for diskobs
                    @test_throws ErrorException view(obs, 1) # views not yet supported for diskobs
                    @test_throws ErrorException view(obs, :) # views not yet supported for diskobs


                    # test manual flushing
                    obs = Observable(Float64, "flushtest"; inmemory=false, alloc=10)
                    push!(obs, 1.0:5.0)
                    isfile(obs.outfile) ? rm(obs.outfile) : nothing
                    @test flush(obs) == nothing
                    @test isfile(obs.outfile)
                    @test ts(obs.outfile, "flushtest") == 1.0:5.0
                    @test ts_flat(obs.outfile, "flushtest") == 1.0:5.0
                    obs2 = loadobs_frommemory(obs.outfile, "flushtest")
                    @test obs == obs2
                    push!(obs, 6.0:10.0) # force regular flush
                    obs2 = loadobs_frommemory(obs.outfile, "flushtest")
                    @test obs == obs2

                    # test no flush if obs.tsidx == 1 (there is nothing to flush)
                    rm("Observables.jld")
                    obs = Observable(Float64, "flushtest"; inmemory=false, alloc=10)
                    push!(obs, rand(10))
                    @test HDF5.h5read("Observables.jld", "flushtest/timeseries/chunk_count") == 1
                    flush(obs)
                    @test HDF5.h5read("Observables.jld", "flushtest/timeseries/chunk_count") == 1
                end
            end
        end

        @testset "Complex Observables" begin
            mktempdir() do d
                cd(d) do
                    # constructor
                    obs = Observable(ComplexF64, "myobs"; inmemory=false, alloc=10)
                    @test !inmemory(obs)

                    # macro
                    @test !inmemory(@diskobs rand(ComplexF64, 10))

                    data = Complex{Float64}[0.589744+0.252428im, 0.737068+0.154224im, 0.65847+0.546091im, 0.536648+0.989492im, 0.365943+0.401982im, 0.679054+0.65316im, 0.517828+0.259064im, 0.452195+0.0356182im, 0.771914+0.392988im, 0.11461+0.23768im, 0.800796+0.584551im, 0.100475+0.400542im, 0.196098+0.325246im, 0.616814+0.480603im, 0.402191+0.400236im, 0.835151+0.981177im, 0.981963+0.554879im, 0.97145+0.854191im, 0.0723336+0.390246im, 0.831044+0.446365im]
                    push!(obs, data[1:9])
                    @test !isfile(obs.outfile)
                    push!(obs, data[10])
                    @test isfile(obs.outfile)

                    @test timeseries_frommemory("Observables.jld", "myobs") == data[1:10]
                    @test timeseries_frommemory_flat("Observables.jld", "myobs") == data[1:10]
                    @test timeseries("Observables.jld", "myobs") == data[1:10]
                    @test timeseries_flat("Observables.jld", "myobs") == data[1:10]
                    @test ts("Observables.jld", "myobs") == data[1:10]
                    @test ts_flat("Observables.jld", "myobs") == data[1:10]
                    @test loadobs_frommemory("Observables.jld", "myobs") == obs

                    push!(obs, data[11:20])
                    @test ts(obs) == data[1:20]
                    @test obs[1:3] == data[1:3] # slice within chunk
                    @test obs[9:13] == data[9:13] # slice spanning multiple chunks
                    @test obs[18:end] == data[18:20]
                    @test obs[3] == data[3]
                    @test obs[:] == timeseries(obs)
                end
            end
        end

        @testset "Matrix Observables" begin
            mktempdir() do d
                cd(d) do
                    # constructor
                    obs = Observable(Matrix{ComplexF64}, "myobs"; inmemory=false, alloc=2)
                    @test !inmemory(obs)

                    # macro
                    @test !inmemory(@diskobs [rand(ComplexF64, 2,3) for _ in 1:2])

                    data = Array{Complex{Float64},2}[[0.497019+0.161613im 0.142061+0.205009im; 0.0387687+0.602916im 0.131416+0.641818im], [0.958829+0.250432im 0.82005+0.0678016im; 0.428906+0.40505im 0.323868+0.657073im], [0.267133+0.794451im 0.289949+0.363709im; 0.124168+0.541679im 0.519768+0.82765im], [0.932745+0.157519im 0.314411+0.0119721im; 0.266742+0.0445631im 0.756244+0.158147im]]
                    push!(obs, data[1])
                    @test !isfile(obs.outfile)
                    push!(obs, data[2])
                    @test isfile(obs.outfile)

                    data_flat = cat(data..., dims=3)
                    @test timeseries_frommemory("Observables.jld", "myobs") == data[1:2]
                    @test timeseries_frommemory_flat("Observables.jld", "myobs") == data_flat[:,:,1:2]
                    @test timeseries("Observables.jld", "myobs") == data[1:2]
                    @test timeseries_flat("Observables.jld", "myobs") == data_flat[:,:,1:2]
                    @test ts("Observables.jld", "myobs") == data[1:2]
                    @test ts_flat("Observables.jld", "myobs") == data_flat[:,:,1:2]
                    @test loadobs_frommemory("Observables.jld", "myobs") == obs

                    push!(obs, data[3:4])
                    @test ts(obs) == data[1:4]
                    @test obs[1:2] == data[1:2] # slice within chunk
                    @test obs[2:3] == data[2:3] # slice spanning multiple chunks
                    @test obs[2:end] == data[2:end]
                    @test obs[3] == data[3]
                    @test obs[:] == timeseries(obs)

                    # test manual flushing
                    obs = Observable(Matrix{Float64}, "mflushtest"; inmemory=false, alloc=5)
                    obsts = [rand(2,2) for _ in 1:5]
                    push!(obs, obsts[1:3])
                    isfile(obs.outfile) ? rm(obs.outfile) : nothing
                    @test flush(obs) == nothing
                    @test isfile(obs.outfile)
                    @test ts(obs.outfile, "mflushtest") == obsts[1:3]
                    @test ts_flat(obs.outfile, "mflushtest") == cat(obsts[1:3]..., dims=3)
                    obs2 = loadobs_frommemory(obs.outfile, "mflushtest")
                    @test obs == obs2
                    push!(obs, obsts[4:5]) # force regular flush
                    obs2 = loadobs_frommemory(obs.outfile, "mflushtest")
                    @test obs == obs2
                end
            end
            end
    end


    @testset "IO" begin
        mktempdir() do d
            cd(d) do
                obs = @obs rand(10)
                saveobs(obs, "myobs.jld", "myobservables/obs")
                saveobs(obs, "myobs.jld", "myobservables/obs_again") # test writing to already existing file
                x = loadobs("myobs.jld", "myobservables/obs")
                @test x == obs
                @test "obs" in listobs("myobs.jld", "myobservables/")
                rmobs("myobs.jld", "obs", "myobservables/")
                @test !("obs" in listobs("myobs.jld", "myobservables/"))

                export_result(obs, "myresults.jld", "myobservables"; timeseries=true)
                ots = timeseries_frommemory_flat("myresults.jld", "myobservables/")
                @test ots == timeseries(obs)
                ots = timeseries_frommemory("myresults.jld", "myobservables/")
                @test ots == timeseries(obs)

                MonteCarloObservable.export_error(obs, "myobs.jld" ,"myobservables/obserror")
                HDF5.h5open("myobs.jld", "r") do f
                    @test HDF5.has(f, "myobservables/obserror/error")
                    @test HDF5.has(f, "myobservables/obserror/error_rel")
                    @test HDF5.read(f["myobservables/obserror/error"]) == std_error(obs)
                    @test HDF5.read(f["myobservables/obserror/error_rel"]) == std_error(obs)/mean(obs)
                end

                rm("myobs.jld")
                rm("myresults.jld")
            end
        end
    end
    
end