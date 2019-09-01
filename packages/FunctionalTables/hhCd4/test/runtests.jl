using FunctionalTables, Test
using FunctionalTables:
    # utilities
    cancontain, narrow, append1, split_namedtuple, is_prefix, merge_default_types,
    # column ordering building blocks
    ColumnOrdering, mask_ordering, table_ordering, cmp_ordering, retained_ordering,
    ordering_repr, split_compatible_ordering,
    # column collection building blocks
    SINKCONFIG, collect_column, collect_columns, RLEVector, TrustLength
import Tables
using Statistics: mean

include("utilities.jl")         # utilities for tests

####
#### Utilities and low-level building blocks
####

@testset "narrow" begin
    @test narrow(true) ≡ true
    @test narrow(false) ≡ false
    @test narrow(1) ≡ Int8(1)
    @test narrow(0) ≡ Int8(0)
    @test narrow(-9) ≡ Int8(-9)
    @test narrow(128) ≡ Int16(128)
    @test narrow(2^17) ≡ Int32(2^17)
    @test narrow(2^32) ≡ Int(2^32)
end

@testset "cancontain" begin
    @test cancontain(Int8, -7)
    @test !cancontain(Int8, typemax(Int8) + 1)
    @test !cancontain(String, -7)
    @test cancontain(Float64, Int8(9))
    @test cancontain(Float64, maxintfloat(Float64))
    @test !cancontain(Float64, Int(maxintfloat(Float64)) + 1)
    for T in (Float32, Float64)
        # Test around `maxintfloat`, as it will fail if the number can be contained by
        # accident.
        for elt in vcat(Int(maxintfloat(T)) .+ (-1:1), -Int(maxintfloat(T)) .+ (-1:1))
            v = T[]
            push!(v, elt)
            (oftype(elt, v[1]) ≡ elt) ≡ cancontain(T, elt)
        end
    end
end

@testset "append1" begin
    a1 = append1(ones(Int8, 2), missing)
    @test eltype(a1) ≡ Union{Missing, Int8}
    @test [1, 1, missing] ≅ a1
end

@testset "splitting named tuples" begin
    s = NamedTuple{(:a, :c)}
    @test @inferred(split_namedtuple(s, (a = 1, b = 2, c = 3, d = 4))) ≡
        ((a = 1, c = 3), (b = 2, d = 4))
    @test @inferred(split_namedtuple(s ,(c = 1, b = 2, a = 3, d = 4))) ≡
        ((a = 3, c = 1), (b = 2, d = 4))
    @test_throws ErrorException split_namedtuple(s, (a = 1, b = 2))
end

@testset "merge_default_types" begin
    T = NamedTuple{(:a, :b), Tuple{Union{}, Union{}}}
    @test merge_default_types(T, typeof(NamedTuple())) ≡ T
    @test merge_default_types(T, NamedTuple{(:c, :d), Tuple{Missing, String}}) ≡ T
    @test merge_default_types(T, NamedTuple{(:a, ), Tuple{Missing}}) ≡
        NamedTuple{(:a, :b), Tuple{Missing, Union{}}}
end

@testset "picking and wrapping" begin
    x = 1:5
    ax = wrapping(:a).(x)
    @test ax == collect((a = i,) for i in x)
    @test picking(:a).(ax) == x
end

####
#### columns
####

@testset "collect by names" begin
    itr = [(a = i, b = Float64(i), c = 'a' + i - 1) for i in 1:10]
    ordering = table_ordering((:a, :b, :c))
    len, result, rule = collect_columns(SinkConfig(;useRLE = false), itr, TrustOrdering(ordering))
    @test len ≡ TrustLength(10)
    @test result isa NamedTuple{(:a, :b, :c), Tuple{Vector{Int8}, Vector{Float64}, Vector{Char}}}
    @test result.a ≅ 1:10
    @test result.b ≅ Float64.(1:10)
    @test result.c ≅ (0:9) .+ 'a'
    @test rule ≡ TrustOrdering(ordering)
end

@testset "RLE creation" begin
    r = RLEVector{Missing}(Int8, Missing)
    @test eltype(typeof(r)) ≡ Missing
    @test length(r) == 0

    r = RLEVector{Missing}(Int8, Float64)
    @test eltype(typeof(r)) ≡ Float64
    @test length(r) == 0

    r = RLEVector{Missing}(Int8, Union{})
    @test eltype(typeof(r)) ≡ Union{}
    @test length(r) == 0

    r = RLEVector{Missing}(Int8, Union{Missing, Float64})
    @test eltype(typeof(r)) ≡ Union{Missing, Float64}
    @test length(r) == 0
