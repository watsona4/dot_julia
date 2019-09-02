using Test

using MarkovChains.Graphs
@testset "digraph" begin
    @testset "search_dfs" begin
        dg = Digraph()
        n1 = add_node!(dg)
        n2 = add_node!(dg)
        n3 = add_node!(dg)
        n4 = add_node!(dg)
        add_edge!(dg, n1, n2)
        add_edge!(dg, n2, n3)
        add_edge!(dg, n1, n4)
        order = []
        dfs(dg, n1, (p, c) -> begin
            push!(order, c)
        end)
        @test order == [1, 2, 3, 4]
    end
    @testset "scc_one_comp" begin
        dg = Digraph()
        n1 = add_node!(dg)
        n2 = add_node!(dg)
        n3 = add_node!(dg)
        add_edge!(dg, n1, n2)
        add_edge!(dg, n2, n3)
        add_edge!(dg, n3, n1)
        comps = strongly_connected_components(dg)
        @test length(comps) == 1
        @test comps[1].members == [3,2,1]
        @test comps[1].is_bottom == true
    end
    @testset "scc_acyclic" begin
        dg = Digraph()
        n1 = add_node!(dg)
        n2 = add_node!(dg)
        n3 = add_node!(dg)
        add_edge!(dg, n1, n2)
        add_edge!(dg, n2, n3)
        comps = strongly_connected_components(dg)
        @test length(comps) == 3
        @test comps[1].members == [3]
        @test comps[1].is_bottom == true
        @test comps[2].members == [2]
        @test comps[2].is_bottom == false
        @test comps[3].members == [1]
        @test comps[3].is_bottom == false
    end
    @testset "scc_two_comp" begin
        dg = Digraph()
        n1 = add_node!(dg)
        n2 = add_node!(dg)
        n3 = add_node!(dg)
        n4 = add_node!(dg)
        add_edge!(dg, n1, n2)
        add_edge!(dg, n2, n1)
        add_edge!(dg, n2, n3)
        add_edge!(dg, n3, n4)
        add_edge!(dg, n4, n3)
        comps = strongly_connected_components(dg)
        @test length(comps) == 2
        @test comps[1].members == [4, 3]
        @test comps[1].is_bottom == true
        @test comps[2].members == [2, 1]
        @test comps[2].is_bottom == false
    end
end
