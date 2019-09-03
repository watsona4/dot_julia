using Documenter
using ScanImageTiffReader

push!(LOAD_PATH, "../src")

makedocs(
    modules = [ScanImageTiffReader],
    doctest = true,
    format = :html,
    sitename = "ScanImage Tiff Reader",
    pages = [
        "index.md"
    ]
)
