
using JuliaPetra
using Test
using TypeStability

include("TestUtil.jl")

# function based tests
include("DenseMultiVectorTests.jl")
include("BasicDirectoryTests.jl")
include("LocalCommTests.jl")

#need access to MPI comm to ensure that tests only run on the root process
#use distinct types
GID = UInt64
PID = UInt16
LID = UInt32
comm = MPIComm(GID, PID, LID)

pid = myPid(comm)
nProcs = numProc(comm)

#only print errors from one process
if pid != 1
    #redirect_stdout()
    #redirect_stderr()
end


#tries are to allow barriers to work correctly, even under erronious situtations
try
    @testset "MPI Tests" begin
        try
            @testset "Comm MPI Tests" begin
                include("MPICommTests.jl")
                include("MPIBlockMapTests.jl")
                include("MPIimport-export Tests.jl")

                include("LocalCommTests.jl")
                runLocalCommTests(comm)

                include("BasicDirectoryTests.jl")
                basicDirectoryTests(comm)
            end

            @testset "Data MPI Tests" begin
                denseMultiVectorTests(comm)

                include("CSRMatrixMPITests.jl")
            end

        finally
            #print results sequentially
            for i in 1:pid
                barrier(comm)
            end
        end
        @info "process $pid test results:"
    end

finally
    #print results sequentially
    for i in pid:nProcs
        barrier(comm)
    end
end
