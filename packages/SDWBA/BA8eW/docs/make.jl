using Documenter, SDWBA


makedocs(
  sitename = "SDWBA.jl",
  authors = "Sam Urmy",
  # assets = ["assets/style.css"],
  pages = [
    "Introduction" => "index.md",
    "API reference" => "API.md",
    "Included Scatterering Models" => "Models.md"
  ]
)

deploydocs(
    repo = "github.com/ElOceanografo/SDWBA.jl.git",
)
