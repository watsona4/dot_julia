using Rectangle

function tree_get_data(t::IntervalTree{K, V}) where {K, V}
    karr = Vector{Interval{K}}()
    varr = Vector{V}()
    
    arr = collect(Iterator(t))
    for p in arr
        push!(karr, p[1])
        push!(varr, p[2])
    end
    return karr, varr
end

function intervalvalidity(t::IntervalTree)
    it = Iterator(t)
    next = iterate(it)
    valid = false
    while next !== nothing
        d, n = next
        valid = isnil(t, n) ||
            (isnil(t, n.l) && isnil(t, n.r) && n.k.submax == n.k.i.hi)   ||
            (isnil(t, n.l) && n.k.submax == max(n.k.i.hi, n.r.k.submax)) ||
            (isnil(t, n.r) && n.k.submax == max(n.k.i.hi, n.l.k.submax)) ||
            (n.k.submax == max(n.k.i.hi, n.l.k.submax, n.r.k.submax))    || break
        next = iterate(it, n)
    end
    return valid
end

function intersectvalidity(t, res, q)
    arr = [i for i in collect(Iterator(t)) if Rectangle.overlaps(i[1], q)]
    println(length(arr), ":", length(res))
    return arr == res
end

@testset "Interval Trees" begin
    @test string(Interval(0, 1)) == "(0, 1)"
    @test string(Rectangle.IntervalKey(Interval(0, 1))) == "(0, 1, 1)"
    a = [(26, 26), (25, 30), (19, 20), (17, 20), (16, 21),
         (15, 23), (8, 9),   (6,  10), ( 5,  8), ( 0,  3)]
    
    t = IntervalTree{Int, Int}()

    @test isempty(t)

    for i=1:lastindex(a)
        insert!(t, a[i][1], a[i][2], i*10)
    end

    @test collect(Iterator(t)) ==
        [Interval(0, 3)=>100,   Interval(5, 8)=>90,   Interval(6, 10)=>80,
         Interval(8, 9)=>70,   Interval(15, 23)=>60, Interval(16, 21)=>50,
         Interval(17, 20)=>40, Interval(19, 20)=>30, Interval(25, 30)=>20,
         Interval(26, 26)=>10]
    @test !intersects(t, Interval(4, 4))
    @test intersects(t, Interval(7, 8))
    @test intersect(t, Interval(7, 18)) ==
        [Interval(5, 8)=>90,   Interval(6, 10)=>80, Interval(8, 9)=>70,
         Interval(15, 23)=>60, Interval(16, 21)=>50, Interval(17, 20)=>40]
    t[Interval(16, 21)] = 110
    @test 110 == t[Interval(16, 21)]
    @test intervalvalidity(t)
    @test parentvalidity(t)
    @test bstvalidity(t)
    @test rbvalidity(t)
    @test length(t) == 10
    @test !isempty(t)
    @test maximum(t) == (Interval(26,26)=>10)
    @test minimum(t) == (Interval(0, 3)=>100)
    data = tree_get_data(t)
    aa = [Interval(x...) for x in sort(a)]
    @test data[1] == aa
    @test delete!(t, Interval(16, 21)) == (Interval(16,21)=>110)
    @test delete!(t, Interval(100, 110)) === nothing
    @test intervalvalidity(t)
    @test parentvalidity(t)
    @test bstvalidity(t)
    @test rbvalidity(t)
    data = tree_get_data(t)
    @test sort(data[2]) == [10, 20, 30, 40, 60, 70, 80, 90, 100]
    empty!(t)
    @test isempty(t)

    @testset "Non-unique" begin
        t.unique = false
        n = 10000
        a = Vector{Interval{Int}}()
        for i = 1:n
            j = rand(1:1000)
            k = rand(j:1000)
            push!(a, Interval(j, k))
        end
        for i = 1:n
            insert!(t, a[i].lo, a[i].hi, i)
        end
        @test length(t) == n
        @test intervalvalidity(t)
        @test parentvalidity(t)
        @test bstvalidity(t)
        @test rbvalidity(t)

        qlo = rand(1:1000)
        qhi = rand(qlo:1000)
        res = intersect(t, Interval(qlo, qhi))

        @test intersectvalidity(t, res, Interval(qlo, qhi))
        
        for i = 1:div(n, 2)
            @assert delete!(t, a[i]) !== nothing
        end
        @test length(t) == div(n, 2)
        @test intervalvalidity(t)
        @test rbvalidity(t)
        @test parentvalidity(t)
        @test bstvalidity(t)

        for i = 1:div(n, 2)
            insert!(t, a[i].lo, a[i].hi, i)
        end
        @test length(t) == n
        @test intervalvalidity(t)
        @test rbvalidity(t)
        @test parentvalidity(t)
        @test bstvalidity(t)
    end
end