end

@testset "simple RLE" begin
    v = vcat(fill(1, 10), fill(missing, 5), fill(2, 20))
    s = collect_column(SINKCONFIG, v)
    @test length(s) == 35
    @test eltype(typeof(s)) ≡ Union{Int8, Missing}
    @test s.data == [1, 2]
    @test s.counts == [10, -5, 20]
    @test collect(s) ≅ v
end

@testset "RLE corner cases" begin
    s = collect_column(SINKCONFIG, [missing])
    @test length(s) == 1
    @test collect(s)[1] ≡ missing
    @test eltype(typeof(s)) ≡ Missing
    s = collect_column(SINKCONFIG, [130])
    @test length(s) == 1
    @test eltype(typeof(s)) ≡ Int16
    @test collect(s) == [130]
end

@testset "overrun RLE" begin
    v = vcat(fill(1, 300), fill(missing, 5), fill(2, 20), fill(missing, 200))
    s = collect_column(SINKCONFIG, v)
    @test length(s) == length(v)
    @test eltype(typeof(s)) ≡ Union{Int8, Missing}
    @test s.data == [1, 1, 1, 2]
    @test s.counts == [127, 127, 300-(2*127), -5, 20, -128, -200+128]
    @test collect(s) ≅ v
end

@testset "large collection" begin
    v = randvector(1000)
    len, columns, ordering = collect_columns(SINKCONFIG, [(a = a, ) for a in v], TrustOrdering())
    @test len ≡ TrustLength(length(v))
    @test collect(columns.a) ≅ v
    @test ordering ≡ TrustOrdering()
end

@testset "is_prefix" begin
    @test is_prefix((:a, ), (:a, :b, :c))
    @test is_prefix((:a, :b, :c), (:a, :b, :c))
    @test is_prefix((), ())
    @test !is_prefix((:b, :c), (:a, :b, :c))
    @test !is_prefix((:b, ), ())
    @test !is_prefix((:b, :c, :a), (:a, :b, :c))
end

####
#### Ordering building blocks
####

@testset "column ordering specifications" begin
    @test table_ordering((:a, :b => reverse, ColumnOrdering(:c, false))) ==
        (ColumnOrdering(:a, false), ColumnOrdering(:b, true), ColumnOrdering(:c, false))
    @test_throws ArgumentError table_ordering(("foobar", "baz")) # invalid
    @test_throws ArgumentError TrustOrdering(:a, :a)             # duplicate

    @test ordering_repr(()) == "no ordering"
    @test ordering_repr(table_ordering((:a, :b => reverse))) == "ordering ↑a ↓b"
end

@testset "mask_ordering" begin
    t = table_ordering((:a, :b => reverse, :c))
    @test mask_ordering(t, (:a, )) ≡ t[[1]]
    @test mask_ordering(t, (:b, )) ≡ ()
    @test mask_ordering(t, (:c, )) ≡ ()
    @test mask_ordering(t, (:b, :a, )) ≡ t[[1,2]]
    @test mask_ordering(t, (:c, :a, )) ≡ t[[1]]

    o = table_ordering((:a, :b, :c))
    @test mask_ordering(o, (:d, :e), true) ≡ o
    @test mask_ordering(o, (:c, :b), true) ≡ table_ordering((:a, ))
    @test mask_ordering(o, (:a, :b, :c), true) ≡ table_ordering(())
end

@testset "retained ordering" begin
    o = table_ordering((:a, :b => reverse))
    row = (a = 1, b = 2, c = 3)
    @test retained_ordering(o, row, row) ≡ o
    @test retained_ordering(o, row, (a = 2, b = 1, c = -1)) ≡ o
    @test retained_ordering(o, row, (a = 2, b = 3, c = -1)) ≡ table_ordering((:a, ))
    @test @inferred(retained_ordering(table_ordering(()), row, row)) ≡ table_ordering(())
end

