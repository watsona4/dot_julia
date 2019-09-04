push!(LOAD_PATH,"../src/")
using Documenter, Triangle

makedocs(
	format = :html,
	sitename = "Triangle.jl",
	pages = [
		"Home" => "index.md"
	]
)
