using LargeMovieReviewDataset, Test

@testset "LargeMovieReviewDataset.jl" begin
    all_reviews = review_files()
    @test length(all_reviews) == 100_000

    unlabeled_reviews = review_files(labels=["unsup"])
    @test length(unlabeled_reviews) == 50_000
    @test all(ismissing ∘ review_rating, unlabeled_reviews)

    labeled_reviews = review_files(labels=["pos","neg"])
    @test length(labeled_reviews) == 50_000
    @test all([1 <= review_rating(review) <= 10 for review in labeled_reviews])

    train, test = trainfiles(), testfiles()
    @test length(train) == length(test) == 25_000
    @test all(r -> 1 <= review_rating(r) <= 10, train)
    @test all(r -> 1 <= review_rating(r) <= 10, test)

    isnum = x -> typeof(x) <: Number
    for reviews in (all_reviews, trainfiles(), testfiles(), unlabeled_reviews, labeled_reviews)
        @test all(isfile, reviews)
        @test all(isnum ∘ review_id, reviews)
    end
    @test isfile(LargeMovieReviewDataset.readme())
end
