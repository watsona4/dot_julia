prodir = realpath(joinpath(dirname(dirname(@__FILE__))))
srcdir = joinpath(prodir, "src")
srcdir ∉ LOAD_PATH && push!(LOAD_PATH, srcdir)

using Documenter, IntegerSequences

makedocs(
   modules = [IntegerSequences],
   clean = true,
   doctest = false,
   format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
   sitename = "IntegerSequences",
   pages = [
      "About" => "about.md",
      "Sequences" => "index.md",
      "Modules" => "modules.md",
      "Notebooks and demos" => "notebooks.md",
      "User guide" => "userguide.md",
      "Developer guide" => "developerguide.md",
      "Use of the OEIS" => "useofoeis.md",
      "License" => "license.md",
   ]
)

deploydocs(
    repo = "github.com/OpenLibMathSeq/IntegerSequences.jl.git"
)
