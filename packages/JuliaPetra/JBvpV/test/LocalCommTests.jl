
function runLocalCommTests(origComm::Comm{GID, PID, LID}) where{GID, PID, LID}
    localComm = LocalComm(origComm)
    
    @test_throws InvalidStateError barrier(localComm)
    @test_throws InvalidStateError broadcastAll(localComm, [1, 2, 3], 1)
    @test_throws InvalidStateError broadcastAll(localComm, 18, 1)
    @test_throws InvalidStateError createDistributor(localComm)
    
    
    @test_throws InvalidStateError gatherAll(localComm, [4, 5, 6, 7])
    @test_throws InvalidStateError gatherAll(localComm, 8)
    
    @test_throws InvalidStateError sumAll(localComm, [4, 5, 6, 7])
    @test_throws InvalidStateError sumAll(localComm, 8)
    
    @test_throws InvalidStateError minAll(localComm, [4, 5, 6, 7])
    @test_throws InvalidStateError minAll(localComm, 8)
    
    @test_throws InvalidStateError maxAll(localComm, [4, 5, 6, 7])
    @test_throws InvalidStateError maxAll(localComm, 8)
    
    @test_throws InvalidStateError scanSum(localComm, [4, 5, 6, 7])
    @test_throws InvalidStateError scanSum(localComm, 8)
        
    
    @test myPid(origComm) == myPid(localComm)
    @test numProc(origComm) == numProc(localComm)
end