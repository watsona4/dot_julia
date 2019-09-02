using Kwant, PyPlot, PyCall
kwant = Kwant; pyplot = PyPlot


####
include("band_structure.jl")

lead = make_lead().finalized()
kwant.plotter.bands(lead, show=false)
pyplot.xlabel("momentum [(lattice constant)^-1]")
pyplot.ylabel("energy [t]")
pyplot.gcf()


####

include("closed_system.jl")

syst = make_system()

# Check that the system looks as intended.
kwant.plot(syst)

# Finalize the system.
system = syst.finalized()

# We should observe energy levels that flow towards Landau
# level energies with increasing magnetic field.
plot_spectrum(system, [iB * 0.002 for iB in range(0,length=(100-1))])

# Plot an eigenmode of a circular dot. Here we create a larger system for
# better spatial resolution.
system = make_system(r=20).finalized()

plot_wave_function(system)
plot_current(system)
