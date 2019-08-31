@testset "user_functions" begin

    @testset "generate_caos_rules" begin
        tree, character_labels, taxa_labels = generate_caos_rules("data/S10593.nex", "data/output")
        @test typeof(tree) == CAOS.Node
    end

    @testset "load_tree" begin
        tree, character_labels, taxa_labels = load_tree("data/output")
        @test typeof(tree) == CAOS.Node
    end

    @testset "classify_new_sequence" begin
        tree, character_labels, taxa_labels = load_tree("data/output")
        classification = classify_new_sequence(tree, character_labels, taxa_labels, "data/dna_seq.txt", "data/output")
        @test typeof(classification) == String
    end

end