@testset "split compatible ordering" begin
    ordering = table_ordering((:a, :b => reverse, :c))
    @test split_compatible_ordering(ordering, (:a, )) ≡ ordering[1:1]
    @test split_compatible_ordering(ordering, (:a, :b)) ≡ ordering[1:2]
    @test split_compatible_ordering(ordering, (:b, :a)) ≡ ordering[[2, 1]]
    @test split_compatible_ordering(ordering, (:b, :a, :d)) ≡
        table_ordering((ordering[[2, 1]]..., :d))
    @test split_compatible_ordering((), (:b, :a, :d)) ≡ table_ordering((:b, :a, :d))
    @test split_compatible_ordering((), ()) ≡ ()
end

####
#### FunctionalTable API
####

@testset "FunctionalTable basics and column operations" begin
    A = 1:10
    B = 'a':('a'+9)
    C = Float64.(21:30)
    ft = FunctionalTable((a = A, b = B, c = C))
    @test Base.IteratorEltype(ft) ≡ Base.HasEltype()
    @test eltype(typeof(ft)) ≡ typeof((a = first(A), b = first(B), c = first(C)))
    @test Base.IteratorSize(ft) ≡ Base.HasLength()
    @test length(ft) ≡ length(A)
    @test @inferred(keys(ft)) ≡ (:a, :b, :c)
    @test @inferred(propertynames(ft)) ≡ (:a, :b, :c)
    @test @inferred(columns(ft)) ≡ getfield(ft, :columns)
    column_a(ft) = ft.a         # wrap for inference to kick in
    @test @inferred(column_a(ft)) ≡ A
    @test_throws ErrorException ft.nonexistent
    @test @inferred(values(ft)) ≡ values(columns(ft))
    @test ft[(:a, :b)] ≅ FunctionalTable((a = A, b = B))
    @test ft[drop = (:a, :b)] ≅ FunctionalTable((c = C,))
    @test ft[:a] == A
    @test FunctionalTable(ft) ≅ ft
    cols = @inferred map(collect, columns(ft))
    @test all(isa.(values(cols), AbstractVector))
    @test cols.a == A && cols.a ≢ A
    @test cols.b == B && cols.b ≢ B
    @test cols.c == C && cols.c ≢ C
    @test @inferred(FunctionalTable(ft)) ≡ ft # same object
end

@testset "merging" begin
    A = 1:10
    B = 'a':('a'+9)
    C = Float64.(21:30)
    A2 = .-A
    ft = FunctionalTable((a = A, b = B), VerifyOrdering(:a, :b))
    @test @inferred(merge(ft, FunctionalTable((c = C, )))) ≅
        FunctionalTable((a = A, b = B, c = C), VerifyOrdering(:a, :b))
    @test_throws ArgumentError merge(ft, FunctionalTable((c = C, a = A2)))
    @test @inferred(merge(ft, FunctionalTable((c = C, a = A2)); replace = true)) ≅
        FunctionalTable((a = A2, b = B, c = C))
    @test @inferred(merge(ft, FunctionalTable((c = C, a = A2)); replace = true)) ≅
        merge(ft, (c = C, a = A2); replace = true)
end

@testset "map (direct)" begin
    A = 1:10
    B = 'a':('a'+9)
    ft = @inferred FunctionalTable((a = A, b = B), VerifyOrdering(:a, :b))
    f(row) = (b = row.a + 1, c = row.b + 2)
    B2 = A .+ 1
    C = collect(B .+ 2)
    ft2 = map(f, ft)
    # NOTE map removes ordering
    @test ft2 ≅ FunctionalTable((b = B2, c = C))
    ft3 = merge(f, ft; replace = true)
    # NOTE as :b is replaced, its ordering is removed
    @test ft3 ≅ FunctionalTable((a = A, b = B2, c = C), VerifyOrdering((:a, )))
    # overlap, without replacement
    @test_throws ArgumentError merge(f, ft)
end

@testset "filter" begin
    A = 1:5
    B = 'a':'e'
    o = VerifyOrdering(:a, :b)
    ft = FunctionalTable((a = A, b = B), o)
    @test filter(row -> isodd(row.a), ft) ≅
        FunctionalTable((a = [1, 3, 5], b = ['a', 'c', 'e']), o)
end

@testset "RepeatRow" begin
    rr = RepeatRow((a = 1, b = 2))
    ft = FunctionalTable((a = fill(1, 3), b = fill(2, 3)))
    @test @inferred(FunctionalTable(3, rr)) ≅ ft
    ft2 = FunctionalTable((c = 4:6, d = 7:9))
    @test @inferred(merge(rr, ft2)) ≅ @inferred(merge(ft, ft2))
    @test @inferred(merge(ft2, rr)) ≅ @inferred(merge(ft2, ft))
