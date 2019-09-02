using MPIFiles, PyPlot

filename = "../../../test/measurement_V2.mdf"
f = MPIFile(filename)

u = getMeasurementsFD(f, frames=1:100, numAverages=100)
figure(6, figsize=(6,4))
semilogy(abs.(u[1:400,1,1,1]))
savefig("../assets/spectrum1.png")
