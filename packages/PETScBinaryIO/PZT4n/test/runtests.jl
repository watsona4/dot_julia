using PETScBinaryIO
using Test
using SparseArrays

function idempotent_io(int_type, scalar_type, itype_check, stype_check)
    try
        itype, stype = if int_type == nothing
            PETScBinaryIO.parse_petsc_config()
        else
            int_type, scalar_type
        end
        A = rand(stype, 1000)
        B = sprand(stype, 1000,1000,0.1)
        C = rand(itype, 1000)
        writepetsc("vec.petsc", [A, B, C]; int_type=int_type, scalar_type=scalar_type)
        AA, BB, CC = readpetsc("vec.petsc"; int_type=int_type, scalar_type=scalar_type)
        AA == A && BB == B && CC == C && eltype(A) == stype_check && eltype(C) == itype_check
    finally
        if isfile("vec.petsc")
            rm("vec.petsc")
        end
    end
end

@testset "Test Suite" begin
    @testset "Idempotent IO" begin
        for itype in [Int32, Int64]
            for stype in [Float32, Float64]
                @testset "$itype $stype" begin
                    @test idempotent_io(itype, stype, itype, stype)
                end

                @testset "$itype $stype config" begin
                    withenv("PETSC_DIR" => pwd(), "PETSC_ARCH" => "arch-i$(sizeof(itype) * 8)-f$(sizeof(stype) * 8)") do
                        @test idempotent_io(nothing, nothing, itype, stype)
                    end
                end
            end
        end
    end

    @testset "Parse Config" begin
        for itype in [Int32, Int64]
            for stype in [Float32, Float64]
                @testset "$itype $stype config" begin
                    withenv("PETSC_DIR" => pwd(), "PETSC_ARCH" => "arch-i$(sizeof(itype) * 8)-f$(sizeof(stype) * 8)") do
                        @test PETScBinaryIO.parse_petsc_config() == (itype, stype)
                    end
                end
            end
        end
    end
end
