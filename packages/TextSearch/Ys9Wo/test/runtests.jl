# using Languages
using Test
using SimilaritySearch
using TextSearch
using LinearAlgebra
fit = TextSearch.fit

const text0 = "@user;) #jello.world"
const text1 = "hello world!! @user;) #jello.world :)"
const text2 = "a b c d e f g h i j k l m n o p q"
const corpus = ["hello world :)", "@user;) excellent!!", "#jello world."]

@testset "Character q-grams" begin
    config = TextConfig()
    config.del_usr = false
    config.nlist = []
    config.qlist = [3]
    config.skiplist = []
    a = [(p.first, p.second) for p in compute_bow(config, text0)[1]]
    b = [(:rld, 1), (Symbol("@us"), 1), (:orl, 1), (:wor, 1), (Symbol("lo."), 1), (:use, 1), (:ser, 1), (Symbol("o.w"), 1), (:llo, 1), (Symbol("r;)"), 1), (:jel, 1), (Symbol(" #j"), 1), (Symbol("er;"), 1), (Symbol("ld "), 1), (Symbol(";) "), 1), (Symbol(" @u"), 1), (:ell, 1), (Symbol(") #"), 1), (Symbol(".wo"), 1), (Symbol("#je"), 1)]
    @test sort(a) == sort(b)
end

@testset "Word n-grams" begin
    config = TextConfig()
    config.del_usr = false
    config.nlist = [1, 2]
    config.qlist = []
    config.skiplist = []
    a = [(p.first, p.second) for p in compute_bow(config, text0)[1]]
    b = [(Symbol("#jello"), 1), (Symbol("#jello ."), 1), (:., 1), (Symbol(". world"), 1), (Symbol(";)"), 1), (Symbol(";) #jello"), 1), (Symbol("@user"), 1), (Symbol("@user ;)"), 1), (:world, 1)]
    @test sort(a) == sort(b)
 end

@testset "Skip-grams" begin
    config = TextConfig()
    config.nlist = []
    config.qlist = []
    config.del_punc = true
    config.skiplist = [(2,1), (2, 2), (3, 1), (3, 2)]
    #L = collect(compute_bow(text2, config))
    #sort!(L)
    a = [(p.first, p.second) for p in compute_bow(config, text2)[1]]
    b = [(Symbol("a c"), 1), (Symbol("a c e"), 1), (Symbol("a d"), 1), (Symbol("a d g"), 1), (Symbol("b d"), 1), (Symbol("b d f"), 1), (Symbol("b e"), 1), (Symbol("b e h"), 1), (Symbol("c e"), 1), (Symbol("c e g"), 1), (Symbol("c f"), 1), (Symbol("c f i"), 1), (Symbol("d f"), 1), (Symbol("d f h"), 1), (Symbol("d g"), 1), (Symbol("d g j"), 1), (Symbol("e g"), 1), (Symbol("e g i"), 1), (Symbol("e h"), 1), (Symbol("e h k"), 1), (Symbol("f h"), 1), (Symbol("f h j"), 1), (Symbol("f i"), 1), (Symbol("f i l"), 1), (Symbol("g i"), 1), (Symbol("g i k"), 1), (Symbol("g j"), 1), (Symbol("g j m"), 1), (Symbol("h j"), 1), (Symbol("h j l"), 1), (Symbol("h k"), 1), (Symbol("h k n"), 1), (Symbol("i k"), 1), (Symbol("i k m"), 1), (Symbol("i l"), 1), (Symbol("i l o"), 1), (Symbol("j l"), 1), (Symbol("j l n"), 1), (Symbol("j m"), 1), (Symbol("j m p"), 1), (Symbol("k m"), 1), (Symbol("k m o"), 1), (Symbol("k n"), 1), (Symbol("k n q"), 1), (Symbol("l n"), 1), (Symbol("l n p"), 1), (Symbol("l o"), 1), (Symbol("m o"), 1), (Symbol("m o q"), 1), (Symbol("m p"), 1), (Symbol("n p"), 1), (Symbol("n q"), 1), (Symbol("o q"), 1)]
    @test sort(a) == sort(b)
end

