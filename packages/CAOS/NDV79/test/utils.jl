@testset "utils" begin
    tree, character_labels, taxa_labels = load_tree("data/output")

    @testset "remove_blanks" begin
        d = Dict("a" => "-", "b" => "2")
        d1 = remove_blanks(d)
        d2 = remove_blanks(d, change_to_N=true)
        @test d1["a"] == ""
        @test d2["a"] == "N"
    end

    @testset "get_max_depth" begin
        tree, character_labels, taxa_labels = generate_caos_rules("data/S10593.nex", "data/output")
        tree_out = load_tree("data/output")
        @test length(tree_out[1].children) == 2
        @test get_max_depth(tree_out[1], 10) == 33
        @test typeof(tree_out[1]) == CAOS.Node
    end

    @testset "find_sequence" begin
        result = find_sequence(tree, "Tubificoides_diazi_CE3411")
        @test typeof(result) == CAOS.Node
    end

    @testset "get_neighbors" begin
        neighbors = get_neighbors(tree, "Tubificoides_diazi_CE3411")

        @test length(neighbors) == 61
        @test neighbors[1:3] == ["Tubificoides_insularis_CE3417", "Tubificoides_insularis_I_CE3424", "Tubificoides_insularis_II_CE4438"]
        @test neighbors[58:61] ==  ["Tubificoides_heterochaetus_CE2266", "Tubificoides_heterochaetus_CE2447", "Tubificoides_heterochaetus_CE2260", "Tubificoides_insularis_CE3418"]
    end

    @testset "get_all_neighbors" begin
        @test get_all_neighbors(tree, character_labels, "Tubificoides_diazi_CE3411") == ["Tubificoides_diazi_CE3410"]
    end

    @testset "get_first_taxa_from_tree" begin
        #println(get_first_taxa_from_tree(tree))
        # needs to fix fefn
    end

    @testset "get_descendents" begin
        desc = get_descendents(tree)
        @test desc[1:3] == ["Tubificoides_insularis_CE3417", "Tubificoides_insularis_I_CE3424", "Tubificoides_insularis_II_CE4438"]
    end

    @testset "downsample_taxa" begin
        taxa = ["1", "2", "3", "4", "5"]
        @test length(downsample_taxa(taxa, 0.2)) == 1
    end

    @testset "get_adjusted_start" begin
        s = "--S1234"
        @test get_adjusted_start(1, s) == 3
    end
end
