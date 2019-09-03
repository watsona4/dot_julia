using Documenter, SlurmWorkloadFileGenerator

makedocs(;
    modules=[SlurmWorkloadFileGenerator],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/singularitti/SlurmWorkloadFileGenerator.jl/blob/{commit}{path}#L{line}",
    sitename="SlurmWorkloadFileGenerator.jl",
    authors="Qi Zhang <singularitti@outlook.com>",
    assets=String[],
)

deploydocs(;
    repo="github.com/singularitti/SlurmWorkloadFileGenerator.jl",
)
