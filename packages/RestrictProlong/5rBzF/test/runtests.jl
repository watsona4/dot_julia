using RestrictProlong, Test

@testset "restrict" begin
    oddset =  (([1,0,0,0,0], [0.5,0,0]),
               ([0,1,0,0,0], [0.25,0.25,0]),
               ([0,0,1,0,0], [0,0.5,0]),
               ([0,0,0,1,0], [0,0.25,0.25]),
               ([0,0,0,0,1], [0,0,0.5]))
    evenset = (([1,0,0,0,0,0], [0.5,0,0]),
               ([0,1,0,0,0,0], [3/8,1/8,0]),
               ([0,0,1,0,0,0], [1/8,3/8,0]),
               ([0,0,0,1,0,0], [0,3/8,1/8]),
               ([0,0,0,0,1,0], [0,1/8,3/8]),
               ([0,0,0,0,0,1], [0,0,0.5]))

    # 1D
    for (y, Y) in oddset
        @test restrict(y) ≈ Y
        @test restrict(y, 1) ≈ Y
        @test restrict(y, 2) == y
    end
    for (y, Y) in evenset
        @test restrict(y) ≈ Y
        @test restrict(y, 1) ≈ Y
        @test restrict(y, 2) == y
    end

    # 2D
    for yset in (oddset, evenset)
        for xset in (oddset, evenset)
            for (y, Y) in yset
                for (x, X) in xset
                    @test restrict(x.*y') ≈ X.*Y'
                    @test restrict(x.*y', 1) ≈ X.*y'
                    @test restrict(x.*y', 2) ≈ x.*Y'
                    @test restrict(x.*y', [1,3]) ≈ X.*y'
                    @test restrict(x.*y', ()) == x.*y'
                end
            end
        end
    end
end

@testset "prolong" begin
    oddset =  (([1,0,0], [0.5,0.25,0,0,0]),
               ([0,1,0], [0,0.25,0.5,0.25,0]),
               ([0,0,1], [0,0,0,0.25,0.5]))
    evenset = (([1,0,0], [1/2,3/8,1/8,0,0,0]),
               ([0,1,0], [0,1/8,3/8,3/8,1/8,0]),
               ([0,0,1], [0,0,0,1/8,3/8,1/2]))

    # 1D
    for (Y, y) in oddset
        @test prolong(Y) ≈ y
        @test prolong(Y, length(y)) ≈ y
        @test prolong(Y, length(y), 1) ≈ y
        @test prolong(Y, 1, 2) == Y
    end
    for (Y, y) in evenset
        @test prolong(Y, length(y)) ≈ y
        @test prolong(Y, length(y), 1) ≈ y
        @test prolong(Y, 1, 2) == Y
    end

    # 2D
    for yset in (oddset, evenset)
        for xset in (oddset, evenset)
            for (Y, y) in yset
                for (X, x) in xset
                    @test prolong(X.*Y', (length(x),length(y))) ≈ x.*y'
                    @test prolong(X.*Y', length(x), 1) ≈ x.*Y'
                    @test prolong(X.*Y', length(y), 2) ≈ X.*y'
                end
            end
        end
    end
end

nothing
