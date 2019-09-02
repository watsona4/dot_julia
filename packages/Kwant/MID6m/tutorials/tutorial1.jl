import Kwant, PyPlot
kwant = Kwant; pyplot = PyPlot

include("quantum_wire.jl")

syst.attach_lead(right_lead)

# Plot it, to make sure it's OK
kwant.plot(syst)

# Finalize the system
syst = syst.finalized()

# Now that we have the system, we can compute conductance
energies = []
data = []
for ie in range(0,length=100)
    energy = ie * 0.01

    # compute the scattering matrix at a given energy
    smatrix = kwant.smatrix(syst, energy)

    # compute the transmission probability from lead 0 to
    # lead 1
    append!(energies,energy) ## CHANGE: note append!(energies,...) not energies.append(...)
    append!(data,smatrix.transmission(1, 0)) ## CHANGE: note append!(data,...) not data.append(...)
end

# Use matplotlib to write output
# We should see conductance steps
pyplot.figure()
pyplot.plot(energies, data)
pyplot.xlabel("energy [t]")
pyplot.ylabel("conductance [e^2/h]")
pyplot.gcf() ## note gcf not show
