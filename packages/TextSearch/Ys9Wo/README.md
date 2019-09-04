# TextSearch.jl

[![Build Status](https://travis-ci.org/sadit/TextSearch.jl.svg?branch=master)](https://travis-ci.org/sadit/TextSearch.jl)
[![Coverage Status](https://coveralls.io/repos/github/sadit/TextSearch.jl/badge.svg?branch=master)](https://coveralls.io/github/sadit/TextSearch.jl?branch=master)
[![codecov](https://codecov.io/gh/sadit/TextSearch.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/sadit/TextSearch.jl)


`TextSearch.jl` is a package to create vector representations of text, mostly, independently of the language. It is intended to be used with [SimilaritySearch.jl](https://github.com/sadit/SimilaritySearch.jl), but can be used independetly if needed.
`TextSearch.jl` was renamed from `TextModel.jl` to reflect its capabilities and mission.

For generic text analysis you should use other packages like [TextAnalysis.jl](https://github.com/johnmyleswhite/TextAnalysis.jl).

It supports a number of simple text preprocessing functions, and three different kinds of tokenizers, i.e., word n-grams, character q-grams, and skip-grams. It supports creating multisets of tokens, commonly named bag of words (BOW).
`TextSearch.jl` can produce sparse vector representations based on term-weighting schemes like TF, IDF, and TFIDF. It also supports term-weighting schemes designed to cope text classification tasks, mostly based on distributional representations.

# Installing SimilaritySearch

You may install the package as follows
```bash
julia -e 'using Pkg; pkg"add https://github.com/sadit/TextSearch.jl"'
```
also, you can run the set of tests as follows
```bash
julia -e 'using Pkg; pkg"test TextSearch"'
```

## Using the library
```julia
julia> using SimilaritySearch, TextSearch
julia> url = "http://ingeotec.mx/~sadit/emospace50k.json.gz"
julia> !isfile(basename(url)) && download(url, basename(url))
julia> db = loadtweets(basename(url))
# you can use a number of tokenizers, here we use character q-grams to improve support for informal writing
julia> config = TextConfig(qlist=[4], nlist=[])
julia> corpus = [t["text"] for t in db]
julia> model = fit(VectorModel, config, corpus)
julia> invindex = InvIndex()
julia> for (i, text) in enumerate(corpus)
        push!(invindex, i, vectorize(model, TfidfModel, text) |> normalize!)
    end
```

queries are made as follows
```julia
julia> q = vectorize(model, TfidfModel, "que chida musica!!!") |> normalize!
julia> db[[p.objID for p in search(invindex, q, KnnResult(11))]]
```

you can save memory by pruning large lists, as follows
```julia
julia> invindex = prune(invindex, 100)
julia> for p in search(invindex, vectorize(model, TfidfModel, "que chida musica!!!") |> normalize!, KnnResult(11))
    println(db[p.objID]["klass"], "\t", db[p.objID]["text"])
end
```
in some cases this can improve results since it keeps the most weighted items per list.

It is also simple to modify the bag of words to apply query expansion, downsampling, error correction, etc.
```julia
julia> function randomsample!(bow)
        Dict(rand(bow, div(length(bow), 2)))
    end
julia> for p in search(invindex, vectorize(model, TfidfModel, "que chida musica!!!", randomsample!) |> normalize!, KnnResult(11))
    println(db[p.objID]["klass"], "\t", db[p.objID]["text"])
end
😎	No me toquen ando chida! 😎 https://t.co/39OKexhGFT
🙏	Díganme películas chidas para ver 🙏🏼
😋	Me cae bien mi vecino por que siempre pone canciones chidas😋
😉	Esta si esta chida para ir a la alameda los domingos 😉 https://t.co/vRExWJhOGH
😐	Me va a quedar bien chida la falda ... 😐 https://t.co/YV3sfBAjqD
😒	De chiquito cantaba chido😒
🤓	Se ve que se va a poner muy chida la Jornada. 🤓
💙	¡Qué chido está Pachuca! 💙
😢	Siento que en MARCO una chava me tomó una foto chida y nunca la subieron 😢
😥	El problema de ponerle fin a las relaciones es que también te separas de personas bien chidas que valen la pena 😥
😜	#BuenMartes #gentechida a darle con todo que ya sólo falta un día después de pasado mañana para que llegue el viernes!! 😜
```


TextSearch can also be used with SimilaritySearch methods. The initial code is identical to that needed by the inverted index
```julia
julia> using SimilaritySearch, TextSearch
julia> url = "http://ingeotec.mx/~sadit/emospace50k.json.gz"
julia> !isfile(basename(url)) && download(url, basename(url))
julia> db = loadtweets(basename(url))
# you can use a number of tokenizers, here we use character q-grams to improve support for informal writing
julia> config = TextConfig(qlist=[4], nlist=[])
julia> corpus = [t["text"] for t in db]
julia> model = fit(VectorModel, config, corpus)
julia> db = [vectorize(model, TfidfModel, text) |> normalize! for text in corpus]
julia> invindex = fit(InvIndex, db)
```


now, the code to use SimilaritySearch methods along with a brief comparison with inverted indexes
```julia
julia> using SimilaritySearch.Graph, SimilaritySearch.SimilarReferences
julia> perf = Performance(db, cosine_distance)
julia> seq = fit(Sequential, db)
julia> knr = fit(Knr, cosine_distance, db, k=7, numrefs=1024)
julia> graph = fit(SearchGraph, cosine_distance, db)
julia> pruned1000 = prune(invindex, 1000)
julia> pruned300 = prune(invindex, 300)
julia> pruned100 = prune(invindex, 100)
julia> pruned30 = prune(invindex, 30)
julia> P = [
        probe(perf, seq, cosine_distance),
        probe(perf, knr, cosine_distance),
        probe(perf, graph, cosine_distance),
        probe(perf, invindex, cosine_distance),
        probe(perf, pruned1000, cosine_distance),
        probe(perf, pruned300, cosine_distance),
        probe(perf, pruned100, cosine_distance),
        probe(perf, pruned30, cosine_distance),
    ]
julia> M = Array{Any}(undef, 9, 5)
julia> M[1, :] .= ["index", "distances_sum", "evaluations_ratio", "queries_by_second", "recall"]
julia> for (i, p) in zip(
            ["seq", "knr", "graph", "invindex", "pruned1000", "pruned300", "pruned100", "pruned30"],
            [p.distances_sum/P[1].distances_sum for p in P],
            [p.evaluations/P[1].evaluations for p in P],
            [1/p.seconds for p in P],
            [p.recall for p in P]) |> enumerate
       M[i+1, :] .= p
       end

julia> M
9×5 Array{Any,2}:
 "index"        "distances_sum"   "evaluations_ratio"      "queries_by_second"   "recall"
 "seq"         1.0               1.0                      9.86785               1.0      
 "knr"         1.01337           0.0863964               80.5455                0.809028 
 "graph"       1.0091            0.0519419              162.02                  0.864583 
 "invindex"    1.0               0.0                     79.3421                0.998264 
 "pruned1000"  1.00196           0.0                    354.288                 0.942708 
 "pruned300"   1.00568           0.0                    703.035                 0.875    
 "pruned100"   1.01031           0.0                   1608.57                  0.762153 
 "pruned30"    1.01843           0.0                   5013.6                   0.625868
```

As you may see, prunning an inverted index improves the search speed significantly with
a small impact in the recall. The sum of distances is also barely impacted. The `SearchGraph` and
`Knr` indexes perform relatively good, but inverted indexes are much better; that is why we need specialized methods like those provided in `TextSearch.jl` package. In any case, the approximation ratio is small, as indicated by the `distances_sum` ratio. Notice that it is possible to have a good distance approximation factor with bad recall, in this sense, recall is a more strict score.
In particular, the scalability of the pruned inverted index is almost independent of the size of the dataset, being dependent mostly in the number of tokens in the query; of course, it is also dependent of the size of the pruned posting list.
