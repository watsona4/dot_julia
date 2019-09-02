
#ensure multiple calls to MPIComm works
MPIComm(Bool, Bool, Bool)
MPIComm(UInt64, UInt16, UInt32)


@test 4 == numProc(comm)
@test isa(numProc(comm), UInt16)

@test 1 <= myPid(comm) <= 4
@test isa(myPid(comm), UInt16)

@test [1, 8] == broadcastAll(comm, [myPid(comm), 8], 1)
@test [2, 5] == broadcastAll(comm, [myPid(comm), 5], 2)
@test [3, 7] == broadcastAll(comm, [myPid(comm), 7], 3)
@test [4, 6] == broadcastAll(comm, [myPid(comm), 6], 4)

@test [1, 2, 3, 4] == gatherAll(comm, [myPid(comm)])
@test ([1, 2, 3, 2, 4, 6, 3, 6, 9, 4, 8, 12]
        == gatherAll(comm, [myPid(comm), myPid(comm)*2, myPid(comm)*3]))

#check for hangs and such, hard to test if all processes are at the same spot
barrier(comm)

@test [10] == sumAll(comm, [myPid(comm)])
@test [32, 12, 10, 8] == sumAll(comm, [8, 3, myPid(comm), 2])

@test [4] == maxAll(comm, [myPid(comm)])
@test [4, -1, 8] == maxAll(comm, [myPid(comm), -Int(myPid(comm)), 8])

@test [1] == minAll(comm, [myPid(comm)])
@test [1, -4, 6] == minAll(comm, [myPid(comm), -Int(myPid(comm)), 6])

@test [sum(1:myPid(comm))] == scanSum(comm, [myPid(comm)])
@test ([myPid(comm)*5, sum(-2:-2:(-2*Int(myPid(comm)))), myPid(comm)*3]
        == scanSum(comm, [5, -2*Int(myPid(comm)), 3]))

#test distributor

dist = createDistributor(comm)
@test isa(dist, Distributor{UInt64, UInt16, UInt32})

#check for error when not waiting
@test_throws InvalidStateError resolveWaits(dist)
@test_throws InvalidStateError resolveReverseWaits(dist)

@test 4 == createFromSends(dist, [1, 2, 3, 4])

resolvePosts(dist, [pid, 2*pid, 3*pid, 4*pid])
@test_throws InvalidStateError resolveReverseWaits(dist)
@test pid*[1, 2, 3, 4] == resolveWaits(dist)

#check for error when not waiting
@test_throws InvalidStateError resolveWaits(dist)
@test_throws InvalidStateError resolveReverseWaits(dist)

#test distributor when elements not blocked by processor
dist2 = createDistributor(comm)
@test 8 == createFromSends(dist, [1, 2, 3, 4, 1, 2, 3, 4])

@test (reduce(vcat, [[(pid-1)*5+j, (pid+3)*5+j] for j in 1:4]; init=[])
        == resolve(dist, [pid, 5+pid, 10+pid, 15+pid, 20+pid, 25+pid, 30+pid, 35+pid]))

#test distributore createFromRecvs
@test ([(pid-1)*5+j for j in 1:4], [1, 2, 3, 4]) == createFromRecvs(dist, [pid, 5+pid, 10+pid, 15+pid], [1, 2, 3, 4])
