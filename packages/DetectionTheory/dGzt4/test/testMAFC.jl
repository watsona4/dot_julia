using Test, DetectionTheory, HDF5

gridStep = 0.01
PC = collect(0+gridStep:gridStep:1-gridStep)

nPC = length(PC)
alt = collect(2:1:10)
nAlt = length(alt)

dps = zeros(nAlt, nPC)

for i=1:nAlt
    for j=1:nPC
        dps[i,j] = dprimeMAFC(PC[j], alt[i])
    end
end

fid = h5open("table_mAFC.h5", "r")
psi_dp = read(fid["dp"])

#@test_approx_eq_eps(dps, psi_dp, 1e-3)
@test dps ≈ psi_dp atol=1e-3 nans=true


