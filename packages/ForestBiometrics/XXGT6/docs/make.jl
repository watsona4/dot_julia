using Documenter
using ForestBiometrics

makedocs(
        modules =[ForestBiometrics],
        sitename= "ForestBiometrics.jl",
        format = :html,
        authors="Casey Ghilardi",
        doctest=false,
        clean=true,
        pages = Any[
        "Home" => "index.md",
        "Functionality" =>Any["functionality/height_diameter.md",
        "functionality/density.md",
        "functionality/other_functions.md"],
        "Volume Equations" => Any["volume_equations/volume_eqs.md"],
        "Visualizations" =>Any["visualizations/visualizations.md"],
        "Included Datasets"=>Any["data/data.md"]
        ])

 deploydocs(
            deps = nothing,
            branch = "gh-pages",
            latest = "master",
            julia ="1.0",
            repo = "github.com/Crghilardi/ForestBiometrics.jl.git",
            target = "build",
            osname ="linux",
            make = nothing
   )
