using ProperOrthogonalDecomposition
using Test
using Random
using Statistics
using Pkg
using DelimitedFiles

# Define test matrix X with dimensions n×m, where n is number of data poitns and
# m is the number of snapshots
# W is the weight matrix representing the cell volume

Random.seed!(1)
X = rand(1000,10)
X .+= 10
Random.seed!(1)
W = rand(1:0.2:10,1000)

@testset "Standard POD" begin

    PODbase, Σ = POD(X)
    PODbaseEig, Σeig = PODeigen(X)
    PODbaseSvd, Σsvd = PODsvd(X)

    meanPODbaseEig, meanΣeig = PODeigen(copy(X), subtractmean = true)
    meanPODbaseSvd, meanΣsvd = PODsvd(copy(X), subtractmean = true)

    Σ₁ = 1050.362168606664
    Σ₂ = 8.301301177004774
    meanΣ₁ = 9.878480670625322
    meanΣ₂ = 8.30589586913458

    @testset "POD using eigenvalue decomposition" begin
        @test Σeig[1] ≈ Σ₁
        @test Σeig[end] ≈ Σ₂
        @test meanΣeig[1] ≈ meanΣ₁
        @test meanΣeig[end-1] ≈ meanΣ₂

    end

    @testset "POD using SVD" begin
        @test Σsvd[1] ≈ Σ₁
        @test Σsvd[end] ≈ Σ₂
        @test meanΣsvd[1] ≈ meanΣ₁
        @test meanΣsvd[end-1] ≈ meanΣ₂
    end

    @testset "Default method" begin
        @test maximum(abs.(abs.(PODbaseSvd.coefficients) .- abs.(PODbase.coefficients))) ≈ 0 atol=1e-8
        @test maximum(abs.(abs.(PODbaseSvd.modes) .- abs.(PODbase.modes))) ≈ 0 atol=1e-8
        @test maximum(abs.(Σsvd.-Σ)) ≈ 0 atol=1e-8
    end

    @testset "Method equality of SVD and Eig" begin
        @test maximum(abs.(abs.(PODbaseSvd.coefficients) .- abs.(PODbaseEig.coefficients))) ≈ 0 atol=1e-8
        @test maximum(abs.(abs.(PODbaseSvd.modes) .- abs.(PODbaseEig.modes))) ≈ 0 atol=1e-8
        @test maximum(abs.(abs.(meanPODbaseSvd.coefficients) .- abs.(meanPODbaseEig.coefficients))) ≈ 0 atol=1e-7
        @test maximum(abs.(abs.(meanPODbaseSvd.modes[:,1:end-1]) .- abs.(meanPODbaseEig.modes[:,1:end-1]))) ≈ 0 atol=1e-7
        @test maximum(abs.(Σeig.-Σsvd)) ≈ 0 atol=1e-8
    end

    @testset "Rebuild solution" begin
        @test PODbaseEig.modes*PODbaseEig.coefficients ≈ X
        @test PODbaseSvd.modes*PODbaseSvd.coefficients ≈ X
        @test meanPODbaseEig.modes*meanPODbaseEig.coefficients ≈ X .- mean(X,dims=2)
        @test meanPODbaseSvd.modes*meanPODbaseSvd.coefficients ≈ X .- mean(X,dims=2)
    end
end

@testset "Weighted POD" begin

    PODbase, Σ = POD(X, W)
    PODbaseEig, Σeig = PODeigen(X,W)
    PODbaseSvd, Σsvd = PODsvd(X,W)

    meanPODbaseEig, meanΣeig = PODeigen(copy(X), W, subtractmean = true)
    meanPODbaseSvd, meanΣsvd = PODsvd(copy(X), W, subtractmean = true)

    Σ₁ = 2445.2807019537136
    Σ₂ = 19.41742998859931
    meanΣ₁ = 23.11141372908026
    meanΣ₂ = 19.444770050580598

    @testset "POD using eigenvalue decomposition" begin
        @test Σeig[1] ≈ Σ₁
        @test Σeig[end] ≈ Σ₂
        @test meanΣeig[1] ≈ meanΣ₁
        @test meanΣeig[end-1] ≈ meanΣ₂

    end

    @testset "POD using SVD" begin
        @test Σsvd[1] ≈ Σ₁
        @test Σsvd[end] ≈ Σ₂
        @test meanΣsvd[1] ≈ meanΣ₁
        @test meanΣsvd[end-1] ≈ meanΣ₂
    end

    @testset "Default method with weights" begin
        @test maximum(abs.(abs.(PODbaseSvd.coefficients) .- abs.(PODbase.coefficients))) ≈ 0 atol=1e-8
        @test maximum(abs.(abs.(PODbaseSvd.modes) .- abs.(PODbase.modes))) ≈ 0 atol=1e-8
        @test maximum(abs.(Σsvd.-Σ)) ≈ 0 atol=1e-8
    end

    @testset "Method equality of SVD and Eig with weights" begin
        @test maximum(abs.(abs.(PODbaseSvd.coefficients) .- abs.(PODbaseEig.coefficients))) ≈ 0 atol=1e-8
        @test maximum(abs.(abs.(PODbaseSvd.modes) .- abs.(PODbaseEig.modes))) ≈ 0 atol=1e-8
        @test maximum(abs.(Σeig.-Σsvd)) ≈ 0 atol=1e-8
    end

    @testset "Rebuild solution with weights" begin
        @test PODbaseEig.modes*PODbaseEig.coefficients ≈ X
        @test PODbaseSvd.modes*PODbaseSvd.coefficients ≈ X
    end
end

@testset "Mode convergence" begin
    A = [   0.010197212000627108 0.007070856617510225 0.004345509205119795 0
            0.6179627074745591 0.5476731024048103 0.12030902309667643 0
            1.377162205777348 0.8636384160114929 0.3197534098872419 0   ]
    Amean =[0.6322816398505274 0.5534565187905752 0.13120270384723295 0
            1.3821479511006756 0.8593667661723656 0.3083628970324381 0
            1.3536726312063883 1.1047589549024917 0.9957138077649103 0  ]
    W₂ = ones(1000)

    pkgpath = abspath(joinpath(dirname(Base.find_package("ProperOrthogonalDecomposition")), ".."))
    testdataPath = joinpath(pkgpath, "test","testdata.csv")

    @testset "Convergence of number of included snapshots" begin
        
        @test modeConvergence(X,PODeigen,[1:4,1:6,1:8,1:10],3) ≈ A
        @test modeConvergence(X,PODsvd,[1:4,1:6,1:8,1:10],3) ≈ A
        @test modeConvergence!(()->readdlm(testdataPath, ','),PODeigen!,[1:4,1:6,1:8,1:10],3) ≈ A
        @test modeConvergence!(()->readdlm(testdataPath, ','),PODsvd!,[1:4,1:6,1:8,1:10],3) ≈ A

    end

    @testset "Convergence of number of included snapshots with one weights" begin
        
        @test modeConvergence(X,x->PODeigen(x,W₂),[1:4,1:6,1:8,1:10],3) ≈ A
        @test modeConvergence(X,x->PODsvd(x,W₂),[1:4,1:6,1:8,1:10],3) ≈ A
        @test modeConvergence!(()->readdlm(testdataPath, ','),x->PODeigen!(x,W₂),[1:4,1:6,1:8,1:10],3) ≈ A
        @test modeConvergence!(()->readdlm(testdataPath, ','),x->PODsvd!(x,W₂),[1:4,1:6,1:8,1:10],3) ≈ A

    end

end
