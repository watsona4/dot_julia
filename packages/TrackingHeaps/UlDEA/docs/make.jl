using Documenter, TrackingHeaps

makedocs(
  modules = [TrackingHeaps],
  format = Documenter.HTML(
    prettyurls = get(ENV, "CI", nothing) == "true"
  ),
  checkdocs = :exports,
  sitename = "TrackingHeaps.jl",
  #pages = Any["index.md"],
  doctest = true
)

deploydocs(
  repo = "github.com/henriquebecker91/TrackingHeaps.jl.git",
)
