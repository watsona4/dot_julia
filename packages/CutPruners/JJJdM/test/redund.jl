@testset "Redundancy removal" begin
    A = [9.69462e-5 9.69462e-5 9.69462e-5 9.69462e-5 0.0 0.0 0.0 0.0]
    B = [8.95335e-5 8.95335e-5 8.95335e-5 8.95335e-5 0.0 0.0 0.0 0.0]
    a = [1.]
    @test CutPruners.checkredundancy(A, a, B, a, true, true, 1e-5) == [1]
    @test CutPruners.checkredundancy(A, a, B, a, true, false, 1e-5) == [1]
    @test CutPruners.checkredundancy(A, a, B, a, true, true, 1e-6) == Int[]
    @test CutPruners.checkredundancy(A, a, B, a, true, false, 1e-6) == Int[]
    # A and B will be renormalized so A would be very close to B and even 1e-16 works
    @test CutPruners.checkredundancy(A, a, B, a, false, true, 1e-16) == Int[]
    @test CutPruners.checkredundancy(A, a, B, a, false, false, 1e-16) == [1]
end
@testset "Self redundancy" begin
    A = [9.69462e-5 9.69462e-5;
         8.95335e-5 8.95335e-5;
         0.0 0.0; 0.0 0.0]
    a = ones(Float64, 4)
    @test CutPruners.checkredundancy(A, a, true, true, 1e-5) == [2, 4]
    @test CutPruners.checkredundancy(A, a, true, false, 1e-5) == [2, 4]
    @test CutPruners.checkredundancy(A, a, true, true, 1e-6) == Int[4]
    @test CutPruners.checkredundancy(A, a, true, false, 1e-6) == Int[4]
    # A and B will be renormalized so A would be very close to B and even 1e-16 works
    @test CutPruners.checkredundancy(A, a, false, true, 1e-16) == Int[4]
    @test CutPruners.checkredundancy(A, a, false, false, 1e-6) == [2, 4]
end
