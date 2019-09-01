using Documenter, FeatherLib

makedocs(
	modules = [FeatherLib],
	sitename = "FeatherLib.jl",
	analytics="UA-132838790-1",
	pages = [
        "Introduction" => "index.md"
    ]
)

deploydocs(
    repo = "github.com/queryverse/FeatherLib.jl.git"
)
