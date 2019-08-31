using Documenter

if ispath("buld/")
    rm("build/", recursive=true)
end

if ispath("site/")
    rm("site/", recursive=true)
end

include("runWeave.jl") #convert weave file to markdown
makedocs()
run(`mkdocs build`)
