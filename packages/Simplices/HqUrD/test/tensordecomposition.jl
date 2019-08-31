@testset "Tensor decomposition" begin
    @testset "k = $k" for k in 1:7
        @testset "p = $p" for p in 1:7
            # Check that inverse of decomposition yields the original sequence
            # of integers.
            decomp = tensordecomp(k, p)
            original_sequence = collect(0:(k^p - 1))
            @test all(decomp * k .^ collect(0:p-1) .== original_sequence)
        end
    end
end
