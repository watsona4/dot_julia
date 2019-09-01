@testset "TransMatrix" begin
    using LinearAlgebra

    a = [π/4, π/6, π/8]
    b = zeros(Float64,3)
    la_tmp1 = zeros(Float64,6,6)
    la_tmp2 = zeros(Float64,6,6)
    @test TransMatrix([a;b],la_tmp1,la_tmp2) ≈ TransMatrix([[0., 0., a[3]];b],la_tmp1,la_tmp2)*
                               TransMatrix([[0., a[2], 0.];b],la_tmp1,la_tmp2)*
                               TransMatrix([[a[1], 0., 0.];b],la_tmp1,la_tmp2)
    c = TransMatrix([0., 0., 0., 1., 2., 3.],la_tmp1,la_tmp2)
    @test diag(c) == ones(Float64,6)
    d = TransMatrix([π/4, π/6, π/8, 1., 2., 3.],la_tmp1,la_tmp2)
    @test !any(d[1:3,4:6] .!= 0.0)
end

@testset "Mfcross" begin
    a = rand(Float64,6)
    b = rand(Float64,6)
    @test Mfcross(a, b) ≈ [cross(a[1:3], b[1:3]) + cross(a[4:6], b[4:6]);
                           cross(a[1:3], b[4:6])]
end
