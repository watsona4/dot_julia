using Test
using ForestBiometrics

@test typeof(sdi_chart(500,8)) == Plots.Plot{Plots.GRBackend}
@test typeof(sdi_chart(500,8;maxsdi=600)) == Plots.Plot{Plots.GRBackend}
