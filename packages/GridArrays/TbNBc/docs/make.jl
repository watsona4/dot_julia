using Pkg
Pkg.develop(PackageSpec(path=splitdir(@__DIR__)[1]))
pkg"instantiate"
using Documenter, GridArrays

const format = Documenter.HTML(
        prettyurls = ("deploy" in ARGS),
    )

makedocs(sitename="GridArrays.jl",
    modules = [GridArrays],
    format = format,
    pages = [
        "Home" => "index.md",
        "Manual" => "man/GridArrays.md"
        ],
    doctest=true
)

if "deploy" in ARGS && Sys.ARCH === :x86_64 && Sys.KERNEL === :Linux
    deploydocs(
        repo = "github.com/JuliaApproximation/GridArrays.jl.git",
    )
end
