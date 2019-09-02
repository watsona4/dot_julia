using PyPlot, PyCall, Revise
using Kwant
kwant = Kwant; pyplot = PyPlot

include("superconductor.jl")

syst = make_system(W=10)

# Check that the system looks as intended.
kwant.plot(syst)

# Finalize the system.
system = syst.finalized()



# Check particle-hole symmetry of the scattering matrix
check_PHS(system)

# Compute and plot the conductance
plot_conductance(system, energies=[0.002 * i for i in range(-10, stop=100)])
