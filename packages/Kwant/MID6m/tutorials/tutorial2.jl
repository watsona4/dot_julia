using Revise, PyPlot, PyCall
using Kwant
kwant = Kwant; pyplot = PyPlot

######### SPIN ORBIT ############

include("spin_orbit.jl")

syst = make_system()

# Check that the system looks as intended.
kwant.plot(syst)

# Finalize the system.
system = syst.finalized()

# We should see non-monotonic conductance steps.
plot_conductance(system, [0.01 * i - 0.3 for i in range(0,length=100)])
# CHANGE from oringal: energies not specified as keyword


######### QUANTUM WELL ############
include("quantum_well.jl")

syst = make_system()

# Check that the system looks as intended.
kwant.plot(syst)

# Finalize the system.
system = syst.finalized()

# We should see conductance steps.
plot_conductance(system, 0.2, [0.01 * i for i in 0:100-1]) ## note 1:100 not range(100)


################# AHARONOV-BOHM RING ################
include("ab_ring.jl")

syst = make_system()

# Check that the system looks as intended.
kwant.plot(syst)

# Finalize the system.
system = syst.finalized()

# We should see a conductance that is periodic with the flux quantum
plot_conductance(system, energy=0.15, fluxes=[0.01*i*3*2pi for i in range(0,length=100-1)])
