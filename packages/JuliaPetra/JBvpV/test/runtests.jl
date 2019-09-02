
using JuliaPetra
using Test
using TypeStability

include("TestUtil.jl")

#function based tests
include("DenseMultiVectorTests.jl")
include("BasicDirectoryTests.jl")
include("LocalCommTests.jl")

@testset "Serial tests" begin

    #a generic serial comm for the tests that need to be called with a comm object
    comm = SerialComm{UInt64, UInt16, UInt32}()

    @testset "Util Tests" begin
        include("UtilsTests.jl")
    end

    @testset "Comm Tests" begin
        include("SerialCommTests.jl")
        include("Import-Export Tests.jl")
        include("BlockMapTests.jl")

        runLocalCommTests(serialComm)

        basicDirectoryTests(serialComm)
    end

    @testset "Data Structure Tests" begin
        denseMultiVectorTests(serialComm)

        include("SparseRowViewTests.jl")
        include("LocalCSRGraphTests.jl")
        include("LocalCSRMatrixTests.jl")

        include("CSRGraphTests.jl")
        include("CSRMatrixTests.jl")
    end
end


code = """
    $(Base.load_path_setup_code(false))
    cd("$(pwd())")
    include("mpi-runtests.jl")
"""

run(```
    mpiexec -n 4
        $(Base.julia_cmd())
        --code-coverage=$(Bool(Base.JLOptions().code_coverage) ? "user" : "none")
        --color=$(Base.have_color ? "yes" : "no")
        --compiled-modules=$(Bool(Base.JLOptions().use_compiled_modules) ? "yes" : "no")
        --check-bounds=yes
        --startup-file=$(Base.JLOptions().startupfile == 1 ? "yes" : "no")
        --track-allocation=$(("none", "user", "all")[Base.JLOptions().malloc_log + 1])
        --eval $code
```)
