@testset "Matúš" begin
    function eq3(id1, id2)
        h1 = submodular(5,2,4,3) + submodular(5,3,4,2)
        h2 = submodular(5,3,4,2) + submodular(5,2,4,3)
        h1.liftid = id1
        h2.liftid = id2
        setequality(DualEntropyLift(h1, 3) - DualEntropyLift(h2, 3))
    end
    function eq4(id1, id2)
        h1 = ingleton(5,1,2,3,4)
        h2 = ingleton(5,1,2,3,4)
        h1.liftid = id1
        h2.liftid = id2
        setequality(DualEntropyLift(h1, 3) - DualEntropyLift(h2, 3))
    end
    function supmodular()
        submodular(5,3,4,5) + submodular(5,4,5,3) + submodular(5,3,5,4)
    end
    function lemma3(id1, id2)
        h1 = ingleton(5,1,2,3,4) + supmodular()
        h2 = submodular(5,1,5,3 ) + submodular(5,1,5,4 ) + submodular(5,2, 5,3 ) + submodular(5,2,5,4) +
        submodular(5,1,2,5 ) + submodular(5,3,4,15) + submodular(5,3, 4,25) + submodular(5,34,5,12) -
        (submodular(5,1,5,34) + submodular(5,2,5,34) + submodular(5,12,5,34))
        h1.liftid = id1
        h2.liftid = id2
        setequality(DualEntropyLift(h1, 3) - DualEntropyLift(h2, 3))
    end
    function cor1(id1, id2)
        h1 = ingleton(5,1,2,3,4) + supmodular()
        h2 = submodular(5,1,5,3) + submodular(5,1,5,4) + submodular(5,2,5,3) + submodular(5,2,5,4)
        h1.liftid = id1
        h2.liftid = id2
        h = DualEntropyLift(h1, 3) - DualEntropyLift(h2, 3)
        h
    end
    function eq5(id1, id2)
        h1 = ingleton(5,1,2,3,4) + supmodular()
        h2 = submodular(5,2,5,4)
        h1.liftid = id1
        h2.liftid = id2
        h = DualEntropyLift(h1, 3) - DualEntropyLift(h2, 3)
        h
    end

    G1 = polymatroidcone(5, Polyhedra.DefaultLibrary{Float64}(lp_solver))
    G2 = polymatroidcone(5, Polyhedra.DefaultLibrary{Float64}(lp_solver))
    G3 = polymatroidcone(5, Polyhedra.DefaultLibrary{Float64}(lp_solver))
    intersect!(G2, submodulareq(5, 5, 12, 34))
    #intersect!(G3, submodulareq(5, 5, 12, 34))
    intersect!(G3, submodulareq(5, 5, 13, 24))
    G = G1 * G2 * G3
    equalonsubsetsof!(G, 1, 2, 1234)
    equalonsubsetsof!(G, 1, 2, 345)
    equalonsubsetsof!(G, 2, 3, 1234)
    equalonsubsetsof!(G, 2, 3, 245)

    eq3_12 = eq3(1,2)
    eq4_12 = eq4(1,2)
    @test eq3_12 in G
    @test eq4_12 in G

    lemma3_11 = lemma3(1,1)
    @test lemma3_11 in G
    lemma3_22 = lemma3(2,2)
    @test lemma3_22 in G
    lemma3_12 = lemma3(1,2)
    @test lemma3_12 in G
    cor1_12 = cor1(1,2)
    @test cor1_12 in G
    eq5_12 = eq5(1,2)
    @test eq5_12 in G

    for s in 0:5
        @test (matus51(s) in G) == (s <= 2)
    end

    equalvariable!(G, 1, 2, 5)
    for s in 0:5
        cons4 = matus41(s)
        @test cons4 == (2*s * (submodular(4,3,4,1) + submodular(4,3,4,2) + submodular(4,1,2) - submodular(4,3,4)) + 2*submodular(4,2,3,4) + s*(s+1)*(submodular(4,2,4,3)+submodular(4,3,4,2)))
        cons5 = DualEntropy{false}([cons4.h; zeros(Int, 16)])
        @test (cons5 in G) == (s <= 2)
    end
    #for i = 0:10
    #  s = 1 << i
    #  cons4 = constraint4(s)
    #  cons5 = DualEntropy([cons4.h; zeros(Int, 16)])
    #  println(s)
    #  println(cons5 in G)
    #end

    p4 = zeros(Float64,2,2,1,1)
    p4[1,1,1,1] = 1/2
    p4[2,2,1,1] = 1/2
    r4 = convert(PrimalEntropy{Int}, entropyfrompdf(p4))
    mr4 = matusrentropy(1,34)
    @test r4 == mr4
    p5 = zeros(Float64,2,2,1,1,2)
    p5[1,1,1,1,1] = 1/2
    p5[2,2,1,1,2] = 1/2
    r5 = convert(PrimalEntropy{Int}, entropyfrompdf(p5))
    #r52 = PrimalEntropy{Int}(entropyfrompdf(p5))
    #r52.liftid = 2
    #r53 = PrimalEntropy{Int}(entropyfrompdf(p5))
    #r53.liftid = 3
    #R = ((r5 * r52) * r53)
    #println(R in G)
    #@test r4 == R[1:15]
    @test r4.h == r5[1:15]
    @test r4 in G
    @test r5 in G
    #println(invalidfentropy(12) in G)

    @test matusrentropy(1,14) in G
    @test matusrentropy(1,23) in G
    @test matusrentropy(2,4) in G
    @test matusrentropy(1,24) in G
    @test matusrentropy(2,3) in G
    @test !(invalidfentropy(12) in G)

    function pdf4(p)
        x = zeros(Float64,2,2,2,2)
        x[1,1,1,2] = p
        x[1,2,1,1] = p
        x[2,1,1,1] = 0.5 - p
        x[2,2,2,1] = 0.5 - p
        x
    end
    function pdf05(p)
        x = zeros(Float64,2,2,2,2,2)
        x[1,1,1,2,1] = p
        x[1,2,1,1,2] = p
        x[2,1,1,1,1] = 0.5 - p
        x[2,2,2,1,2] = 0.5 - p
        x
    end

    function safe_div(x, y)
        if x == 0
            0
        else
            x / y
        end
    end

    hxi04 = entropyfrompdf(pdf4(0))
    pdf0 = pdf05(0)
    pdf0_345 = subpdf(pdf0, 345)
    pdf0_1234 = subpdf(pdf0, 1234)
    pdf0_34 = subpdf(pdf0, 34)
    pdf0_45 = subpdf(pdf0, 45)
    pdf0_4 = subpdf(pdf0, 4)
    pdf1 = zeros(Float64, 2, 2, 2, 2, 2)
    pdf2 = zeros(Float64, 2, 2, 2, 2, 2)
    for x1 = 1:2
        for x2 = 1:2
            for x3 = 1:2
                for x4 = 1:2
                    for x5 = 1:2
                        pdf1[x1,x2,x3,x4,x5] = safe_div(pdf0_345[1,1,x3,x4,x5] * pdf0_1234[x1,x2,x3,x4,1], pdf0_34[1,1,x3,x4,1])
                        pdf2[x1,x2,x3,x4,x5] = safe_div(pdf0_45[1,1,1,x4,x5] * pdf0_1234[x1,x2,x3,x4,1], pdf0_4[1,1,1,x4,1])
                    end
                end
            end
        end
    end

    hxi05 = entropyfrompdf(pdf0)
    hxi15 = entropyfrompdf(pdf1)
    hxi15.liftid = 2
    hxi25 = entropyfrompdf(pdf2)
    hxi25.liftid = 3

    hxi5 = (hxi05 * hxi15) * hxi25

    @test hxi04 == hxi(0)
    @test hxi05[1:15] == hxi(0).h
    @test hxi5[1:15] == hxi(0).h

    Gf = convert(EntropyConeLift{Float64}, G)

    @test !(hxi5 in Gf)

    @test hxi(0) in Gf
    @test g_p(0) in Gf
    function mytest(h)
        @test hxi(h) in Gf
        @test g_p(h) in Gf
    end
    mytest(.000001)
    mytest(.00001)
    mytest(.0001)
    mytest(.001)
    mytest(.01)
    mytest(.1)
end
