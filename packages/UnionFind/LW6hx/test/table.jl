function check(uf :: UnionFinder, groups :: Vector{Vector{Int}})
    # Check node count.

    if sum(length, groups) != length(uf)
        println("Found $(length(uf)), but expected $(sum(length, groups)).")
        return false
    end

    # Check that all nodes which should be in groups together are, in fact,
    # in groups together.

    for group in groups
        if !all(id -> find!(uf, id) == find!(uf, group[1]), group)
            ids = map(id -> find!(uf, id), group)
            println("Group $group has ids $ids.")
            return false
        elseif !all(id -> length(group) == size!(uf, id), group)
            sizes = map(id -> size!(uf, id), group)
            println("Group $group has sizes $sizes.")
            return false
        end
    end

    # Check uniqueness of groups.

    for i in 1:length(groups)
        for j in 1:length(groups)
            if i == j
                continue
            elseif find!(uf, groups[i][1]) == find!(uf, groups[j][1])
                println("Group $(groups[i]) and $(groups[j]) have same id.")
                return false
            end
        end
    end

    return true
end


function check(cf :: CompressedFinder, group_set :: Vector{Vector{Int}})
    # Check node count and group count.

    if sum(length, group_set) != length(cf)
        println("Found $(length(cf)), but expected $(sum(length, group_set)).")
        return false
    elseif length(group_set) != groups(cf)
        println("Expected $(length(groups)) groups, but got $(groups(cf)).")
        return false
    end

    # Check that all nodes which should be in groups together are, in fact,
    # in groups together.

    for group in group_set
        if !all(id -> find(cf, id) == find(cf, group[1]), group)
            ids = map(id -> find(cf, id), group)
            println("Group $group has ids $ids.")
            return false
        elseif find(cf, group[1]) <= 0 || find(cf, group[1]) > groups(cf)
            println("Group $group has invlaid id, $(find(cf, group[1]))")
            return false
        end
    end

    # Check uniqueness of groups.

    for i in 1:length(group_set)
        for j in 1:length(group_set)
            if i == j
                continue
            elseif find(cf, group_set[i][1]) == find(cf, group_set[j][1])
                println("Group $(group_set[i]) and $(group_set[j]) " + 
                        "have same id.")
                return false
            end
        end
    end

    return true
end


function sc_println(test_num :: Integer, uf :: UnionFinder)
    println("Test $test_num:")
    print("parents: [")
    for (i, id) in enumerate(uf.parents)
        print("$i: $id")
        if i != length(uf.parents)
            print(", ")
        end
    end
    println("]")

    print("sizes: [")
    for (i, size) in enumerate(uf.sizes)
        print("$i: $size")
        if i != length(uf.sizes)
            print(", ")
        end
    end
    println("]")

    return true
end


function sc_println(test_num :: Integer, cf :: CompressedFinder)
    println("Test $test_num:")
    print("ids: [")
    for (i, id) in enumerate(cf.ids)
        print("$i: $id")
        if i != length(cf.ids)
            print(", ")
        end
    end
    println("]")
    return true
end


tests = [# singleton
         (Int[], Int[], [[1]]),
         # self loop
         ([1], [1], [[1]]),
         # unconnected pair
         (Int[], Int[], [[1],[2]]),
         # connected pair
         ([1], [2], [[1,2]]),
         # floater
         ([1], [2], [[1,2],[3]]),
         # "V"
         ([1,2], [2,3], [[1,2,3]]),
         # triangle
         ([1,2,3], [3,1,2], [[1,2,3]]),
         # "Z": order 1
         ([1,2,3], [2,3,4], [[1,2,3,4]]),
         # "Z": order 2
         ([1,4,2], [2,3,3], [[1,2,3,4]]),
         # diamond
         ([1,2,4,3,1], [2,4,3,4,3], [[1,2,3,4]]),
         # K-5
         ([1,1,1,1], [2,3,4,5], [[1,2,3,4,5]]),
         ([2,2,2,2], [1,3,4,5], [[1,2,3,4,5]]),
         ([3,3,3,3], [1,2,4,5], [[1,2,3,4,5]]),
         ([4,4,4,4], [1,2,3,5], [[1,2,3,4,5]]),
         ([5,5,5,5], [1,2,3,4], [[1,2,3,4,5]]),
         # jewish star
         ([1,3,5,6,4,2], [3,5,1,2,6,4], [[1,3,5],[2,4,6]]),
         # barbell
         ([1,2,3,4,5,6,6], [2,3,1,5,6,4,3], [[1,2,3,4,5,6]])
         ]

function table_main()
    for (i, (us, vs, groups)) in enumerate(tests)
        uf = UnionFinder(sum(length, groups))
        union!(uf, us, vs)
        cf = CompressedFinder(uf)

        @test check(uf, groups) || !sc_println(i, uf)
        @test check(cf, groups) || !sc_println(i, cf)

        reset!(uf)
        for (u, v) in zip(us, vs)
            union!(uf, u, v)
        end

        @test check(uf, groups) || !sc_println(i, uf)

        reset!(uf)
        union!(uf, zip(us, vs))

        @test check(uf, groups) || !sc_println(i, uf)
    end
end

table_main()
