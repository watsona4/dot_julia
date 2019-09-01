@testset "Similarity order" begin
    wv = fake_wordvectors()
    wv_so = similarity_order(wv)
    @test wv isa typeof(wv)
end
