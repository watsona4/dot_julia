
#created in including file
#comm = MPIComm{UInt64, UInt16, UInt32}()

pid = myPid(comm)

macro MPIMapTests()
    @test isa(map, BlockMap{UInt64, UInt16, UInt32})

    @test uniqueGIDs(map)

    for i = 1:5
        @test myLID(map, i)
        @test pid*5 + i - 5 == gid(map, i)
    end

    for i = 1:20
        if cld(i, 5) == pid
            @test myGID(map, i)
            @test (i-1)%5+1 == lid(map, i)
        else
            @test !myGID(map, i)
            @test 0 == lid(map, i)
        end
    end


    @test !myLID(map, -1)
    @test !myLID(map, 0)
    @test !myLID(map, 6)
    @test !myLID(map, 46)
    @test !myGID(map, -1)
    @test !myGID(map, 0)
    @test !myGID(map, 21)
    @test !myGID(map, 46)

    @test 0 == lid(map, -1)
    @test 0 == lid(map, 0)
    @test 0 == lid(map, 21)
    @test 0 == lid(map, 46)
    @test 0 == gid(map, -1)
    @test 0 == gid(map, 0)
    @test 0 == gid(map, 6)
    @test 0 == gid(map, 46)

    @test distributedGlobal(map)

    @test linearMap(map)

    @test 20 == numGlobalElements(map)
    @test 5 == numMyElements(map)

    @test pid*5 - 4 == minMyGID(map)
    @test pid*5 == maxMyGID(map)
    @test 1 == minAllGID(map)
    @test 20 == maxAllGID(map)
    @test 1 == minLID(map)
    @test 5 == maxLID(map)

    @test ([1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 3, 3, 3, 3, 3, 4, 4, 4, 4, 4],
            [1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5, 1, 2, 3, 4, 5]) == remoteIDList(map, collect(1:20))

    @test collect((1:5) .+ 5*(pid - 1)) == myGlobalElementIDs(map)
end

map = BlockMap(20, comm)
@MPIMapTests

map = BlockMap(20, 5, comm)
@MPIMapTests

map = BlockMap(5*numProc(comm), collect((1:5) .+ 5*(pid - 1)), comm)
@MPIMapTests
