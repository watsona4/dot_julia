using Documenter, DocStringExtensions
using Beauty

makedocs(
    sitename="quantum-factory.de",
    format = Documenter.HTML(prettyurls = false),
    modules = [Beauty]
)