end

@testset "split by 1" begin
    keycounts = [:a => 10, :b => 17, :c => 19]
    ft = FunctionalTable(mapreduce(((k, c), ) -> [(sym = k, val = i)
                                                  for i in 1:c], vcat, keycounts),
                         TrustOrdering(:sym, :val))
    g = by(ft, (:sym, ))        # FIXME eventually this should be @inferred
    @test eltype(typeof(g)) ≡ Tuple{NamedTuple{(:sym, ), Tuple{Symbol}},
                                    FunctionalTable{NamedTuple{(:val, ), Tuple{Vector{Int8}}},
                                                    Tuple{}}} # ordering, NOTE will change to :val
    cg = @inferred collect(g)
    for (i, (s, c)) in enumerate(keycounts)
        @test cg[i] ≅ ((sym = s, ), FunctionalTable((val = 1:c, )))
    end

    # empty split keys
    @test collect(by(ft, ())) ≅ [(NamedTuple(), FunctionalTable(ft, VerifyOrdering()))]
end

@testset "split by 2" begin
    A = [1, 1, 1, 2, 2]
    B = 'a':'e'
    ft = FunctionalTable((a = A, b = B), VerifyOrdering(:a))
    g = by(ft, (:a, ))
    @test Base.IteratorSize(g) ≡ Base.SizeUnknown()
    result = collect(g)
    @test result ≅ [((a = 1, ), FunctionalTable((b = ['a', 'b', 'c'],))),
                    ((a = 2, ), FunctionalTable((b = ['d', 'e'],)))]
end

@testset "tables interface" begin
    cols = (a = 1:10, b = 'a' .+ (1:10))
    ft = FunctionalTable(cols)
    # general sanity checks
    @test Tables.columntable(ft) == cols
    @test Tables.rowtable(ft) == Tables.rowtable(cols)
    # detailed API testing
    @test Tables.istable(ft)
    @test Tables.rowaccess(ft)
    @test Tables.schema(Tables.rows(ft)) == Tables.schema(Tables.rows(cols))
    @test Tables.columnaccess(ft)
    @test Tables.schema(Tables.columns(ft)) == Tables.schema(Tables.columns(cols))
end

@testset "ordering comparisons" begin
    ordering = table_ordering((:a, :b => reverse))
    @test @inferred cmp_ordering(ordering, (a = 1, b = 2), (a = 1, b = 2)) == 0
    @test @inferred cmp_ordering(ordering, (a = 1, b = 3), (a = 1, b = 2)) == -1
    @test @inferred cmp_ordering(ordering, (a = 0, b = 3), (a = 1, b = 2)) == -1
    @test @inferred cmp_ordering(ordering, (a = 1, b = 2), (b = 2, a = 1)) == 0 # order irrelevant
    @test_throws ErrorException cmp_ordering(ordering, (c = 1, ), (c = 1, ))    # no such field
end

@testset "sort" begin
    ft = FunctionalTable((a = [1, -1, 3, 1, 2],
                          b = [2, 2, 1, 2, 2],
                          c = 1:5))
    sft = sort(ft, (:b, :a => reverse))
    @test sft ≅ FunctionalTable((a = [3, 2, 1, 1, -1],
                                 b = [1, 2, 2, 2, 2],
                                 c = [3, 5, 1, 4, 2]),
                                VerifyOrdering(:b, :a => reverse))
    @test columns(sort(sft, (:b, ))) ≡ columns(sft) # prefix ordering

    let ordering = (:c => reverse, ) # test convenience syntax
        @test sort(ft, ordering) ≅ sort(ft, ordering...)
    end
end

@testset "map by" begin
    a = [1, 1, 1, 2, 2]
    b = 1:5
    ft = FunctionalTable((a = a, b = b), VerifyOrdering(:a, :b))
    f(_, ft) = map(sum, columns(ft))
    @test map(Ref ∘ f, by(ft, (:a, ))) ≅
        FunctionalTable((a = [1, 2], b = [6, 9]), TrustOrdering(:a, ))
end

