using GenomicVectors
using Test

# write your own tests here
test_files = [
              "test_utils.jl"
              ,"test_GenomeInfo.jl"
              ,"test_GenomicPositions.jl"
              ,"test_GenomicRanges.jl"
              ]

println("Testing ...")
for f in test_files
    println(f)
    include(f)
end
println("Done testing.")
