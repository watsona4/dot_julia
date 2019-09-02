if Base.HOME_PROJECT[] !== nothing
    Base.HOME_PROJECT[] = abspath(Base.HOME_PROJECT[])
end

push!(LOAD_PATH, joinpath("..", "src"))

using Documenter, RunLengthArrays

makedocs(;
    modules = [RunLengthArrays],
    format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
    pages = [
        "Home" => "index.md",
    ],
    repo = "https://github.com/ziotom78/RunLengthArrays.jl/blob/{commit}{path}#L{line}",
    sitename = "RunLengthArrays.jl",
    authors = "Maurizio Tomasi",)

deploydocs(;
    repo = "github.com/ziotom78/RunLengthArrays.jl",)
