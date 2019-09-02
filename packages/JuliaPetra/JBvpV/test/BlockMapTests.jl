#### Test BlockMap with SerialComm ####

function SerialMapTests(map::BlockMap{Int, Int, Int}, map2::BlockMap{Int, Int, Int}, diffMap::BlockMap{Int, Int, Int})
#    quote
        mapCopy = BlockMap{Int, Int, Int}(map.data)

        @test uniqueGIDs(map)

        for i = 1:5
            @test myLID(map, i)
            @test myGID(map, i)
            @test i == lid(map, i)
            @test i == gid(map, i)
        end

        @test !myLID(map, -1)
        @test !myLID(map, 0)
        @test !myLID(map, 6)
        @test !myLID(map, 30)
        @test !myGID(map, -1)
        @test !myGID(map, 0)
        @test !myGID(map, 6)
        @test !myGID(map, 30)

        @test 0 == lid(map, -1)
        @test 0 == lid(map, 0)
        @test 0 == lid(map, 6)
        @test 0 == lid(map, 30)
        @test 0 == gid(map, -1)
        @test 0 == gid(map, 0)
        @test 0 == gid(map, 6)
        @test 0 == gid(map, 30)

        @test !distributedGlobal(map)

        @test 5 == numGlobalElements(map)
        @test 5 == numMyElements(map)

        @test 1 == minMyGID(map)
        @test 5 == maxMyGID(map)
        @test 1 == minAllGID(map)
        @test 5 == maxAllGID(map)
        @test 1 == minLID(map)
        @test 5 == maxLID(map)

        @test ([1, 1, 1, 1, 1], [1, 2, 3, 4, 5]) == remoteIDList(map, [1, 2, 3, 4, 5])

        @test [1, 2, 3, 4, 5] == myGlobalElements(map)

        @test sameBlockMapDataAs(map, mapCopy)
        @test sameBlockMapDataAs(mapCopy, map)
        @test !sameBlockMapDataAs(map, map2)
        @test !sameBlockMapDataAs(map2, map)
        @test !sameBlockMapDataAs(map, diffMap)
        @test !sameBlockMapDataAs(diffMap, map)

        @test sameAs(map, mapCopy)
        @test sameAs(mapCopy, map)
        @test sameAs(map, map2)
        @test sameAs(map2, map)
        @test !sameAs(map, diffMap)
        @test !sameAs(diffMap, map)
        @test !sameAs(map2, diffMap)
        @test !sameAs(diffMap, map2)

        @test linearMap(map)

        @test [1, 2, 3, 4, 5] == myGlobalElementIDs(map)

        @test commVal == getComm(map)
#    end
end

commVal = SerialComm{Int, Int, Int}()


## constructor 1 ##
@test_throws InvalidArgumentError BlockMap(-8, commVal)
@test_throws InvalidArgumentError BlockMap(-1, commVal)

BlockMap(0, commVal)
BlockMap(1, commVal)

map = BlockMap(5, commVal)
map2 = BlockMap(5, commVal)
diffMap = BlockMap(6, commVal)
#@SerialMapTests
SerialMapTests(map, map2, diffMap)

## constructor 2 ##
@test_throws InvalidArgumentError BlockMap(-8, 4, commVal)
@test_throws InvalidArgumentError BlockMap(-2, 4, commVal)
@test_throws InvalidArgumentError BlockMap(5, -6, commVal)
@test_throws InvalidArgumentError BlockMap(4, -1, commVal)

BlockMap(0, 0, commVal)
BlockMap(1, 1, commVal)

map = BlockMap(5, 5, commVal)
map2 = BlockMap(5, 5, commVal)
diffMap = BlockMap(6, 6, commVal)
#@SerialMapTests
SerialMapTests(map, map2, diffMap)

map = BlockMap(-1, 5, commVal)
map2 = BlockMap(-1, 5, commVal)
diffMap = BlockMap(-1, 6, commVal)
#@SerialMapTests
SerialMapTests(map, map2, diffMap)


## constructor 3 ##
BlockMap(0, Int[], commVal)
BlockMap(1, [1], commVal)

map = BlockMap(5, [1, 2, 3, 4, 5], commVal)
map2 = BlockMap(5, [1, 2, 3, 4, 5], commVal)
diffMap = BlockMap(6, [1, 2, 3, 4, 5, 6], commVal)
#@SerialMapTests
SerialMapTests(map, map2, diffMap)

## constructor 4 ##
@test_throws InvalidArgumentError BlockMap(-8, 4, [1, 2, 3, 4], false, 1, 4, commVal)
@test_throws InvalidArgumentError BlockMap(-2, 4, [1, 2, 3, 4], false, 1, 4, commVal)
@test_throws InvalidArgumentError BlockMap(5, -6, [1, 2, 3, 4, 5], false, 1, 5, commVal)
@test_throws InvalidArgumentError BlockMap(4, -1, [1, 2, 3, 4], false, 1, 4, commVal)

BlockMap(0, 0, Int[], false, 1, 0, commVal)
BlockMap(1, 1, [1], false, 1, 1, commVal)

map = BlockMap(5, 5, [1, 2, 3, 4, 5], false, 1, 5, commVal)
map2 = BlockMap(5, 5, [1, 2, 3, 4, 5], false, 1, 5, commVal)
diffMap = BlockMap(6, 6, [1, 2, 3, 4, 5, 6], false, 1, 6, commVal)
#@SerialMapTests
SerialMapTests(map, map2, diffMap)


#stability tests
for (GID, PID, LID) in Base.product(stableGIDs, stablePIDs, stableLIDs)
        @test is_stable(check_method(gid, (BlockMap{GID, PID, LID}, LID)))
        @test is_stable(check_method(lid, (BlockMap{GID, PID, LID}, GID)))
        @test is_stable(check_method(myGID, (BlockMap{GID, PID, LID}, GID)))
        @test is_stable(check_method(myLID, (BlockMap{GID, PID, LID}, LID)))
        @test is_stable(check_method(numGlobalElements, (BlockMap{GID, PID, LID},)))
        @test is_stable(check_method(numMyElements, (BlockMap{GID, PID, LID},)))
end
