using RunLengthArrays
using Test

empty_array = RunLengthArray{Int,String}()
@test isempty(empty_array)

##################################################################################

original = Int8[3, 3, 3, 7, 7, 7, 7, 7, 7, 4]
compressed = RunLengthArray{Int,Int8}(original)

@test runs(compressed) == Int[3, 6, 1]
@test values(compressed) == Int8[3, 7, 4]

##################################################################################
# Check that looping works

total = Int8(0)
for elem in compressed
    global total
    total += elem
end
@test total == sum(original)

##################################################################################
# Check that the original array and the compressed array behave identically

@test length(compressed) == length(original)
@test sum(compressed) == sum(original)

for i in eachindex(original)
    @test compressed[i] == original[i]
end
@test compressed[end] == 4

@test collect(compressed) == original

##################################################################################
# Modify the two arrays and check that they are still identical

push!(compressed, Int8(4))
push!(original, 4)
@test length(compressed) == length(original)
@test sum(compressed) == sum(original)

push!(compressed, (4, Int8(6)))
append!(original, Int8[6, 6, 6, 6])
@test length(compressed) == length(original)
@test sum(compressed) == sum(original)

for i in eachindex(original)
    @test compressed[i] == original[i]
end

append!(compressed, Int8[3, 4, 5])
append!(original, Int8[3, 4, 5])

for i in eachindex(original)
    @test compressed[i] == original[i]
end

@test minimum(compressed) == minimum(original)
@test maximum(compressed) == maximum(original)
@test extrema(compressed) == extrema(original)

##################################################################################
# Finally, check that sorting works

@test collect(sort(compressed)) == sort(original)

sort!(compressed)
@test collect(compressed) == sort(original)
