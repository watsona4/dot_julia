
function basicDirectoryTests(comm::Comm{GID, PID, LID}) where {GID, PID, LID}
    n = 8
    nProc = numProc(comm)
    pid = myPid(comm)

    map = BlockMap(n*nProc, n, comm)

    dir = BasicDirectory{GID, PID, LID}(map)
    @test isa(dir, BasicDirectory{GID, PID, LID})

    dir = createDirectory(comm, map)
    @test isa(dir, BasicDirectory{GID, PID, LID})
    @test gidsAllUniquelyOwned(dir)
    @test (repeat(1:nProc, inner=n), repeat(1:n, outer=nProc)) == getDirectoryEntries(dir, map, Vector{GID}(1:n*nProc))
end
