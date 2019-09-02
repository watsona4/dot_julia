using Kwant, PyPlot, PyCall
kwant = Kwant; pyplot = PyPlot


include("graphene.jl")

pot = 0.1
syst, leads = make_system(pot=pot)

# To highlight the two sublattices of graphene, we plot one with
# a filled, and the other one with an open circle:
py"""
    def family_colors(site):
        return 0 if site.family == $(a.o) else 1
    """

# Plot the closed system without leads.
kwant.plot(syst, site_color=py"family_colors", site_lw=0.1, colorbar=false)

# Compute some eigenvalues.
compute_evs(syst.finalized())

    # Attach the leads to the system.
for lead in leads
    syst.attach_lead(lead)
end

    # Then, plot the system with leads.
kwant.plot(syst, site_color=py"family_colors", site_lw=0.1,
           lead_site_lw=0, colorbar=false)

# Finalize the system.
system = syst.finalized()

    # Compute the band structure of lead 0.
momenta = [-pi + 0.02 * pi * i for i in range(0,length=101)]
plot_bandstructure(system.leads[1], momenta)

# Plot conductance.
energies = [-2 * pot + 4. / 50. * pot * i for i in range(0,length=51)]
plot_conductance(system, energies)
