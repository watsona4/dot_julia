using Documenter, RainFARM

push!(LOAD_PATH,"../src/")
makedocs(sitename="RainFARM documentation")

deploydocs(
    repo = "github.com/jhardenberg/RainFARM.jl.git",
)
