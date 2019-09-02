using Test, KongYiji, Pkg, JLD2, FileIO, ProgressMeter


#=
@testset "Generating REQUIRE file..." begin
        println(Pkg.METADATA_compatible_uuid("KongYiji"))
        PT = Pkg.Types
        Pkg.activate("..")             # current directory as the project
        ctx = PT.Context()
        pkg = ctx.env.pkg
        if pkg ≡ nothing
            @error "Not in a package, I won't generate REQUIRE."
            exit(1)
        else
            @info "found package" pkg = pkg
        end

        deps = PT.get_deps(ctx)
        non_std_deps = sort(collect(setdiff(keys(deps), values(ctx.stdlibs))))

        open(joinpath("..", "REQUIRE"), "w") do io
            println(io, "julia 0.7")
            for d in non_std_deps
                println(io, d)
                @info "listing $d"
            end
        end
end
=#

#=
@testset "Generating CTB data file..." begin
        home = joinpath("d:\\", "ctb8.0")
        @time ctb = KongYiji.ChTreebank(home; nf=0)
        ctb_path = joinpath(pathof(KongYiji), "..", "..", "data")
        ctb_name = joinpath(ctb_path, "ctb.jld2")
        mkpath(ctb_path)
        @time @save ctb_name ctb
        @time zipped_name = KongYiji.zip7(ctb_name)
        rm(ctb_name)
        @time unzipped_name = KongYiji.unzip7(zipped_name)
        @time ctb2 = load(unzipped_name)["ctb"]
        @time @test ctb == ctb2
end
=#

@testset "Test CTB postable..." begin
        println(postable())
end

#=
@testset "Cross validating HMM on CTB..." begin
        @time unzipped_file = KongYiji.unzip7(joinpath(pathof(KongYiji), "..", "..", "data", "ctb.jld2.7z"))
        @time ctb = load(unzipped_file)["ctb"]
        @show length(ctb)
        folds = KongYiji.kfolds(ctb; k=10)
        k = length(folds)
        tbs = Vector{KongYiji.HmmScoreTable}(undef, k)
        @showprogress 1 "Cross Validating HMM..." for i in 1:k
                test = folds[i]
                train = collect(Iterators.flatten([folds[j] for j in 1:k if j != i]))
                hmm = KongYiji.HMM(train)
                KongYiji.normalize!(hmm) # Don't forget
                x = test
                y = hmm(x)
                tbs[i] = KongYiji.HmmScoreTable(x, y)
        #        println(tbs[i])
        end
        hmmscoretable = sum(tbs)
        println(hmmscoretable)
end
=#

#=
@testset "Generating HMM model file of CTB..." begin
        @time ctb_home = KongYiji.unzip7(joinpath(pathof(KongYiji), "..", "..", "data", "ctb.jld2.7z"))
        @time ctb = load(ctb_home)["ctb"]
        @time hmm = KongYiji.HMM(ctb)
        home = joinpath(pathof(KongYiji), "..", "..", "data", "hmm.jld2")
        mkpath(dirname(home))
        @time @save home hmm
        @time zhome = KongYiji.zip7(home)
        rm(home)
        @time home2 = KongYiji.unzip7(zhome)
        @assert home == home2
        @time hmm2 = load(home2)["hmm"]
        @test hmm == hmm2
end
=#

@testset "Test KongYiji(1) with Hand written examples..." begin
        tk = Kong()
        input = "一个脱离了低级趣味的人"
        output = tk(input)
        @show output

        input = "一/个/脱离/了/低级/趣味/的/人"
        tk(input, "/")

        inputs = [
                "他/说/的/确实/在理",
                "这/事/的确/定/不/下来",
                "费孝通/向/人大/常委会/提交/书面/报告",
                "邓颖超/生前/使用/过/的/物品",
                "停电/范围/包括/沙坪坝区/的/犀牛屙屎/和/犀牛屙屎抽水",
        ]
        println("Input :")
        for input in inputs
                println(input)
        end

        println("raw output :")
        for input in inputs
                println(tk(filter(c -> c != '/', input)))
        end
        
        tk2 = Kong(; user_dict_array=[("VV", "定"),
                                      ("VA", "在理"),
                                       "邓颖超",
                                       "沙坪坝区", 
                                       "犀牛屙屎",
                                       "犀牛屙屎抽水",
                                     ]
        )
        println("output with user dict supplied :")
        for input in inputs
                println(tk2(filter(c -> c != '/', input)))
        end
end
