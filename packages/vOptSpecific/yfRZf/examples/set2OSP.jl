using vOptSpecific

n =4 
p = [2, 4, 3, 1]
d = [1, 2, 4, 6]

id = set2OSP(n, p, d)
z1, z2 , S = vSolve(id) #Default solver is OSP_Van_Wassenhove1980()

for i = 1:length(S)
    println("(", z1[i], ", ", z2[i], ") : ", S[i])
end