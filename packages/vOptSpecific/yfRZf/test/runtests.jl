using vOptSpecific
@static if VERSION > v"0.7-"
	using Test
else
	using Base.Test
end
println("Testing 2LAP...")
C1 = [3 9 0 0 6 10 7 5 16 11 ;
16 0 6 12 19 8 17 10 9 18 ;
2 7 11 15 8 10 10 12 8 6 ;
4 11 7 16 3 13 18 11 11 7 ;
14 19 7 0 4 19 8 13 9 10 ;
11 4 17 14 19 5 16 2 17 4 ;
8 14 7 15 2 11 0 1 14 11 ;
8 8 3 15 8 7 14 9 0 16 ;
11 3 12 8 9 11 6 5 5 15 ;
2 5 1 9 0 4 12 13 5 6 ]

C2 = [16 5 6 19 12 7 18 19 16 10 ;
15 7 13 7 7 2 10 5 0 8 ;
1 2 13 2 3 6 6 16 19 3 ;
14 7 8 1 7 13 8 17 12 16 ;
8 19 15 1 18 14 16 8 0 8 ;
8 1 10 14 15 5 0 14 1 11 ;
9 16 10 10 9 17 3 17 15 15 ;
5 15 14 0 16 12 14 4 12 6 ;
12 1 19 14 15 15 0 7 1 13 ;
10 10 1 0 0 10 10 3 19 17 ]

id = set2LAP(10, C1, C2)
z1,z2,solutions = vSolve(id)

@test z1 == [18,19,28,35,43,54,66,22,26,34,51]
@test solutions[1,:] == [3, 2, 1, 5, 4, 10, 7, 9, 8, 6]

id = load2LAP("../examples/2AP10-1A100.dat")
z1,z2,solutions = vSolve(id)

@test z1 == [146, 155, 185, 271, 363, 478, 572, 149, 220, 267, 307, 402, 433]
@test solutions[1,:] == [6, 3, 7, 9, 2, 10, 1, 5, 4, 8]



println("\nTesting 2UKP...")
id = set2UKP([1,2,3], [4,5,6], [7,8,9], 16)
z1, z2, w, solutions = vSolve(id)

@test z1 == [4]
@test w == [16]
@test solutions == [[1, 0, 1]]

id = load2UKP("../examples/2KP500-1A.DAT")
z1, z2, w, solutions = vSolve(id)
@assert length(z1) == 1682
@assert extrema(z1) == (16028, 20360)
@assert allunique(solutions)


println("\nTesting 2UMFLP...")
id = load2UMFLP("../examples/F50-51.txt")
z1, z2, facility_res, X, isEdge = vSolve(id)
@test length(z1) == 198
@test count(!iszero, X[21]) == 91
@test count(isEdge) == 188


println("\nTesting 2OSP...")
id = set2OSP(4, [2, 4, 3, 1], [1, 2, 4, 6])
z1, z2 , S = vSolve(id)

for i = 1:length(S)
    println("(", z1[i], ", ", z2[i], ") : ", S[i])
end

@test z1 == [20, 21, 27]
@test z2 == [8, 6, 5]
@test S == [[4, 1, 3, 2], [4, 1, 2, 3], [1, 2, 3, 4]]
