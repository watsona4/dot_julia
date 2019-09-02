using LaplaceBIE
using Documenter
using Literate

# try 
#     using AbstractPlotting, GLMakie  
#     @info "Animation with Makie is being made..."
#     let 
#         cd(joinpath(@__DIR__,"src"))
#         include(joinpath(@__DIR__,"../examples/mdrop.jl"))
#     end
# catch end

function dropexecution(content)
    content = replace(content, "```@example" => "```julia")
    return content
end

Literate.markdown(joinpath(@__DIR__, "../examples/homogenous.jl"), joinpath(@__DIR__,"src/"); credit = false, name = "homogenous") #, preprocess = replace_includes)

Literate.markdown(joinpath(@__DIR__, "../examples/pointlike.jl"), joinpath(@__DIR__,"src/"); credit = false, name = "pointlike")

Literate.markdown(joinpath(@__DIR__, "../examples/mdrop.jl"), joinpath(@__DIR__,"src/"); credit = false, name = "mdrop", postprocess = dropexecution)

Literate.script(joinpath(@__DIR__, "../examples/sphere.jl"), joinpath(@__DIR__,"src/"); credit = false, name = "sphere")

makedocs(sitename="LaplaceBIE.jl",pages = ["index.md","homogenous.md","pointlike.md","mdrop.md"])

deploydocs(
    repo = "github.com/akels/LaplaceBIE.jl.git",
)
