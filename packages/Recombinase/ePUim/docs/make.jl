using Documenter, Literate, Recombinase

@info "makedocs"

for filename in ["tutorial.jl", "digging_deeper.jl"]
    Literate.markdown(
        joinpath(@__DIR__, "src", filename),
        joinpath(@__DIR__, "src", "generated")
    )
end

makedocs(
   format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
   sitename = "Recombinase.jl",
   pages = [
        "index.md",
        "generated/tutorial.md",
        "interactive_interface.md",
        "generated/digging_deeper.md",
   ]
)

@info "deploydocs"
deploydocs(
    repo = "github.com/piever/Recombinase.jl.git",
)
