push!(LOAD_PATH,"../src/")

using Documenter, LabelNumerals

makedocs(
    format = :html,
    sitename = "LabelNumerals",
    pages = [
        "index.md"
    ]
)
