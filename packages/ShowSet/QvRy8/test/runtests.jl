using Test
using ShowSet

A = BitSet([1,3,9])
@test string(A) == "{1,3,9}"

B = Set{String}()
push!(B,"Hello")
push!(B,"Bye")
@test "{Bye,Hello}" == string(B)
