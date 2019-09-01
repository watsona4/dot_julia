const FAKE_CONCEPTNET = """
5 5
/c/en/this 1 2 3 4 5
/c/en/is -1 -2 -3 -4 -5
/c/en/# 1 1 1 1 1
/c/fr/etre 6 7 8 9 10
/c/fr/# 2 2 2 2 2
"""
@testset "Conceptnet-2-WordVectors" begin
    filepath, io = mktemp()
    write(io, FAKE_CONCEPTNET)
    close(io)
    cptnet = load_embeddings(filepath)
    for lang in keys(cptnet.embeddings)
        wv = conceptnet2wv(cptnet, lang)
        _, _, data_type = typeof(cptnet).parameters
        @test wv isa WordVectors{String, data_type, Int}
        @test length(wv.vocab) == length(cptnet.embeddings[lang])
        @test size(wv.vectors, 1) == cptnet.width
        for word in keys(cptnet.embeddings[lang])
            @test cptnet[lang, word] == get_vector(wv, word)
        end
    end
end

