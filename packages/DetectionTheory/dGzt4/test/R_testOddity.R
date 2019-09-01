library(psyphy)
library(rhdf5)

unlink("table_oddity.h5")
h5createFile("table_oddity.h5")

gridStep = 0.01
PC = seq((1/3)+gridStep, 1-gridStep, gridStep)

nPC = length(PC)
dpOddity = numeric(nPC)

for (i in 1:nPC){ 
    dpOddity[i] = dprime.oddity(PC[i])
}

h5write(dpOddity, "table_oddity.h5","dp")

