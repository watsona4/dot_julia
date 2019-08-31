@testset "classification" begin

    generate_caos_rules("data/S10593.nex", "data/output")
    tree, character_labels, taxa_labels = load_tree("data/output")

    @testset "classify_sequence" begin
        classification = classify_new_sequence(tree, character_labels, taxa_labels, "data/dna_seq.txt", "data/output")
        @test classification == "Tubificoides_amplivasatus_II_CE1247"
    end

    generate_caos_rules("data/E1E2L1.nex", "data/output2", protein=true)
    tree2, character_labels2, taxa_labels2 = load_tree("data/output2")

    @testset "classify_sequence" begin

        classification2 = classify_new_sequence(tree2, character_labels2, taxa_labels2, "data/protein_seq.txt", "data/output2", protein=true)

        @test classification2 == "HPV200"

        # @test classification == "Tubificoides_amplivasatus_II_CE1247"
    end
end
