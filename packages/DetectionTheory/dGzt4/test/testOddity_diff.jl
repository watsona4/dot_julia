using Test, DetectionTheory, HDF5

gridStep = 0.01

PC = collect((1/3)+gridStep: gridStep: 1-gridStep)
nPC = length(PC)
dpOddity = zeros(nPC)

for i=1:nPC
    dpOddity[i] = dprimeOddity(PC[i], "diff")
end

fid = h5open("table_oddity.h5", "r")
psi_dp = read(fid["dp"])

#@test_approx_eq_eps(dpOddity, psi_dp, 1e-4)
#@test dpOddity ≈ psi_dp atol=1e-4 nans=true


@test isequal(isnan.(dpOddity) .== true,  isnan.(psi_dp) .== true)
@test isequal(isinf.(dpOddity) .== true,  isinf.(psi_dp) .== true)

dpOddity_nonan = dpOddity[isnan.(dpOddity) .== false]
psi_dp_nonan = psi_dp[isnan.(psi_dp) .== false]

dpOddity_nonan_noinf = dpOddity_nonan[isinf.(dpOddity_nonan) .== false]
psi_dp_nonan_noinf = psi_dp_nonan[isinf.(psi_dp_nonan) .== false]

for i=1:length(dpOddity_nonan_noinf)
    @test abs(dpOddity_nonan_noinf[i] - psi_dp_nonan_noinf[i]) < 1e-4
end
