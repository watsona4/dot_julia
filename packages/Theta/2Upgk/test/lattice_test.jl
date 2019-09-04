import Theta: Lattice, svp, check_size_reduce, size_reduce!, check_lll, lll!

@testset "SVP correctness" begin
# Test data are generated using fplll
    @test norm(svp([116 303;331 963])[1]) == norm([-45, -30])
    @test norm(svp([116 456 99 566; 331 225 649 213; 303 827 395 694; 963 381 975 254])[1]) == norm([110 -12 -133 -127])
    @test norm(svp([116 827 566 597 912 611; 331 381 213 980 451 734; 303 99 694 462 926 668; 963 649 254 533 105 308; 456 395 629 231 162 101; 225 975 303 443 742 863])[1]) == norm([-301 283 -258 203 -61 121])
    @test norm(svp([116 99 629 912 668 438 621 371; 331 649 303 451 308 456 215 554; 303 395 597 926 101 887 6 434; 963 975 980 105 863 466 340 638; 456 566 462 162 279 634 142 939; 225 213 533 742 976 748 411 554; 827 694 231 611 127 307 250 840; 381 254 443 734 549 1002 873 633])[1]) == norm([-17 318 92 12 110 -12 -133 -127])
end


@testset "SVP length" begin
    @test begin
        S = svp(rand(1,1));
        (norm(S[1]))^2 ≈ S[2]
    end
    @test begin
        S = svp(rand(2,2));
        norm(S[1])^2 ≈ S[2]
    end
    @test begin
        S = svp(rand(5,5));
        norm(S[1])^2 ≈ S[2]
    end
    @test begin
        S = svp(rand(4,3));
        norm(S[1])^2 ≈ S[2]
    end    
end

@testset "Size reduction" begin
    @test check_size_reduce(size_reduce!(Lattice(rand(1,1))))
    @test check_size_reduce(size_reduce!(Lattice(rand(2,2))))
    @test check_size_reduce(size_reduce!(Lattice(rand(3,3))))
    @test check_size_reduce(size_reduce!(Lattice(rand(4,4))))
    @test check_size_reduce(size_reduce!(Lattice(rand(5,5))))
    @test check_size_reduce(size_reduce!(Lattice(rand(10,10))))
end

@testset "LLL" begin
    @test check_lll(lll!(Lattice(rand(1,1))))
    @test check_lll(lll!(Lattice(rand(2,2))))
    @test check_lll(lll!(Lattice(rand(3,3))))
    @test check_lll(lll!(Lattice(rand(4,4))))
    @test check_lll(lll!(Lattice(rand(5,5))))
    @test check_lll(lll!(Lattice(rand(10,10))))
end






