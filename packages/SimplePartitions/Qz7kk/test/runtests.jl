using Test
using SimplePartitions
using Permutations

@testset "Set Partitions" begin
n = 20
p = RandomPermutation(n)
P = Partition(p)
@test P >= Partition(p*p')
@test length(cycles(p)) == num_parts(P)
@test num_elements(P) == n
@test ground_set(P) == Set(1:n)


Plist = collect(parts(P))
for A in Plist
    @test in(A,P)
end

@test P == PartitionBuilder(parts(P))

P = Partition(n)
for k=1:n-1
    merge_parts!(P,k,k+1)
end
@test num_parts(P) == 1

@test length(all_partitions(Set(1:4))) == 15

P = Partition(RandomPermutation(10))
Q = Partition(RandomPermutation(10))

@test P ∧ Q <= P
@test P ∨ Q >= Q

end  # end testset

@testset "Integer Partitions" begin

p = IntegerPartition(1,2,3)
@test sum(p)==6
@test p' == p
@test sum(p+p) == 2*sum(p)

p = IntegerPartition(5)
@test string(p) == "(5)"
@test parts(p') == ones(Int,5)

end # end testset
