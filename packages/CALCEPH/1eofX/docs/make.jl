using Documenter, CALCEPH

makedocs(
    format = :html,
	sitename = "CALCEPH.jl",
	authors = "Bernard Godard and the CALCEPH.jl contributors",
	pages = [
		"Home" => "index.md",
		"Tutorial" => "tutorial.md",
		"API" => "api.md"
	],
)

deploydocs(
	repo = "github.com/JuliaAstro/CALCEPH.jl.git",
	target = "build",
)
