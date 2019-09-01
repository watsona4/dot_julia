using DetectionTheory, Lexicon
include("extract_docstrings.jl")

#Lexicon.save("docs/API.md", DetectionTheory)
extract_docstrings(["../src/DetectionTheory.jl"], "../docs/API.md")
cd("../")
run(`mkdocs build`)
cd("prep-release")
