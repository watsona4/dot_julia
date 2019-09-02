
### test Serial Comm ###

serialComm = SerialComm{Int, Int, Int}()
@test typeof(serialComm) == SerialComm{Int, Int, Int}
@test typeof(SerialComm{Int, Int, Int}()) == SerialComm{Int, Int, Int}

io = IOBuffer()
show(io, serialComm)
@test "SerialComm{$(String(Symbol(Int))),$(String(Symbol(Int))),$(String(Symbol(Int)))} with PID 1 and 1 processes" == String(take!(io))

# ensure no errors or hangs
barrier(serialComm)

@test_throws InvalidArgumentError broadcastAll(serialComm, [1, 2, 3], 2)
@test [1, 2, 3] == broadcastAll(serialComm, [1, 2, 3], 1)
@test ['a', 'b', 'c'] == broadcastAll(serialComm, ['a', 'b', 'c'], 1)

@test [1, 2, 3] == gatherAll(serialComm, [1, 2, 3])
@test ['a', 'b', 'c'] == gatherAll(serialComm, ['a', 'b', 'c'])

@test [1, 2, 3] == sumAll(serialComm, [1, 2, 3])
@test ['a', 'b', 'c'] == sumAll(serialComm, ['a', 'b', 'c'])

@test [1, 2, 3] == maxAll(serialComm, [1, 2, 3])
@test ['a', 'b', 'c'] == maxAll(serialComm, ['a', 'b', 'c'])

@test [1, 2, 3] == minAll(serialComm, [1, 2, 3])
@test ['a', 'b', 'c'] == minAll(serialComm, ['a', 'b', 'c'])

@test [1, 2, 3] == scanSum(serialComm, [1, 2, 3])
@test ['a', 'b', 'c'] == scanSum(serialComm, ['a', 'b', 'c'])

@test 1 == myPid(serialComm)
@test 1 == numProc(serialComm)

serialDistributor = createDistributor(serialComm)
@test typeof(serialDistributor) <: Distributor


### test Serial Distributor ###

@test_throws InvalidArgumentError createFromSends(serialDistributor, [1, 1, 1, 2])
@test_throws InvalidArgumentError createFromSends(serialDistributor, [1, 1, 2, 1])
@test_throws InvalidArgumentError createFromSends(serialDistributor, [2, 1, 1])
@test 1 == createFromSends(serialDistributor, [1])
@test 2 == createFromSends(serialDistributor, [1, 1])
@test 5 == createFromSends(serialDistributor, [1, 1, 1, 1, 1])
@test 8 == createFromSends(serialDistributor, [1, 1, 1, 1, 1, 1, 1, 1])


@test_throws InvalidArgumentError createFromRecvs(serialDistributor, [1, 2, 3, 4], [1, 1, 1, 2])
@test_throws InvalidArgumentError createFromRecvs(serialDistributor, [1, 2, 3, 4, 5], [2, 1, 1, 1, 1])
@test_throws InvalidArgumentError createFromRecvs(serialDistributor, [1, 2, 3, 4, 5, 6], [1, 1, 1, 2, 1, 1])
@test ([2], [1]) == createFromRecvs(serialDistributor, [2], [1])
@test ([2, 3, 4, 5], [1, 1, 1, 1]) == createFromRecvs(serialDistributor, [2, 3, 4, 5], [1, 1, 1, 1])


@test [3] == resolve(serialDistributor, [3])
@test [3, 4, 5, 6, 7, 8, 9, 10] == resolve(serialDistributor, [3, 4, 5, 6, 7, 8, 9, 10])
@test ['a', 'b', 'c', 'd'] == resolve(serialDistributor, ['a', 'b', 'c', 'd'])


@test [4] == resolveReverse(serialDistributor, [4])
@test [11, 4, 5, 6, 7, 8, 9, 10] == resolveReverse(serialDistributor, [11, 4, 5, 6, 7, 8, 9, 10])
@test ['a', 'b', 'c', 'k'] == resolveReverse(serialDistributor, ['a', 'b', 'c', 'k'])

@test_throws InvalidStateError resolveWaits(serialDistributor)
@test_throws InvalidStateError resolveReverseWaits(serialDistributor)

resolvePosts(serialDistributor, [1, 2, 3])
resolvePosts(serialDistributor, [6, 7, 8, 9])
@test [6, 7, 8, 9] == resolveWaits(serialDistributor)
@test_throws InvalidStateError resolveWaits(serialDistributor)

resolveReversePosts(serialDistributor, [11, 12, 13])
resolveReversePosts(serialDistributor, [16, 17, 81, 19])
@test [16, 17, 81, 19] == resolveReverseWaits(serialDistributor)
@test_throws InvalidStateError resolveReverseWaits(serialDistributor)
