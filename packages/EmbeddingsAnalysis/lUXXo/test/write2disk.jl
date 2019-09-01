function fake_wordvectors(type_element::Type{T}=Float32) where T<:AbstractFloat
    vocab = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"]
    vectors = diagm(0 => T[1.0, 2, 4, 5, 12, 1, 2, 1, 0, 10])
    vocab_hash = Dict(v => i for (i,v) in enumerate(vocab))
    return WordVectors(vocab, vectors, vocab_hash)
end

@testset "write2disk: WordVectors" begin
    filepath, io = mktemp()
    for T in [Float32, Float64]
        for kind in [:text, :binary]
            # create data
            wv_orig = fake_wordvectors(T)
            # dump data
            write2disk(filepath, wv_orig, kind=kind)
            # reload data
            wv_loaded = wordvectors(filepath, T, kind=kind, normalize=false)
            # tests
            @test eltype(wv_orig.vectors) == eltype(wv_loaded.vectors)
            @test wv_orig.vectors == wv_loaded.vectors
            @test wv_orig.vocab == wv_loaded.vocab
            @test wv_orig.vocab_hash == wv_loaded.vocab_hash
        end
    end
end


@testset "write2disk: CompressedWordVectors" begin
    filepath, io = mktemp()
    for T in [Float32, Float64]
        for kind in [:text, :binary]
            # create data
            wv_orig = fake_wordvectors(T)
            # compress data
            wv_compressed = compress(wv_orig, sampling_ratio=1.0,
                                     k=2, m=5, method=:pq)
            # write compressed data & reload
            write2disk(filepath, wv_compressed, kind=kind)
            wv_loaded = compressedwordvectors(filepath, T, kind=kind)
            # start tests
            @test wv_compressed.vocab == wv_loaded.vocab
            @test wv_compressed.vocab_hash == wv_loaded.vocab_hash
            @test typeof(wv_compressed) == typeof(wv_loaded)
            @test all(wv_compressed.vectors.data .==
                      wv_loaded.vectors.data)
            @test wv_compressed.vectors.quantizer.rot ==
                wv_loaded.vectors.quantizer.rot
        end
    end
end
