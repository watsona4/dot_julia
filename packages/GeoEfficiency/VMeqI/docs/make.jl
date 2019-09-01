#**************************************************************************************
# make.jl
# =============== part of the GeoEfficiency.jl package.
#
# script for building documentation of the GeoEfficiency.jl package.
#
#  _args = ["clean", "pdf", "doctest"]
#  include(raw"C:\Users\Mohamed\.julia\dev\GeoEfficiency\docs\make.jl")
#**************************************************************************************

using  Documenter, DocumenterLaTeX #, DocumenterMarkdown
using GeoEfficiency

_args = @isdefined(_args) ? _args : ARGS
const PAGES = Any[
    "Home" => "index.md",
    "Manual" => [
		"manual/GeoEfficiency.md",
        #"manual/Error.md",
        #"manual/Input_Console.md",
        "manual/Physics_Model.md",
        "manual/Calculations.md",
        "manual/Output_Interface.md",
        "manual/Input_Batch.md",
     ],
    
    "Development" => "manual/Development.md",
    "Index" => "list.md",
]

const formats = Any[
    Documenter.HTML(
        prettyurls = false,  #get(ENV, "CI", nothing) == "true",
        canonical = "https://github.com/DrKrar/GeoEfficiency.jl/v0.9.3/",
        
    ), 
    
]

isdefined(@__MODULE__,:DocumenterMarkdown) &&  push!(formats, Markdown())

if "pdf" in _args
    Sys.iswindows() ?   push!(formats, LaTeX(platform = "native")) : 
                        push!(formats, LaTeX(platform = "docker"))
end

makedocs(
    format  = formats,
    modules = [GeoEfficiency],
    clean   = "clean" in _args,
    doctest = "doctest" in _args,
    sitename= "GeoEfficiency.jl",
    authors = "Mohamed E. Krar",
    pages   = PAGES,
    assets  = ["assets/custom.css"],
)


const REPO = "github.com/DrKrar/GeoEfficiency.jl.git" # "github.com/GeoEfficiency/GeoEfficiency.github.io.git" 
const VERSIONS =["stable" => "v^", "v#.#", "dev" => "dev"]  # order of versions in drop down menu.
const BRANCH = "gh-pages" # "master"

mktempdir() do tmp
    # Hide the PDF from html-deploydocs
    build = joinpath(@__DIR__, "build")
    files = readdir(build)
    idx = findfirst(f -> startswith(f, "GeoEfficiency.jl") && endswith(f, ".pdf"), files)
    pdf = idx === nothing ? nothing : joinpath(build, files[idx])
    if pdf !== nothing
        pdf = mv(pdf, joinpath(tmp, basename(pdf)))
    end
    # Deploy HTML pages
    @info "Deploying HTML pages"
    deploydocs(
        repo = REPO,
        branch = BRANCH, #"gh-pages"
        versions = VERSIONS,
    )
    if isdefined(@__MODULE__,:DocumenterMarkdown)
        # Deploy Markup pages
        @info "Deploying MarkUp pages"
        deploydocs(
            repo = REPO,
            branch = BRANCH, #"gh-pages",
            target = "build/Mrk",
            versions = VERSIONS,
        )
    end #if
    # Put back PDF into docs/build/pdf
    mkpath(joinpath(build, "pdf"))
    if pdf !== nothing
        pdf = mv(pdf, joinpath(build, "pdf", basename(pdf)))
    end
    # Deploy PDF
    @info "Deploying PDF"
    deploydocs(
        repo = REPO,
        target = "build/pdf",
        branch = BRANCH * "-pdf", #"gh-pages-pdf",
        forcepush = true,
    )
end
