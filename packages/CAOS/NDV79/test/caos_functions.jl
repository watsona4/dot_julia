@testset "caos_functions" begin
    tree = parse_tree("data/S10593.nex")
    nodes, taxa_labels, character_labels, title = tree
    node_num = 2

    @testset "get_group_taxa_at_node" begin
        @test get_group_taxa_at_node(nodes, 44)[1] == ["58", "59", "60"]
        @test get_group_taxa_at_node(nodes, 44)[2] == ["61", "62"]

    end

    @testset "get_sPu_and_sPr" begin
        sPu, sPr = get_sPu_and_sPr(nodes, node_num, taxa_labels, character_labels; protein=false)
        @test typeof(sPu) == Array{Dict{String,Any},1}
        @test length(sPu) == 2
        @test sPu[1]["Num_Non_Group"] == 59
        @test sPu[1]["Group_Taxa"] == ["2", "3"]

        #println(sPr)
    end

    @testset "get_cPu_and_cPr" begin
        sPu, sPr = get_sPu_and_sPr(nodes, node_num, taxa_labels, character_labels; protein=false)
        cPu, cPr = get_cPu_and_cPr(nodes, node_num, taxa_labels, character_labels, sPu, sPr)
        @test typeof(cPu) == Array{Dict{String,Any},1}
    end

    @testset "get_group_combos" begin
        group_taxa = get_group_taxa_at_node(nodes, node_num)
        group_combos = get_group_combos(group_taxa)
        @test group_combos[2]["Non_group"] == ["2", "3"]
    end

end
