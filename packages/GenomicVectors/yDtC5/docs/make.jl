using Documenter, GenomicVectors

makedocs(
         modules = [GenomicVectors]
         )

deploydocs(
           repo = "github.com/phaverty/GenomicVectors.jl.git",
           julia = "release"
           )
