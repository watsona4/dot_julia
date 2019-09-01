library(psyphy)
library(rhdf5)
t1 = Sys.time()

fName = "table_ABX.h5"

gridStep = 0.01
minHR = 0; maxHR=1

try(file.remove(fName))
HR = seq(minHR, maxHR, gridStep) #hit rate values for which d' should be computed
n = length(HR)*(length(HR)+1)/2
HR_arr = numeric(n)
FAR_arr = numeric(n)
dp_IO_arr = numeric(n)
dp_diff_arr = numeric(n)
HR_arr[] = NaN
FAR_arr[] = NaN
dp_IO_arr[] = NaN
dp_diff_arr[] = NaN

cnt = 1
for (k in 1:length(HR)){
    thisHR = HR[k]
    FAR = seq(minHR, thisHR, gridStep)
    for (l in 1:length(FAR)){
        thisFAR = FAR[l]
        HR_arr[cnt] = thisHR
        FAR_arr[cnt] = thisFAR
        cnt = cnt+1
    }
}

for (i in 1:length(HR_arr)){
    thisHR = HR_arr[i]; thisFAR = FAR_arr[i]
    dp_diff = try(dprime.ABX(thisHR, thisFAR, method="diff"), silent=T)

    if (class(dp_diff) == "try-error"){
        print(paste("diff", thisHR, thisFAR, sep=" "))
    } else {
        dp_diff_arr[i] = dp_diff
    }

    dp_IO = try(dprime.ABX(thisHR, thisFAR, method="IO"), silent=T)
    if (class(dp_IO) == "try-error"){
        print(paste("IO", thisHR, thisFAR, sep=" "))
    } else {
        dp_IO_arr[i] = dp_IO
    }
}
       

h5createFile(fName)
h5write(HR_arr, fName,"HR")
h5write(FAR_arr, fName,"FA")
h5write(dp_diff_arr, fName,"dp_diff")
h5write(dp_IO_arr, fName,"dp_IO")
        
t2 = Sys.time()
print(t2-t1)
