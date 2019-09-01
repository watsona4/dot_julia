using Test, DotTestSets

# Just exercising normal behavior

@testset DotTestSet begin
    @testset DotTestSet for i = 1:10
        for j = 1:10
            @test 1 + 1 == 2
        end
    end
end
