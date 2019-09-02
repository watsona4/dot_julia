using Documenter, ItemGraphs

makedocs(
    format = Documenter.HTML(
		prettyurls = get(ENV, "CI", nothing) == "true",
	),
	sitename = "ItemGraphs.jl",
	authors = "Helge Eichhorn and the ItemGraphs.jl contributors",
	pages = [
		"Home" => "index.md",
		"API" => "api.md",
	],
)

deploydocs(
    repo = "github.com/helgee/ItemGraphs.jl.git",
    target = "build",
)
