using vOptSpecific

length(ARGS) != 1 && error("run julia parseLAP.jl filename")
!isfile(ARGS[1]) && error("can't find $(ARGS[1])")

id = load2LAP(ARGS[1])
z1, z2, solutions = vSolve(id)

for i = 1:length(z1)
    println("(" , z1[i], " | ", z2[i], ") : ", solutions[i,:])
end