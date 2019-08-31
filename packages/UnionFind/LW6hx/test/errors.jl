function errors_main()
    lim = 10
    
    uf = UnionFinder(lim)
    
    @test_throws BoundsError union!(uf, lim, 0)
    @test_throws BoundsError union!(uf, 0, lim)
    @test_throws BoundsError union!(uf, lim, lim + 1)
    @test_throws BoundsError union!(uf, lim + 1, lim)
    
    @test_throws ArgumentError union!(uf, [lim, lim, lim], [lim, lim])

    @test_throws BoundsError union!(uf, [lim], [0])
    @test_throws BoundsError union!(uf, [0], [lim])
    @test_throws BoundsError union!(uf, [lim], [lim + 1])
    @test_throws BoundsError union!(uf, [lim + 1], [lim])
    
    @test_throws BoundsError union!(uf, [(lim, 0)])
    @test_throws BoundsError union!(uf, [(0, lim)])
    @test_throws BoundsError union!(uf, [(lim, lim + 1)])
    @test_throws BoundsError union!(uf, [(lim + 1, lim)])
    
    @test_throws BoundsError find!(uf, lim + 1)
    @test_throws BoundsError find!(uf, 0)
    
    @test_throws BoundsError size!(uf, lim + 1)
    @test_throws BoundsError size!(uf, 0)
    
    cf = CompressedFinder(uf)
    
    @test_throws BoundsError find(cf, lim + 1)
    @test_throws BoundsError find(cf, 0)

    @test_throws ArgumentError UnionFinder(0)
end

errors_main()
