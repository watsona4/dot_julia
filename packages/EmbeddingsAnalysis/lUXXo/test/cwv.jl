@testset "CompressedWordVectors" begin
    n = 50
    D = 20
    k = 2
    m = 5
    vocab = [randstring(10) for _ in 1:n]
    vectors = rand(D, n)
    distance = Distances.SqEuclidean()
    wv = WordVectors(vocab, vectors)

    compressed_type = CompressedWordVectors{QuantizedArrays.OrthogonalQuantization,
                        UInt8, Distances.SqEuclidean, Float64, String, Int}
    cwv = compress(wv, sampling_ratio = 0.5, k=k, m=m,
                   method=:pq, distance=distance)

    @test cwv isa compressed_type
    @test EmbeddingsAnalysis.vocabulary(cwv) == cwv.vocab
    @test EmbeddingsAnalysis.in_vocabulary(cwv, vocab[1])
    @test EmbeddingsAnalysis.size(cwv) == size(cwv.vectors)
    idx = rand(1:n); word = vocab[idx]
    @test EmbeddingsAnalysis.index(cwv, word) == cwv.vocab_hash[word]
    @test EmbeddingsAnalysis.get_vector(cwv, word) == cwv.vectors[:, idx]
    @test EmbeddingsAnalysis.similarity(cwv, word, word) ==
            cwv.vectors[:,idx]' * cwv.vectors[:,idx]

    n=3
    csw = EmbeddingsAnalysis.cosine_similar_words(cwv, vocab[1], n)
    @test csw isa Vector{String}
    @test length(csw) == n
    aw = EmbeddingsAnalysis.analogy_words(cwv, [vocab[1]], [], n)
    @test aw isa Vector{String}
    @test length(aw) == n

end
