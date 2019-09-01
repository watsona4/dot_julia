using Test, DetectionTheory, HDF5

fName = "table_ABX.h5"

gridStep = 0.01
minHR = 0; maxHR=1


HR = collect(minHR:gridStep:maxHR)
n = round(Int, length(HR)*(length(HR)+1)/2)
dp_IO_arr = zeros(n); #dp_IO_arr[1:end] = NaN
dp_diff_arr = zeros(n); #dp_diff_arr[1:end] = NaN
HR_arr = zeros(n)
FAR_arr = zeros(n)

cnt = 1
for k=1:length(HR)
    thisHR = HR[k]
    FAR = collect(minHR:gridStep:thisHR)
    for l=1:length(FAR)
        thisFAR = FAR[l]
        HR_arr[cnt] = thisHR
        FAR_arr[cnt] = thisFAR
        global cnt = cnt+1
    end
end





for i=1:length(HR_arr)
    thisHR = HR_arr[i]; thisFAR = FAR_arr[i]
    try
        dp_IO_arr[i] = dprimeABX(thisHR, thisFAR, "IO")
    catch
        dp_IO_arr[i] = NaN
    end

    try
        dp_diff_arr[i] = dprimeABX(thisHR, thisFAR, "diff")
    catch
        dp_diff_arr[i] = NaN
    end
end


fid = h5open(fName, "r")
psi_dp_IO = read(fid["dp_IO"])
psi_dp_diff = read(fid["dp_diff"])


@test dp_IO_arr ≈ psi_dp_IO atol=1e-4 nans=true
@test dp_diff_arr ≈ psi_dp_diff atol=1e-4 nans=true

@test isequal(isnan.(dp_IO_arr) .== true,  isnan.(psi_dp_IO) .== true)
@test isequal(isinf.(dp_IO_arr) .== true,  isinf.(psi_dp_IO) .== true)

@test isequal(isnan.(dp_diff_arr) .== true,  isnan.(psi_dp_diff) .== true)
@test isequal(isinf.(dp_diff_arr) .== true,  isinf.(psi_dp_diff) .== true)


dp_IO_arr_nonan = dp_IO_arr[isnan.(dp_IO_arr) .== false]
psi_dp_IO_nonan = psi_dp_IO[isnan.(psi_dp_IO) .== false]

dp_diff_arr_nonan = dp_diff_arr[isnan.(dp_diff_arr) .== false]
psi_dp_diff_nonan = psi_dp_diff[isnan.(psi_dp_diff) .== false]

dp_IO_arr_nonan_noinf = dp_IO_arr_nonan[isinf.(dp_IO_arr_nonan) .== false]
psi_dp_IO_nonan_noinf = psi_dp_IO_nonan[isinf.(psi_dp_IO_nonan) .== false]

dp_diff_arr_nonan_noinf = dp_diff_arr_nonan[isinf.(dp_diff_arr_nonan) .== false]
psi_dp_diff_nonan_noinf = psi_dp_diff_nonan[isinf.(psi_dp_diff_nonan) .== false]

for i=1:length(dp_IO_arr_nonan_noinf)
    @test abs(dp_IO_arr_nonan_noinf[i] - psi_dp_IO_nonan_noinf[i]) < 1e-4
end

for i=1:length(dp_diff_arr_nonan_noinf)
    @test abs(dp_diff_arr_nonan_noinf[i] - psi_dp_diff_nonan_noinf[i]) < 1e-4
end



## dp_IO_arr_nonan = dp_IO_arr[isnan.(dp_IO_arr) .== false]
## psi_dp_IO_nonan = psi_dp_IO[isnan.(psi_dp_IO) .== false]

## dp_diff_arr_nonan = dp_diff_arr[isnan.(dp_diff_arr) .== false]
## psi_dp_diff_nonan = psi_dp_diff[isnan.(psi_dp_diff) .== false]

## for i=1:length(dp_IO_arr_nonan)
##     @test abs(dp_IO_arr_nonan[i] - psi_dp_IO_nonan[i]) < 1e-4
## end

## for i=1:length(dp_diff_arr_nonan)
##     @test abs(dp_diff_arr_nonan[i] - psi_dp_diff_nonan[i]) < 1e-4
## end