@testset "Tokenizer, BOW, and vectorize" begin # test_vmodel
    config = TextConfig()
    config.nlist = [1]
    config.qlist = []
    config.skiplist = []
    config.del_usr = false

    @test tokenize(config, text1) == [Symbol(h) for h in ["hello", "world", "!!",  "@user", ";)", "#jello", ".", "world", ":)"]]
    model = fit(VectorModel, config, corpus)
    @test length(vectorize(model, TfModel, text1)) == 8
    @test length(vectorize(model, TfModel, text2)) == 0
end


const labeled_corpus = [("me gusta", 1), ("me encanta", 1), ("lo odio", 2), ("odio esto", 2), ("me encanta esto LOL!", 1)]
const sentiment_text = "lol, esto me encanta"

@testset "DistModel tests" begin
    config = TextConfig()
    config.nlist = [1]
    dmodel = fit(DistModel, config, [x[1] for x in labeled_corpus], [x[2] for x in labeled_corpus])
    @show sentiment_text
    @show dmodel
    #a = vectorize(dmodel, TfIdf, sentiment_text)
    #b = [(:me1,1.0),(:me2,0.0),(:encanta1,1.0),(:encanta2,0.0),(:esto1,0.4),(:esto2,0.6),(:lol1,1.0),(:lol2,0.0)]
    #@test string(a) == string(b)

end

@testset "DistModel-normalize! tests" begin
    config = TextConfig()
    config.nlist = [1]
    X = [x[1] for x in labeled_corpus]
    y = [x[2] for x in labeled_corpus]
    dmodel = fit(DistModel, config, X, y, norm_by=minimum)
    #dmap = id2token(dmodel)
    #@show sentiment_text
    #@show dmodel
    #d1 = [(dmap[t.id], t.weight) for t in vectorize(dmodel, sentiment_text).tokens]
    #d2 = [(:me1, 1.0), (:me2, 0.0), (:encanta1, 1.0), (:encanta2, 0.0), (:esto1, 0.4), (:esto2, 0.6), (:lol1, 1.0), (:lol2, 0.0)]
    #@test string(d1) == string(d2)
end

@testset "EntModel tests" begin
    config = TextConfig()
    config.nlist = [1]
    X = [x[1] for x in labeled_corpus]
    y = [x[2] for x in labeled_corpus]
    dmodel = fit(DistModel, config, X, y)
    emodel = fit(EntModel, dmodel)
    emodel_ = fit(EntModel, config, X, y)
    a = normalize!(vectorize(emodel, X))
    b = normalize!(vectorize(emodel_, X))
    @test 0.999 < dot(a, b)
 
    # a = [(emap[t.id], t.weight) for t in .tokens]
    # b = [(:esto,0.0290494),(:encanta,1.0),(:me,1.0),(:lol,1.0)]
    # sort!(a)
    # sort!(b)
    # @test string(a) == string(b)

    # @show [(maptoken[term.id], term.id, term.weight) for term in vectorize(sentiment_text, emodel).terms]
    # @show vectorize(text4, vmodel)
end
#@test
# @test TextConfig()


@testset "distances" begin
    u = Dict(:el => 0.9, :hola => 0.1, :mundo => 0.2) |> normalize!
    v = Dict(:el => 0.4, :hola => 0.2, :mundo => 0.4) |> normalize!
    w = Dict(:xel => 0.4, :xhola => 0.2, :xmundo => 0.4) |> normalize!

    dist = angle_distance
    @test dist(u, v) ≈ 0.5975474808029686
    @test dist(u, u) <= eps(Float32)
    @test dist(w, u) ≈ 1.5707963267948966
end

@testset "operations" begin
    u = Dict(:el => 0.1, :hola => 0.2, :mundo => 0.4)
    v = Dict(:el => 0.2, :hola => 0.4, :mundo => 0.8)
    w = Dict(:el => 0.1^2, :hola => 0.2^2, :mundo => 0.4^2)
    y = Dict(:el => 0.1/9, :hola => 0.2/9, :mundo => 0.4/9)
    @test u == u
    @test u != v
    @test u + u == v
    @test u * u == w
    @test u * (1/9) == y
    @test (1/9) * u == y
    @test dot(normalize!(u + v - v), normalize!(u)) > 0.99
end

