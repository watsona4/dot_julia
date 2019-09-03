using Documenter, StressTest

makedocs(;
    modules=[StressTest],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/ianshmean/StressTest.jl/blob/{commit}{path}#L{line}",
    sitename="StressTest.jl",
    authors="Ian Butterworth <i.r.butterworth@gmail.com>",
    assets=String[],
)

deploydocs(;
    repo="github.com/ianshmean/StressTest.jl",
)
