using BDF, Lexicon
include("extract_docstrings.jl")
#Lexicon.save("../docs/API.md", BDF)
extract_docstrings(["../src/BDF.jl"], "../docs/API.md")
cd("../")
run(`mkdocs build`)
cd("prep-release")
