using Documenter, CryptoUtils

makedocs(modules = [CryptoUtils],
        sitename = "CryptoUtils.jl",
        pages = Any[
                "Home" => "index.md",
                "Functions" => "api.md"
        ])

deploydocs(repo = "github.com/fcasal/CryptoUtils.jl.git",
)

