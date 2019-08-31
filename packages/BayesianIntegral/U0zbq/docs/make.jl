using Documenter, BayesianIntegral

makedocs(
    format = Documenter.HTML(),
    sitename = "BayesianIntegral",
    modules = [BayesianIntegral],
    pages = ["index.md",
            "1_bayesian_integration.md",
            "2_training_hyperparameters.md",
            "99_refs.md"]
)

deploydocs(
    repo   = "github.com/s-baumann/BayesianIntegral.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing
)
