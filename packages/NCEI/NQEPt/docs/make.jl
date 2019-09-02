using Documenter, NCEI

makedocs(modules = [NCEI],
         sitename = "NCEI.jl",
         pages = ["index.md",
                  "GettingStarted.md",
                  "Walkthrough.md"
                  ])
deploydocs(repo = "github.com/Nosferican/NCEI.jl.git")
