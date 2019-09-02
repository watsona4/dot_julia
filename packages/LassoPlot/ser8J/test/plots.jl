datapath = joinpath(dirname(pathof(Lasso)),"..","test","data")
plotspath = joinpath(dirname(@__FILE__), "plots")
mkpath(plotspath)

Random.seed!(243214)
@testset "plot GammaLassoPath's" begin
    @testset "$family" for (family, dist, link) in (("gaussian", Normal(), IdentityLink()), ("binomial", Binomial(), LogitLink()), ("poisson", Poisson(), LogLink()))
        data = CSV.read(joinpath(datapath,"gamlr.$family.data.csv"))
        y = convert(Vector{Float64},data[1])
        X = convert(Matrix{Float64},data[2:end])
        (n,p) = size(X)
        @testset "γ=$γ" for γ in (0, 2, 10)
            @testset "x=$x" for x in (:segment, :λ, :logλ)
                fitname = "gamma$γ.pf1"
                if !isfile(joinpath(datapath,"gamlr.$family.$fitname.params.csv"))
                    # file names in older Lasso packages
                    fitname = "gamma$γ"
                end
                # get gamlr.R params and estimates
                params = CSV.read(joinpath(datapath,"gamlr.$family.$fitname.params.csv"))
                fittable = CSV.read(joinpath(datapath,"gamlr.$family.$fitname.fit.csv"))
                gcoefs = convert(Matrix{Float64},CSV.read(joinpath(datapath,"gamlr.$family.$fitname.coefs.csv")))
                family = params[1,Symbol("fit.family")]
                γ=params[1,Symbol("fit.gamma")]

                # fit julia version
                glp = fit(GammaLassoPath, X, y, dist, link; γ=γ, λminratio=0.001)

                # test plots
                p = plot(glp;x=x)
                filename = joinpath(plotspath,"$family.$fitname.$x.svg")
                savefig(p, filename)
                @test isfile(filename)
            end
        end
    end
end
