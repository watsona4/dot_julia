push!(LOAD_PATH, "../src/")
using Documenter, Markovify, Tokenizer

makedocs(
    sitename="Markovify.jl",
    assets=["assets/favicon.ico"],
    authors = "Evžen Wybitul",
    pages = [
        "Domovská stránka" => "index.md",
        "Vysvětlení" => [
            "Princip" => "function.md",
            "Implementace" => "implementation.md"
        ],
        "Příklady" => [
            "Lorem ipsum" => "lipsum.md"
        ],
        "Knihovna" => [
            "Veřejné symboly (EN)" => "public.md",
            "Interní symboly (EN)" => "internals.md"
        ]
    ]
 )
