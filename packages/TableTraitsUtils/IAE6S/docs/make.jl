using Documenter, TableTraitsUtils

makedocs(
	modules = [TableTraitsUtils],
	sitename = "TableTraitsUtils.jl",
	analytics="UA-132838790-1",
	pages = [
        "Introduction" => "index.md"
    ]
)

deploydocs(
    repo = "github.com/queryverse/TableTraitsUtils.jl.git"
)