@testset "io" begin
    buff = IOBuffer("""{"key1": "value1a", "key2c": "value2a"}
{"key1": "value1b", "key2c": "value2b"}
{"key1": "value1c", "key2b": "value2c"}
{"key1": "value1d", "key2a": "value2d"}""")
    itertweets(buff) do x
        @info x
    end
end

_corpus = [
    "la casa roja",
    "la casa verde",
    "la casa azul",
    "la manzana roja",
    "la pera verde esta rica",
    "la manzana verde esta rica",
    "la hoja verde",
]

@testset "transpose bow" begin
    config = TextConfig()
    config.nlist = [1]
    config.qlist = []
    config.skiplist = []
    model = fit(VectorModel, config, _corpus)
    @show _corpus
    X = [vectorize(model, FreqModel, x) |> normalize! for x in _corpus]
    dX = transpose(X)
end


@testset "invindex" begin
    config = TextConfig()
    config.qlist = [3, 4]
    config.nlist = [1, 2, 3]

    model = fit(VectorModel, config, _corpus)
    invindex = InvIndex()
    for c in _corpus
        push!(invindex, invindex.n + 1, vectorize(model, TfidfModel, c) |> normalize!)
    end

    q = vectorize(model, TfidfModel, "la casa roja") |> normalize!
    res = search(invindex, cosine_distance, q, KnnResult(4))
    ires = [r.objID for r in res]
    @show res, _corpus[ires]
    @test ires == [1, 2, 4, 3]
    shortindex = prune(invindex, 3)
    res = search(shortindex, cosine_distance, q, KnnResult(4))
    ires = [r.objID for r in res]
    @show res, _corpus[ires]
    @test sort(ires) == [1, 2, 3, 4]
end

@testset "centroid computing" begin
    config = TextConfig()
    config.nlist = [1]
    config.qlist = []
    config.skiplist = []
    model = fit(VectorModel, config, _corpus)
    @show _corpus
    X = [vectorize(model, FreqModel, x) |> normalize! for x in _corpus]
    x = sum(X) |> normalize!
    @test 0.999 < dot(x, Dict(:la=>0.736665,:verde=>0.39922,:azul=>0.112482,:pera=>0.087128,:esta=>0.174256,:roja=>0.224964,:hoja=>0.112482,:casa=>0.337445,:rica=>0.174256,:manzana=>0.19961))
end


@testset "rocchio" begin
    config = TextConfig()
    config.nlist = [1,2]
    config.qlist = [3]
    config.skiplist = []
    corpus = [x[1] for x in labeled_corpus]

    model = fit(VectorModel, config, corpus)
    X = [vectorize(model, TfidfModel, x) |> normalize! for x in corpus]
    y = [x[2] for x in labeled_corpus]
    rocchio = fit(Rocchio, X, y)
    @show rocchio.protos rocchio.pops
    @test sum(predict.(rocchio, X) .== y)/length(y) == 1.0

    for p in transform.(rocchio, X)
        println(p)
    end
end


@testset "rocchio bagging" begin
    config = TextConfig()
    config.nlist = [1, 2]
    config.qlist = [3]
    config.skiplist = []
    corpus = [x[1] for x in labeled_corpus]
    model = fit(VectorModel, config, corpus)
    X = [vectorize(model, TfidfModel, x) |> normalize! for x in corpus]
    y = [x[2] for x in labeled_corpus]
    rocchio = fit(RocchioBagging, X, y)
    for p in transform.(rocchio, X)
        println("===>", p)
    end

    #@show rocchio.protos rocchio.pops
    @show predict.(rocchio, X)
    @show y
end


@testset "neardup" begin
    config = TextConfig()
    config.nlist = [1]
    config.qlist = []
    config.skiplist = []

    function create_corpus()
        alphabet = Char.(97:100)
        corpus = String[]
        L = Char[]
        for i in 1:10000
            resize!(L, 0)
            for j in 1:7
                append!(L, rand(alphabet, 2))
                push!(L, ' ')
            end

            push!(corpus, join(L))
        end

        corpus
    end

    corpus = create_corpus()
    model = fit(VectorModel, config, corpus)
    @show corpus[1:10]
    X = [vectorize(model, TfModel, x) |> normalize! for x in corpus]
    L, D  = neardup(X, 0.2)
    @test length(X) > length(unique(L))
end
