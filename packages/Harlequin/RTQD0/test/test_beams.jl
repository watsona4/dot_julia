@test std2fwhm(1.0) ≈ 2.354820045
@test fwhm2std(1.0) ≈ 0.424660900

beam_map1 = gaussian_beam(128, 5.0 |> fwhm2std, normalization = 1.0)
beam_map2 = gaussian_beam(128, 5.0 |> fwhm2std, normalization = 2.0)

for pixidx in 1:beam_map1.resolution.numOfPixels
    @test beam_map1[pixidx] >= 0
    @test beam_map2[pixidx] >= 0
    @test 2 * beam_map1[pixidx] ≈ beam_map2[pixidx]
end
