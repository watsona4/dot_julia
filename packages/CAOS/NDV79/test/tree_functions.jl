using Tokenize

@testset "tree_functions" begin

    @testset "parse_tree format 1" begin
        tree = parse_tree("data/S10593.nex")
        @test length(tree) == 4

        nodes, taxa_labels, character_labels, title = tree
        @test typeof(nodes) == Array{Dict{String,Any},1}
        @test typeof(taxa_labels) == Dict{String,String}
        @test typeof(character_labels) == Dict{String,String}
        @test typeof(title) == String

        @test length(nodes[1]["Taxa"]) == 62
        @test nodes[1]["Descendents"][1] == 2
        @test nodes[1]["Groups"] == 2

        @test taxa_labels["32"] == "Tubificoides_parapectinatus_CE2490"
        @test taxa_labels["10"] == "Tubificoides_amplivasatus_CE1731"

        @test character_labels["Tubificoides_amplivasatus_CE1731"] == """---------------------CTGC-----GGAAGATCATT------------CCCGTTTCCACACACGATCGACAC-ACGTGCTTTAACGGAG--------GTACAGATCGCGTCGTG--------------------ATTACATTTGAACGCAATTCCGTTCGGCTGTCC-GACAACAGCAGGGCAGTCGT---------------------------------------------------GAGTGGTATGTGGGCCTGGGCAACCCACAAGGGCAGCTAG-------------------------------------------------------------------------------------------------CCTAGCAACGGCTACGATGCTCCCTCCCAACAGTGTCGAGTGATGGTGGAGAA------CGAGGAGC----------GTAACATGCACGAAAGAGTGCA-AGAACGAG-----------------------------TGCACAGACCAAGGAAAGTCAGAGGCAAGCTGATACGAAAGGAAACTGCGAAAGGAAGTACGGAGACTGTGCGAATGA-------------------------------------------ATTATCCCATGTTACCGAATA-----------CGATGAA-------TAC---TCGTTGAAA-CTTCGGGGTACCTGTCGT--------------------------------------GTCGACT-------CTTGC--------------------------------------------ACGATGAGCTGGTCGCGGGCGATC------CCCGCGGCTTCGCGAAGGTTCAAAGAAGCGCGGTT-----------------------CGTCGCTCGCCGT--------CGGTCGGCC-TAAATGCCGGC---------GTGCGAGCAGCGTGCC-------------GCGCTCGCCCCGAAGCCATTTGT-TCGTTTTTTTTCGTACGGTTGCTA--TCGGTCACCTGCCGGTCGACGGA---------------------------------------------------------------------------GGCC-------------------GCCCTTGTTGAACGACTGGGGCTGG--------CCGAAGTCGCGC--------------------------------------------------------------CGCGTA-CGGTGCTGCCCA------GTGTGGAATTTTG--TACAACTCTAAGCGGTGGATCACTCGGCTCGTGTGTCGATGAAGAGCGCAGCCAGCTGCGTGACCTAATGTGAATTGCAGGACACATTGAACATCGATATCTTGAACGCACATTGCGGCCTCGGGTATTCCCGAGGCCACGCCTGTCTCAGGG-TCGGTTGAAACTATCAATCG-TCGGTCGACT---TTTGCCGACGCATTGGAT-GTCGCGGT--GC-GCCGAACTATTA-------------------AGTCGTCGTCGTTCGCGATCGGTCGAAC-TAAATGCCGATCGCGGCGGCGG-----------------CGCA-----GCGCGCCACGTCGTCCGAAGTACAGACGGGT------C-------------------------TGC-GCCTAAGCCTTGCCGACCGCACGTCCT---CAGTCCGTCATT--GCG---------------GAAGGGGACGGC-GACTCGGAAACGT---TGAGAAGCCGTCGCCT---A-TTGCT--TTG-----GCGGTACGGT--------------------CG-GCGTAGGCTGTGTGGCAC--GAC-----------CCAAG-------------------------------AACGAA-------------CGAACGACCGC---------TTGAACGGGGTTGAGCGTCG------ACTCTTGCGTCTTCCTAATTACTCGCGC-------------------------------------------------------------------------------------------------------------------------GTCTTCAT------TCTTCTTCGAC------------------CTGAGATCAGACGAGATTACCCGCTGA---ATTTAA"""

        @test title == "Tubificoides_ITS"


        tree = parse_tree("data/S10593.nex", taxa_to_remove=["Tubificoides_imajimai_CE536", "Tubificoides_benedii_II_CE2692"])
        @test length(tree) == 4

        nodes, taxa_labels, character_labels, title = tree
        @test !(["30", "45"] in nodes[1]["Taxa"])
        @test !haskey(taxa_labels, "30")
        @test !haskey(taxa_labels, "45")
        @test !haskey(character_labels, "Tubificoides_imajimai_CE536")
        @test !haskey(character_labels, "Tubificoides_benedii_II_CE2692")
    end

    @testset "parse_tree format 2" begin
        tree = parse_tree("data/E1E2L1.nex")
        nodes, taxa_labels, character_labels, title = tree

        @test length(nodes) == 421

    end


    @testset "remove_from_tree" begin
        tree = "((1,2,3),((4,5),6));"
        tree_tokens = [untokenize(token) for token in collect(tokenize(tree))]
        remove_from_tree!(tree_tokens,["1"])

        @test !occursin("1", join(tree_tokens))

        tree = "((apple,pinapple,pear),((tomatoe,pepper),potatoe)));"
        tree_tokens = [untokenize(token) for token in collect(tokenize(tree))]
        remove_from_tree!(tree_tokens,["pepper"])
        @test join(tree_tokens) == "((apple,pinapple,pear),((tomatoe),potatoe)));"
        @test !occursin("pepper", join(tree_tokens))

        remove_from_tree!(tree_tokens,["pinapple", "pear"])
        @test join(tree_tokens) == "((apple),((tomatoe),potatoe)));"
        @test !occursin("pinapple", join(tree_tokens))
        @test !occursin("pear", join(tree_tokens))

        tree = "(,(apple,pinapple,pear),((tomatoe,pepper),potatoe)));"
        tree_tokens = [untokenize(token) for token in collect(tokenize(tree))]
        remove_from_tree!(tree_tokens,["pinapple", "pear"])
        @test !occursin("pear", join(tree_tokens))

        tree = "((1,2,3),(a),((4,5),6));"
        tree_tokens = [untokenize(token) for token in collect(tokenize(tree))]
        remove_from_tree!(tree_tokens,["a"])

        @test join(tree_tokens) == "((1,2,3),((4,5),6));"
        @test !occursin("a", join(tree_tokens))

    end

    @testset "get_nodes" begin
        tree = "(1,((2,3),((4,5),6)));"

        nodes = get_nodes(tree)

        @test length(nodes) == 5
        @test nodes[1]["Taxa"] == ["1", "2", "3", "4", "5", "6"]
        @test nodes[2]["Taxa"] == ["2", "3", "4", "5", "6"]
        @test nodes[3]["Taxa"] == ["2", "3"]
        @test nodes[4]["Taxa"] == ["4", "5", "6"]
        @test nodes[5]["Taxa"] == ["4", "5"]

        @test nodes[1]["Descendents"] == [2]
        @test nodes[2]["Descendents"] == [3,4]
        @test nodes[3]["Descendents"] == []
        @test nodes[4]["Descendents"] == [5]
        @test nodes[5]["Descendents"] == []

        @test nodes[1]["Groups"] == 2
        @test nodes[2]["Groups"] == 2
        @test nodes[3]["Groups"] == 2
        @test nodes[4]["Groups"] == 2
        @test nodes[5]["Groups"] == 2


        tree = "((1,2,3),((4,5),6)));"
        nodes = get_nodes(tree)

        @test length(nodes) == 4
        @test nodes[1]["Taxa"] == ["1", "2", "3", "4", "5", "6"]
        @test nodes[2]["Taxa"] == ["1", "2", "3"]
        @test nodes[3]["Taxa"] == ["4", "5", "6"]
        @test nodes[4]["Taxa"] == ["4", "5"]

        @test nodes[1]["Descendents"] == [2,3]
        @test nodes[2]["Descendents"] == []
        @test nodes[3]["Descendents"] == [4]
        @test nodes[4]["Descendents"] == []

        @test nodes[1]["Groups"] == 2
        @test nodes[2]["Groups"] == 3
        @test nodes[3]["Groups"] == 2
        @test nodes[4]["Groups"] == 2


        tree = "((1,2,3),((4,5),6)));"
        nodes = get_nodes(tree, taxa_to_remove=["2"])

        @test length(nodes) == 4
        @test nodes[1]["Taxa"] == ["1", "3", "4", "5", "6"]
        @test nodes[2]["Taxa"] == ["1", "3"]
        @test nodes[3]["Taxa"] == ["4", "5", "6"]
        @test nodes[4]["Taxa"] == ["4", "5"]

        @test nodes[1]["Descendents"] == [2,3]
        @test nodes[2]["Descendents"] == []
        @test nodes[3]["Descendents"] == [4]
        @test nodes[4]["Descendents"] == []

        @test nodes[1]["Groups"] == 2
        @test nodes[2]["Groups"] == 2
        @test nodes[3]["Groups"] == 2
        @test nodes[4]["Groups"] == 2


        tree = "((1,2,3),((4,5),6)));"
        nodes = get_nodes(tree, taxa_to_remove=["1", "2", "3"])

        @test length(nodes) == 3
        @test nodes[1]["Taxa"] == []
        @test nodes[2]["Taxa"] == ["4", "5", "6"]
        @test nodes[3]["Taxa"] == ["4", "5"]

        @test nodes[1]["Descendents"] == []
        @test nodes[2]["Descendents"] == [3]
        @test nodes[3]["Descendents"] == []

        @test nodes[1]["Groups"] == 1
        @test nodes[2]["Groups"] == 2
        @test nodes[3]["Groups"] == 2

    end

    @testset "add_nodes!" begin

    end
end
