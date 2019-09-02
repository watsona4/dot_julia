function test_isa(onto, term1, term2)
    @test is_a(onto, term1, term2)
    @test !is_a(onto, term2, term1)
end

@testset "relationship tests" begin
    GO = OBOParse.load("$testdir/data/go_mini.obo", "GO")

    @test_throws KeyError gettermbyid(GO, 0)
    term1 = gettermbyid(GO, 1)
    term2 = gettermbyid(GO, 2)
    term4 = gettermbyid(GO, 4)
    term5 = gettermbyid(GO, 5)
    term6 = gettermbyid(GO, 6)

    @test_throws KeyError gettermbyid(GO, OBOParse.gettermid(GO, 0))
    @test gettermbyid(GO, OBOParse.gettermid(GO, 1)) == term1
    @test gettermbyid(GO, "GO:0000001") == term1
    @test gettermbyid(GO, OBOParse.gettermid(GO, 2)) == term2

    @test_throws KeyError gettermbyname(GO, "zero")
    @test gettermbyname(GO, "one") == term1
    @test gettermbyname(GO, "two") == term2

    test_isa(GO, term1, term2)
    test_isa(GO, term4, term2)
    test_isa(GO, term5, term4)
    test_isa(GO, term5, term2)

    @test !is_a(GO, term1, term5)
    @test !is_a(GO, term5, term1)

    @test parents(GO, term1) == [term2]
    @test isempty(parents(GO, term2))
    @test parents(GO, term4) == [term2]
    @test parents(GO, term5) == [term4]

    @test children(GO, term1) == []
    @test Set(children(GO, term2)) == Set([term1, term4])
    @test children(GO, term4) == [term5]
    @test children(GO, term5) == []

    @test ancestors(GO, term1) == [term2]
    @test Set(ancestors(GO, term5)) == Set([term2, term4])
    @test Set(ancestors(GO, term6, :part_of)) == Set([term5])
    @test Set(ancestors(GO, term6, (:is_a, :part_of))) == Set([term2, term4, term5])
    @test Set(ancestors(GO, term6, [:is_a, :part_of])) == Set([term2, term4, term5])

    @test Set(descendants(GO, term2)) == Set([term1, term4, term5])
    @test descendants(GO, term5) == []

    @test Set(descendants(GO, term5, :part_of)) == Set([term6])
    @test Set(descendants(GO, term2, (:is_a, :part_of))) == Set([term1, term4, term5, term6])
    @test Set(descendants(GO, term2, [:is_a, :part_of])) == Set([term1, term4, term5, term6])
end
