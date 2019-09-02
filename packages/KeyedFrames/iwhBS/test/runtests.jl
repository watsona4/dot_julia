using KeyedFrames
using DataFrames
using Test

@testset "KeyedFrames" begin
    df1 = DataFrame(; a=1:10, b=2:11, c=3:12)
    df2 = DataFrame(; a=1:5, d=4:8)
    df3 = DataFrame(; a=[4, 2, 1], e=[2, 5, 2], f=1:3)

    @testset "constructor" begin
        kf1 = KeyedFrame(df1, [:a, :b])
        @test KeyedFrames.frame(kf1) === df1
        @test keys(kf1) == [:a, :b]

        kf2 = KeyedFrame(df2, :a)
        @test KeyedFrames.frame(kf2) === df2
        @test keys(kf2) == [:a]

        kf3 = KeyedFrame(df3, ["e", "a"])
        @test KeyedFrames.frame(kf3) === df3
        @test keys(kf3) == [:e, :a]

        @test_throws ArgumentError KeyedFrame(df1, [:a, :b, :d])
        @test_throws ArgumentError KeyedFrame(df1, :d)

        @test keys(KeyedFrame(df1, [:a, :a, :b, :a])) == [:a, :b]
    end

    kf1 = KeyedFrame(df1, [:a, :b])
    kf2 = KeyedFrame(df2, :a)
    kf3 = KeyedFrame(df3, ["e", "a"])

    @testset "equality" begin
        cp = deepcopy(kf1)
        cpd = deepcopy(df1)

        @test kf1 == kf1
        @test isequal(kf1, kf1)
        @test hash(kf1) == hash(kf1)

        @test kf1 == cp
        @test isequal(kf1, cp)
        @test hash(kf1) == hash(cp)

        @test kf1 == KeyedFrame(cpd, [:a, :b])
        @test isequal(kf1, KeyedFrame(cpd, [:a, :b]))
        @test hash(kf1) == hash(KeyedFrame(cpd, [:a, :b]))

        @test kf1 == KeyedFrame(cpd, [:b, :a])
        @test !isequal(kf1, KeyedFrame(cpd, [:b, :a]))
        @test hash(kf1) != hash(KeyedFrame(cpd, [:b, :a]))

        @test kf1 == df1
        @test df1 == kf1
        @test !isequal(kf1, df1)
        @test !isequal(df1, kf1)
        @test hash(kf1) != hash(df1)

        @test kf1 != KeyedFrame(cpd, [:a, :b, :c])
        @test !isequal(kf1, KeyedFrame(cpd, [:a, :b, :c]))
        @test hash(kf1) != hash(KeyedFrame(cpd, [:a, :b, :c]))

        @test kf2 != KeyedFrame(df3, :a)
        @test !isequal(kf2, KeyedFrame(df3, :a))
        @test hash(kf2) != hash(KeyedFrame(df3, :a))
    end

    @testset "copy" begin
        @test kf1 == deepcopy(kf1)
        @test kf1 !== deepcopy(kf1)
        @test DataFrame(kf1) !== DataFrame(deepcopy(kf1))
        @test keys(kf1) !== keys(deepcopy(kf1))
    end

    @testset "convert" begin
        for (kf, df) in [(kf1, df1), (kf2, df2), (kf3, df3)]
            @test convert(DataFrame, kf) == df
            @test DataFrame(kf) == df
            @test SubDataFrame(kf, 1:3, :) == SubDataFrame(df, 1:3, :)
        end
    end

    @testset "size" begin
        for (kf, df) in [(kf1, df1), (kf2, df2), (kf3, df3)]
            @test nrow(kf) == nrow(df)
            @test ncol(kf) == ncol(df)
            @test size(kf) == size(df)
        end
    end

    @testset "names/index/key" begin
        for (kf, df) in [(kf1, df1), (kf2, df2), (kf3, df3)]
            @test KeyedFrames.names(kf) == DataFrames.names(df)
            @test KeyedFrames.index(kf) == DataFrames.index(df)
            @test keys(kf) == keys(kf)
        end
    end

    @testset "getindex" begin
        @test isequal(kf1[:], kf1)
        @test isequal(kf1[:, :], kf1)

        @test isequal(kf1[1, :], KeyedFrame(DataFrame(; a=1, b=2, c=3), [:a, :b]))
        @test isequal(kf1[8:10, :], KeyedFrame(DataFrame(; a=8:10, b=9:11, c=10:12), [:a, :b]))

        @test isequal(kf1[1:2], KeyedFrame(DataFrame(; a=1:10, b=2:11), [:a, :b]))
        @test isequal(kf1[[:a, :b]], KeyedFrame(DataFrame(; a=1:10, b=2:11), [:a, :b]))

        @test isequal(kf1[1, [:a, :b]], KeyedFrame(DataFrame(; a=1, b=2), [:a, :b]))
        @test isequal(kf1[8:10, 1:2], KeyedFrame(DataFrame(; a=8:10, b=9:11), [:a, :b]))

        @test isequal(kf1[:, 1:2], KeyedFrame(DataFrame(; a=1:10, b=2:11), [:a, :b]))
        @test isequal(kf1[:, [:a, :b]], KeyedFrame(DataFrame(; a=1:10, b=2:11), [:a, :b]))

        # When :a column disappears it is removed from the key
        @test isequal(kf1[2:3], KeyedFrame(DataFrame(; b=2:11, c=3:12), :b))
        @test isequal(kf1[[:b, :c]], KeyedFrame(DataFrame(; b=2:11, c=3:12), :b))

        @test isequal(kf1[:, 2:3], KeyedFrame(DataFrame(; b=2:11, c=3:12), :b))
        @test isequal(kf1[:, [:b, :c]], KeyedFrame(DataFrame(; b=2:11, c=3:12), :b))

        # Returns a column/value instead of a KeyedFrame
        @test isequal(kf1[1, :a], 1)
        @test isequal(kf1[8:10, 1], [8, 9, 10])

        @test isequal(kf1[:, :b], collect(2:11))
        @test isequal(kf1[:, 2], collect(2:11))
    end

    @testset "setindex!" begin
        cp = deepcopy(kf1)
        cp[:b] = collect(11:20)     # Need to collect on a setindex! with DataFrames.
        @test isequal(cp, KeyedFrame(DataFrame(; a=1:10, b=11:20, c=3:12), [:a, :b]))

        cp = deepcopy(kf1)
        cp[:b] = 3
        @test isequal(cp, KeyedFrame(DataFrame(; a=1:10, b=3, c=3:12), [:a, :b]))

        cp = deepcopy(kf1)
        cp[2] = 3
        @test isequal(cp, KeyedFrame(DataFrame(; a=1:10, b=3, c=3:12), [:a, :b]))

        cp = deepcopy(kf1)
        cp[[:b, :c]] = 3
        @test isequal(cp, KeyedFrame(DataFrame(; a=1:10, b=3, c=3), [:a, :b]))

        cp = deepcopy(kf1)
        cp[2:3] = 3
        @test isequal(cp, KeyedFrame(DataFrame(; a=1:10, b=3, c=3), [:a, :b]))

        cp = deepcopy(kf2)
        cp[1, :d] = 10
        @test isequal(cp, KeyedFrame(DataFrame(; a=1:5, d=[10, 5, 6, 7, 8]), :a))

        cp = deepcopy(kf2)
        cp[1, 1:2] = 10
        @test isequal(cp, KeyedFrame(DataFrame(;a=[10, 2, 3, 4, 5],d=[10, 5, 6, 7, 8]), :a))
    end

    @testset "first/last" begin
        # Don't assume that n will always equal 6
        @test first(kf1) isa KeyedFrame
        @test isequal(first(kf1, 1), kf1[1, :])
        @test isequal(first(kf1, 3), kf1[1:3, :])
        @test isequal(first(kf1, 6), kf1[1:6, :])

        @test last(kf1) isa KeyedFrame
        @test isequal(last(kf1, 1), kf1[end, :])
        @test isequal(last(kf1, 3), kf1[end - 2:end, :])
        @test isequal(last(kf1, 6), kf1[end - 5:end, :])
    end

    @testset "sort" begin
        # No columns specified (sort by key)
        expected = KeyedFrame(DataFrame(; a=[1, 4, 2], e=[2, 2, 5], f=[3, 1, 2]), [:e, :a])
        reversed = KeyedFrame(DataFrame(; a=[2, 4, 1], e=[5, 2, 2], f=[2, 1, 3]), [:e, :a])

        @test sort(kf3) == expected
        @test sort(kf3; rev=true) == reversed

        cp = deepcopy(kf3)
        @test sort!(cp) == expected
        @test cp == expected

        cp = deepcopy(kf3)
        @test sort!(cp; rev=true) == reversed
        @test cp == reversed

        @test issorted(kf1)
        @test !issorted(kf3)
        @test issorted(expected)
        @test !issorted(reversed)
        @test issorted(reversed; rev=true)

        # Columns specified
        expected = KeyedFrame(DataFrame(; a=[1, 2, 4], e=[2, 5, 2], f=[3, 2, 1]), [:e, :a])
        reversed = KeyedFrame(DataFrame(; a=[4, 2, 1], e=[2, 5, 2], f=[1, 2, 3]), [:e, :a])

        @test sort(kf3, :a) == expected
        @test sort(kf3, :a; rev=true) == reversed

        cp = deepcopy(kf3)
        @test sort!(cp, :a) == expected
        @test cp == expected

        cp = deepcopy(kf3)
        @test sort!(cp, :a; rev=true) == reversed
        @test cp == reversed

        @test !issorted(expected)
        @test issorted(expected, :a)
        @test !issorted(reversed)
        @test !issorted(reversed, :a)
        @test issorted(reversed, :a; rev=true)

        # Test return type of `sort!`
        @test isa(sort!(deepcopy(kf3), :a), KeyedFrame)
    end

    @testset "push!" begin
        cp = deepcopy(kf2)

        push!(cp, [6, 9])
        @test cp == KeyedFrame(DataFrame(; a=1:6, d=4:9), :a)

        # Test return type of `push!`
        @test isa(push!(deepcopy(kf2), [6, 9]), KeyedFrame)
    end

    @testset "append!" begin
        cp = deepcopy(kf2)
        append!(cp, DataFrame(; a=6:8, d=9:11))
        @test cp == KeyedFrame(DataFrame(; a=1:8, d=4:11), :a)

        # With append! we discard the key from the second KeyedFrame, which I think is fine.
        cp = deepcopy(kf2)
        append!(cp, KeyedFrame(DataFrame(; a=6:8, d=9:11), [:a, :d]))
        @test cp == KeyedFrame(DataFrame(; a=1:8, d=4:11), :a)

        # Test return type of `append!`
        @test isa(
            append!(deepcopy(kf2), KeyedFrame(DataFrame(; a=6:8, d=9:11), [:a, :d])),
            KeyedFrame
        )
    end

    @testset "deleterows!" begin
        cp = deepcopy(kf1)
        deleterows!(cp, 1)
        @test cp == KeyedFrame(DataFrame(; a=2:10, b=3:11, c=4:12), [:a, :b])

        cp = deepcopy(kf1)
        deleterows!(cp, 1:4)
        @test cp == KeyedFrame(DataFrame(; a=5:10, b=6:11, c=7:12), [:a, :b])

        cp = deepcopy(kf1)
        deleterows!(cp, [1, 10])
        @test cp == KeyedFrame(DataFrame(; a=2:9, b=3:10, c=4:11), [:a, :b])

        # Test return type of `deleterows!`
        @test isa(deleterows!(deepcopy(kf1), 1), KeyedFrame)
    end
    
    @testset "deletecols!" begin
        for ind in (:b, 2, [:b], [2])
            cp = deepcopy(kf1)
            deletecols!(cp, ind)
            @test cp == KeyedFrame(DataFrame(; a=1:10, c=3:12), [:a])
        end
        for ind in ([:a, :c], [1, 3])
            cp = deepcopy(kf1)
            deletecols!(cp, ind)
            @test cp == KeyedFrame(DataFrame(; b=2:11), [:b])
        end
        for ind in ([:a, :b], [1, 2])
            cp = deepcopy(kf1)
            deletecols!(cp, ind)
            @test cp == KeyedFrame(DataFrame(; c=3:12), Symbol[])
        end
        for ind in (:d, 4, [:a, :d], [1, 4])
            cp = deepcopy(kf1)
            @test_throws Exception deletecols!(cp, ind)
        end

        # Test return type of `deletecols!`
        @test isa(deletecols!(deepcopy(kf1), :b), KeyedFrame)
    end

    @testset "rename" begin
        initial = copy(kf1)
        expected = KeyedFrame(DataFrame(; new_a=1:10, b=2:11, new_c=3:12), [:new_a, :b])

        @test rename(initial, :a => :new_a, :c => :new_c) == expected
        @test initial == kf1
        @test rename(initial, [:a => :new_a, :c => :new_c]) == expected
        @test initial == kf1
        @test rename(initial, Dict(:a => :new_a, :c => :new_c)) == expected
        @test initial == kf1
        @test rename(x -> x == :b ? x : Symbol("new_$x"), initial) == expected
        @test initial == kf1

        @test rename!(initial, :a => :new_a, :c => :new_c) == expected
        @test initial == expected
        initial = copy(kf1)
        @test rename!(initial, [:a => :new_a, :c => :new_c]) == expected
        @test initial == expected
        initial = copy(kf1)
        @test rename!(initial, Dict(:a => :new_a, :c => :new_c)) == expected
        @test initial == expected
        initial = copy(kf1)
        @test rename!(x -> x == :b ? x : Symbol("new_$x"), initial) == expected
        @test initial == expected
    end

    @testset "unique" begin
        kf4 = KeyedFrame(DataFrame(; a=[1, 2, 3, 1, 2], b=[1, 2, 3, 4, 2], c=1:5), [:a, :b])

        @test nonunique(kf4) == [false, false, false, false, true]
        @test nonunique(kf4, :a) == [false, false, false, true, true]

        # Use default columns (key)
        expected = KeyedFrame(DataFrame(; a=[1, 2, 3, 1], b=1:4, c=1:4), [:a, :b])
        @test isequal(unique(kf4), expected)
        cp = deepcopy(kf4)
        unique!(cp)
        @test isequal(cp, expected)

        # Specify columns
        expected = KeyedFrame(DataFrame(; a=1:3, b=1:3, c=1:3), [:a, :b])
        @test isequal(unique(kf4, :a), expected)
        cp = deepcopy(kf4)
        unique!(cp, :a)
        @test isequal(cp, expected)

        # Test return type of `unique!`
        @test isa(unique!(deepcopy(kf1)), KeyedFrame)
        @test isa(unique!(deepcopy(kf1), :a), KeyedFrame)
    end

    @testset "join" begin
        expected = KeyedFrame(DataFrame(; a=1:5, b=2:6, c=3:7, d=4:8), [:a, :b])
        @test isequal(join(kf1, kf2), expected)
        @test isequal(join(kf1, df2), expected)               # Join a KeyedFrame and a DF
        @test isequal(join(df1, kf2), DataFrame(expected))    # Join a DF and a KeyedFrame

        @test isequal(join(kf1, kf2; kind=:right), expected)
        @test isequal(join(kf1, df2; kind=:right), expected)
        @test isequal(join(df1, kf2; kind=:right), DataFrame(expected))

        expected = KeyedFrame(DataFrame(; a=1:5, d=4:8, b=2:6, c=3:7), [:a, :b])
        @test isequal(join(kf2, kf1; kind=:left), expected)
        expected = KeyedFrame(DataFrame(; a=1:5, d=4:8, b=2:6, c=3:7), [:a])
        @test isequal(join(kf2, df1; kind=:left), expected)
        @test isequal(join(df2, kf1; kind=:left), DataFrame(expected))

        expected = KeyedFrame(
            DataFrame(; a=1:10, b=2:11, c=3:12, d=[4:8; fill(missing, 5)]), [:a, :b]
        )
        @test isequal(join(kf1, kf2; kind=:outer), expected)
        @test isequal(join(kf1, df2; kind=:outer), expected)
        @test isequal(join(df1, kf2; kind=:outer), DataFrame(expected))

        @test isequal(join(kf1, kf2; kind=:left), expected)
        @test isequal(join(kf1, df2; kind=:left), expected)
        @test isequal(join(df1, kf2; kind=:left), DataFrame(expected))

        expected = KeyedFrame(
            DataFrame(; a=1:10, d=[4:8; fill(missing, 5)], b=2:11, c=3:12), [:a, :b]
        )
        @test isequal(join(kf2, kf1; kind=:right), expected)
        expected = KeyedFrame(
            DataFrame(; a=1:10, d=[4:8; fill(missing, 5)], b=2:11, c=3:12), :a
        )
        @test isequal(join(kf2, df1; kind=:right), expected)
        expected = DataFrame(; a=1:10, d=[4:8; fill(missing, 5)], b=2:11, c=3:12)
        @test isequal(join(df2, kf1; kind=:right), expected)

        expected = KeyedFrame(DataFrame(; a=1:5, b=2:6, c=3:7), [:a, :b])
        @test isequal(join(kf1, kf2; kind=:semi), expected)
        @test isequal(join(kf1, df2; kind=:semi), expected)
        @test isequal(join(df1, kf2; kind=:semi), DataFrame(expected))

        expected = KeyedFrame(DataFrame(; a=1:5, d=4:8), :a)
        @test isequal(join(kf2, kf1; kind=:semi), expected)
        @test isequal(join(kf2, df1; kind=:semi), expected)
        @test isequal(join(df2, kf1; kind=:semi), DataFrame(expected))

        expected = KeyedFrame(DataFrame(; a=6:10, b=7:11, c=8:12), [:a, :b])
        @test isequal(join(kf1, kf2; kind=:anti), expected)
        @test isequal(join(kf1, df2; kind=:anti), expected)
        @test isequal(join(df1, kf2; kind=:anti), DataFrame(expected))

        expected = KeyedFrame(DataFrame(; a=[], d=[]), :a)
        @test isequal(join(kf2, kf1; kind=:anti), expected)
        @test isequal(join(kf2, df1; kind=:anti), expected)
        @test isequal(join(df2, kf1; kind=:anti), DataFrame(expected))

        expected = KeyedFrame(
            DataFrame(; a=[1, 2, 4], d=[4, 5, 7], e=[2, 5, 2], f=[3, 2, 1]), [:a, :e]
        )
        @test isequal(join(kf2, kf3), expected)

        expected = KeyedFrame(
            DataFrame(;
                a=[1, 2, 3, 4, 5, 4, 1],
                d=[4, 5, 6, 7, 8, 2, 2],
                f=[missing, 2, missing, missing, missing, 1, 3],
            ),
            :a,     # Key :e disappears, because it's renamed :d by the join
        )
        @test isequal(join(kf2, kf3; on=[:a => :a, :d => :e], kind=:outer), expected)
    end

    @testset "permutecols!" begin
        cp = deepcopy(kf1)
        permutecols!(cp, [1, 3, 2])

        @test isequal(cp, KeyedFrame(DataFrame(; a=1:10, c=3:12, b=2:11), [:a, :b]))
        permutecols!(cp, [2, 3, 1])
        @test isequal(cp, KeyedFrame(DataFrame(; c=3:12, b=2:11, a=1:10), [:a, :b]))

        @test_throws Exception permutecols!(cp, [1, 3])
        @test_throws Exception permutecols!(cp, [1, 2, 3, 4])

        # Test return type of `permutecols!`
        @test isa(permutecols!(deepcopy(kf1), [1, 2, 3]), KeyedFrame)
    end
end
