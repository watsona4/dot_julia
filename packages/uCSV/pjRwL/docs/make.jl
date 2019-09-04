using Documenter, uCSV, Pkg

makedocs(
    root = joinpath(dirname(dirname(pathof(uCSV))), "docs"),
    source = "src",
    build = "build",
    doctest = true,
    modules = [uCSV],
    format   = Documenter.HTML(prettyurls = false),
    sitename = "uCSV.jl",
    checkdocs = :all,
    debug = true,
    pages = Any["Home" => "index.md",
                "Manual" => Any["man/defaults.md",
                                "man/headers.md",
                                "man/dataframes.md",
                                "man/delimiters.md",
                                "man/missingdata.md",
                                "man/declaring-column-element-types.md",
                                "man/declaring-column-vector-types.md",
                                "man/international.md",
                                "man/customparsers.md",
                                "man/quotes-escapes.md",
                                "man/comments-skiplines.md",
                                "man/malformed.md",
                                "man/url.md",
                                "man/compressed.md",
                                "man/unsupported.md",
                                "man/write.md",
                                "man/benchmarks.md"]])

deploydocs(
    repo = "github.com/cjprybol/uCSV.jl.git",
    target = "build",
    deps = nothing,
    make = nothing)