@testset "map by with filtering" begin
    ft = FunctionalTable((a = 1:5, b = 1:5), VerifyOrdering(:a))
    @test map((_, ft) -> isodd(first(ft.b)) ? ft : (), by(ft, :a)) ≅
        FunctionalTable((a = [1, 3, 5], b = [1, 3, 5]), TrustOrdering(:a))
end

@testset "map by empty subtables" begin
    ft = FunctionalTable((a = [1, 1, 1, 2, 2], ), VerifyOrdering(:a))
    @test map((_, ft) -> Ref((len = length(ft), )), by(ft, (:a, ))) ≅
        FunctionalTable((a = [1, 2], len = [3, 2]), TrustOrdering(:a))
end

@testset "corner cases for collecting and ordering" begin
    A = (a = 1, )
    AA = [A, A]

    # different keys by row
    @test_throws ArgumentError FunctionalTable([A, (a = 1, b = 2)])

    # field specified by ordering is missing
    @test_throws ErrorException FunctionalTable(AA, VerifyOrdering(:b, ))
    @test_throws ArgumentError FunctionalTable(AA, TrustOrdering(:b, ))

    # prefix narrows ordering silently
    @test FunctionalTable(AA, TryOrdering(:b)) ≅ FunctionalTable(AA)

    # FIXME not implemented yet
    @test_skip FunctionalTable((a = [2, 1], ), (:a, ), TryOrdering()) ≅
        FunctionalTable((a = [1, 2], ), (), TrustOrdering())

    # nothing in the rows, also special constructor
    emptyrows = (NamedTuple() for _ in 1:1000)
    @test FunctionalTable(emptyrows) ≅ FunctionalTable(1000)

    # no rows
    @test FunctionalTable(()) ≅ FunctionalTable(0, NamedTuple(), TrustOrdering())
end

@testset "printing" begin
    ft = FunctionalTable((a = [1, 2], b = [3, 4]), TrustOrdering(:a, :b => reverse))
    reprft = """
    FunctionalTable of 2 rows, ordering ↑a ↓b
        a = Int64[1, 2]
        b = Int64[3, 4]"""
    @test repr(ft) == reprft
end

@testset "first" begin
    a = 1:1000
    b = fill(9, length(a))
    rt = Tables.rowtable((a = a, b = b))
    s = VerifyOrdering(:a, :b)
    ft = FunctionalTable(rt, s)
    @test first(ft, 100) ≅ FunctionalTable(Iterators.take(rt, 100), s)
end

@testset "rename" begin
    ft = FunctionalTable((a = 1:3, b = 4:6), VerifyOrdering(:b, :a => reverse))
    @test rename(ft, (a = :aa, b = :bb)) ≅
        FunctionalTable((aa = 1:3, bb = 4:6), VerifyOrdering(:bb, :aa => reverse))
    @test rename(ft, (a = :aa, )) ≅
        FunctionalTable((aa = 1:3, b = 4:6), VerifyOrdering(:b, :aa => reverse))

    # extras - error
    @test_throws ArgumentError rename(ft, (a = :aa, b = :bb, c = :cc))

    # duplicate keys
    @test_throws ArgumentError rename(ft, (a = :aa, b = :aa))

    # exchange names
    @test rename(ft, (a = :b, b = :a)) ≅
        FunctionalTable((b = 1:3, a = 4:6), VerifyOrdering(:a, :b => reverse))
end

@testset "eltype split tables" begin
    ft = FunctionalTable((a = [1, 1, 1, 2, 2, 2],
                          b = [1, 1, 1, 4, 4, 4]))
    ft2 = map(by(ft, :a)) do _, ft
        ft2 = filter(r -> r.b ≤ 1, ft) # here, ft2 is empty, but inference b has Int64 eltype
        Ref((bsum = sum(ft2.b), ))
    end
    @test ft2 ≅ FunctionalTable((a = Int8[1, 2], bsum = Int8[3, 0]), TrustOrdering(:a))
end

@testset "aggregator and ignoreindex" begin
    ft = FunctionalTable((a = [1, 1, 1, 2, 2, 2],
                          b = [1, 1, 1, 4, 4, 4]))
    ft_mean = FunctionalTable((a = Int8[1, 2], b = Int8[1, 4]), TrustOrdering(:a))
    @test map(aggregator(mean), by(ft, :a)) ≅ ft_mean # same as below
    @test map(ignoreindex(t -> Ref(map(mean, columns(t)))), by(ft, :a)) ≅ ft_mean
end
