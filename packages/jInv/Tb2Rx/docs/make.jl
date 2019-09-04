using Documenter
using jInv.Mesh
using jInv.Utils
using jInv.ForwardShare
using jInv.LinearSolvers
using jInv.InverseSolve

makedocs()

deploydocs(
    deps   = Deps.pip("mkdocs", "python-markdown-math"),
    repo = "github.com/JuliaInv/jInv.jl.git",
    julia  = "0.5"
)
