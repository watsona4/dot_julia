using Documenter, EffectSizes

makedocs(;
    modules=[EffectSizes],
    format=Documenter.HTML(assets=String[]),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/harryscholes/EffectSizes.jl/blob/{commit}{path}#L{line}",
    sitename="EffectSizes.jl",
    authors="harryscholes",
)

deploydocs(;
    repo="github.com/harryscholes/EffectSizes.jl",
)
