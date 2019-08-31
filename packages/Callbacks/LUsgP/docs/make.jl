using Documenter
using Callbacks

makedocs(
    sitename = "Callbacks",
    format = Documenter.HTML(),
    modules = [Callbacks],
    pages = ["Home" => "index.md",
             "Library" => "library.md",
             "Compose" => "cbnode.md"]
)


deploydocs(
  repo = "github.com/zenna/Callbacks.jl.git",
)
