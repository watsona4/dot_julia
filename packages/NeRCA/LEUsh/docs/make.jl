using Pkg
Pkg.activate(@__DIR__)

using NeRCA
using Literate
using Documenter


# const src_dir = "src"
# const docs_src_dir = "docs/src"
# const api_dir = "api"
#
# pages = Vector{Any}()
#
# # Generate API docs
# api_pages = []
# for file ∈ readdir(src_dir)
#     if file == "fit.jl"
#         continue
#     end
#     out_path = joinpath(docs_src_dir, api_dir)
#     Literate.markdown(joinpath(src_dir, file), out_path; documenter=false)
#     push!(api_pages, joinpath(api_dir, replace(file, ".jl" => ".md")))
# end
# push!(pages, "API" => api_pages)
# print(pages)
    

makedocs(modules=[NeRCA],
         # doctest=true,
         format = Documenter.HTML(prettyurls = get(ENV, "CI", nothing) == "true"),
         authors = "Tamas Gal",
         sitename = "NeRCA.jl",
         pages = []
         )
#=  =#
#= deploydocs(deps   = Deps.pip("mkdocs", "python-markdown-math"), =#
#=     repo = "github.com/tamasgal/NeRCA.jl.git", =#
#=     julia  = "0.7.0", =#
#=     osname = "linux") =#
#

# if get(ENV, "CI", nothing) == "true"
deploydocs(repo = "github.com/tamasgal/NeRCA.jl.git",
           target = "build")
# end
