function polymorphism_main()
    uf = UnionFinder(convert(UInt16, 2))
    union!(uf, convert(UInt16, 1), convert(UInt16, 2))
    reset!(uf)
    @test UInt16 == typeof(find!(uf, convert(UInt16, 1)))
    @test UInt16 == typeof(size!(uf, convert(UInt16, 1)))

    @test_throws MethodError union!(uf, convert(Int64, 1), convert(Int64, 2))
    @test_throws MethodError union!(uf, convert(UInt16, 1), convert(Int64, 2))
    @test_throws MethodError union!(uf, convert(Int64, 1), convert(UInt16, 2))
    @test_throws MethodError find!(uf, convert(Int64, 1))
    @test_throws MethodError size!(uf, convert(Int64, 1))

    cf = CompressedFinder(uf)
    @test UInt16 == typeof(find(cf, convert(UInt16, 1)))
    @test UInt16 == typeof(groups(cf))
    @test_throws MethodError find(cf, convert(Int64, 1))
end

polymorphism_main()
