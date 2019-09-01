using Test, DetectionTheory, DelimitedFiles

#test DetectionTheory.jl results against d-prime oddity table in Macmillan & Creelman
dats, datsHead = readdlm("dprime_oddity_table.txt", ' ', header=true)
dats=dats[2:end,:]

n = size(dats)[1]
dpDiffJulia = zeros(n)
dpIOJulia = zeros(n)

for i=1:n
    dpDiffJulia[i] = dprimeOddity(dats[i,2], "diff")
    dpIOJulia[i] =  dprimeOddity(dats[i,3], "IO")
end

dpDiffJulia = round.(dpDiffJulia, digits=1)
dpIOJulia = round.(dpIOJulia, digits=1)

## @test_approx_eq_eps(dpDiffJulia, dats[:,1], 1e-4)
## @test_approx_eq_eps(dpIOJulia, dats[:,1], 1e-4)
## @test dpDiffJulia ≈ dats[:,1] atol=1e-4 nans=true
## @test dpIOJulia ≈ dats[:,1] atol=1e-4 nans=true

@test isequal(dpDiffJulia, dats[:,1])
@test isequal(dpIOJulia, dats[:,1])
