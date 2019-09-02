using Documenter, NLIDatasets

makedocs(sitename = "NLIDatasets.jl",
         format = Documenter.HTML(),
         modules = [NLIDatasets],
         pages = ["Home" => "index.md"],
         doctest = true)

deploydocs(repo = "github.com/dellison/NLIDatasets.jl.git")
