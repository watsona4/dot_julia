
#computeOffsets
rowPtrs = Array{Int, 1}(undef, 30)
JuliaPetra.computeOffsets(rowPtrs, 9)
@test collect(1:9:9*30) == rowPtrs

rowPtrs = Array{Int, 1}(undef, 30)
numEnts = collect(1:29)
@test sum(1:29) == JuliaPetra.computeOffsets(rowPtrs, numEnts)
@test [sum(numEnts[1:i-1])+1 for i = 1:30] == rowPtrs

@test_throws InvalidArgumentError JuliaPetra.computeOffsets(rowPtrs, Array{Int, 1}(undef, 30))
@test_throws InvalidArgumentError JuliaPetra.computeOffsets(rowPtrs, Array{Int, 1}(undef, 31))
@test_throws InvalidArgumentError JuliaPetra.computeOffsets(rowPtrs, Array{Int, 1}(undef, 42))
