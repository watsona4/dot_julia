using NLIDatasets, Test

@testset "NLIDatasets.jl" begin

    @testset "SNLI" begin
        using NLIDatasets: SNLI
        @test isfile(SNLI.train_tsv())
        @test isfile(SNLI.train_jsonl())
        @test isfile(SNLI.dev_tsv())
        @test isfile(SNLI.dev_jsonl())
        @test isfile(SNLI.test_tsv())
        @test isfile(SNLI.test_jsonl())
    end

    @testset "MultiNLI" begin
        using NLIDatasets: MultiNLI
        @test isfile(MultiNLI.train_tsv())
        @test isfile(MultiNLI.train_jsonl())
        @test isfile(MultiNLI.dev_matched_tsv())
        @test isfile(MultiNLI.dev_matched_jsonl())
        @test isfile(MultiNLI.dev_mismatched_tsv())
        @test isfile(MultiNLI.dev_mismatched_jsonl())
    end

    @testset "XNLI" begin
        using NLIDatasets: XNLI
        @test isfile(XNLI.dev_tsv())
        @test isfile(XNLI.dev_jsonl())
        @test isfile(XNLI.test_tsv())
        @test isfile(XNLI.test_jsonl())
    end

    @testset "SciTail" begin
        using NLIDatasets: SciTail
        @test isfile(SciTail.train_tsv())
        @test isfile(SciTail.train_jsonl())
        @test isfile(SciTail.dev_tsv())
        @test isfile(SciTail.dev_jsonl())
        @test isfile(SciTail.test_tsv())
        @test isfile(SciTail.test_jsonl())
    end

    @testset "HANS" begin
        using NLIDatasets: HANS
        @test isfile(HANS.test_tsv())
    end

    @testset "Breaking_NLI" begin
        using NLIDatasets: BreakingNLI
        @test isfile(BreakingNLI.test_jsonl())
    end
end
