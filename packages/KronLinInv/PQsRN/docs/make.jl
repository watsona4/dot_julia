

using Documenter, KronLinInv 

makedocs(modules = [KronLinInv],
         #repo = "../../{path}",
         sitename="KronLinInv.jl",
         authors = "Andrea Zunino",
         format = Documenter.HTML(prettyurls=get(ENV,"CI",nothing)=="true"),
         pages = [
             "Home" => "index.md",
             "API" => "publicapi.md"
         ]
         )

deploydocs(
    repo = "github.com/inverseproblem/KronLinInv.jl.git",
)
