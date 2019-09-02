using Documenter, Indicators, Plots

makedocs(
    modules = [Indicators],
    sitename = "Indicators",
    authors="Jacob Amos",
    pages=["Home"=>"index.md",
           "Conventional" => ["Moving Averages" => "ma.md",
                              "Momentum Indicators" => "mom.md",
                              "Volatility Indicators" => "vol.md"],
           "Exotic" => ["Regressions"=>"reg.md",
                        "Trendlines" => "trendy.md",
                        "Patterns" => "patterns.md"]],
    format = Documenter.HTML(),
    doctest=false,
    clean=true,
)

deploydocs(deps=Deps.pip("mkdocs", "python-markdown-math"),
           repo="github.com/dysonance/Indicators.jl.git",
           devbranch="master",
           devurl="dev",
           versions=["stable" => "v^", "v#.#", "dev" => "dev"])
