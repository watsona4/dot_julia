using Documenter, DependenciesParser

makedocs(modules = [DependenciesParser], sitename = "DependenciesParser.jl")
deploydocs(repo = "github.com/Nosferican/DependenciesParser.jl.git")
