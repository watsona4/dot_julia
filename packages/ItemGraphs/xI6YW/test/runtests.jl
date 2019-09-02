using ItemGraphs
using Test

abstract type Item end

struct A <: Item end
struct B <: Item end
struct C <: Item end
struct D <: Item end

@testset "ItemGraphs" begin
    g = ItemGraph{Item}()
    add_edge!(g, A(), B())
    add_edge!(g, B(), C())
    add_edge!(g, B(), D())

    @test ItemGraphs.getid(g, A()) == 1
    @test ItemGraphs.getid(g, B()) == 2
    @test ItemGraphs.getid(g, C()) == 3
    @test ItemGraphs.getid(g, D()) == 4
    @test ItemGraphs.getitem(g, 1) == A()
    @test ItemGraphs.getitem(g, 2) == B()
    @test ItemGraphs.getitem(g, 3) == C()
    @test ItemGraphs.getitem(g, 4) == D()

    @test items(g, A(), C()) == [A(), B(), C()]
    @test items(g, A(), D()) == [A(), B(), D()]

    g = ItemGraph{Int}()
    add_edge!(g, 101, 202)
    add_edge!(g, 202, 303)
    add_edge!(g, 202, 404)

    @test ItemGraphs.getid(g, 101) == 1
    @test ItemGraphs.getid(g, 202) == 2
    @test ItemGraphs.getid(g, 303) == 3
    @test ItemGraphs.getid(g, 404) == 4
    @test ItemGraphs.getitem(g, 1) == 101
    @test ItemGraphs.getitem(g, 2) == 202
    @test ItemGraphs.getitem(g, 3) == 303
    @test ItemGraphs.getitem(g, 4) == 404

    @test items(g, 101, 303) == [101, 202, 303]
    @test items(g, 101, 404) == [101, 202, 404]
    @test edgeitems(g, 101, 404) == [0.0, 0.0]

    @test items(g, 101, 102) == []
    @test items(g, 102, 101) == []

    add_edge!(g, 505, 606)
    @test items(g, 101, 505) == []

    g = ItemGraph{Int,Int}()
    add_edge!(g, 101, 202, 102)
    add_edge!(g, 202, 303, 203)
    add_edge!(g, 202, 404, 204)
    @test edgeitem(g, 101, 202) == 102
    @test edgeitems(g, 101, 303) == [102, 203]
    @test edgeitems(g, 101, 404) == [102, 204]
    @test edgeitems(g, 101, 102) == []
end
