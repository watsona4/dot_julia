@testset "PCA reduction" begin
    wv = fake_wordvectors()
	for d in [1, 10]
		for outdim in [1, 10]
            for do_pca in [false, true]
                wv_pca = pca_reduction(wv, d, outdim, do_pca=do_pca)
                @test wv isa typeof(wv)
            end
		end
	end
end
