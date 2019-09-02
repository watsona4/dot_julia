# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/HeatTransfer.jl/blob/master/LICENSE

using Documenter, HeatTransfer, Literate

# automatically generate documentation from tests
using Pkg
pkg_dir = abspath(joinpath(dirname(pathof(HeatTransfer)), ".."))
testdir = joinpath(pkg_dir, "test")
outdir = joinpath(pkg_dir, "docs", "src", "tests")
test_pages = []
for test_file in readdir(testdir)
    startswith(test_file, "test_") || continue
    Literate.markdown(joinpath(testdir, test_file), outdir; documenter=true)
    generated_test_file = joinpath("tests", first(splitext(test_file)) * ".md")
    push!(test_pages, generated_test_file)
end

makedocs(modules=[HeatTransfer],
         format = :html,
         checkdocs = :all,
         sitename = "HeatTransfer.jl",
         pages = [
                  "index.md",
                  "Examples" => test_pages
                 ]
        )
