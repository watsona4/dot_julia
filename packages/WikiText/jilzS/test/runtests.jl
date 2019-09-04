using WikiText, Test

@testset "WikiText" begin
    for wikitext in [WikiText2, WikiText103, WikiText2Raw, WikiText103Raw]
        for corpus in [wikitext, wikitext()]
            @test isfile(trainfile(corpus))
            @test isfile(validfile(corpus))
            @test isfile(testfile(corpus))
        end
    end
end
