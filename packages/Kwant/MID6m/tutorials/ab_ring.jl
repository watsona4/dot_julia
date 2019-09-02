# the need to define python functions is a bit annoying, and against
# the spirit of the package, however, the amount of work necessary to implement
# a pure-julia interface is quite high.
#
# for now I am satisfied that likat 95% of kwant constructions so far
# have a pure-julia interface (i.e. no need to use PyCall directly)

function make_system(a=1, t=1.0, W=10, r1=10, r2=20)
    # Start with an empty tight-binding system and a single square lattice.
    # `a` is the lattice constant (by default set to 1 for simplicity).

    lat = kwant.lattice.square(a)

    syst = kwant.Builder()

    #### Define the scattering region. ####
    # Now, we aim for a more complex shape, namely a ring (or annulus)
    function ring(pos)
        (x, y) = pos
        rsq = x^2 + y^2
        return (r1^2 < rsq < r2^2)
    end

    # and add the corresponding lattice points using the `shape`-function
    syst[lat.shape(ring, (0, r1 + 1))] = 4 * t
    syst[lat.neighbors()] = -t

    # In order to introduce a flux through the ring, we introduce a phase on
    # the hoppings on the line cut through one of the arms.  Since we want to
    # change the flux without modifying the Builder instance repeatedly, we
    # define the modified hoppings as a function that takes the flux as its
    # parameter phi.
    py"""
    def hopping_phase_py(site1, site2, phi):
        return -$t * $exp(1j * phi)
    """

    py"""
    def crosses_branchcut_py(hop):
        ix0, iy0 = hop[0].tag
        # builder.HoppingKind with the argument (1, 0) below
        # returns hoppings ordered as ((i+1, j), (i, j))
        return iy0 < 0 and ix0 == 1  # ix1 == 0 then implied
    """
    # Modify only those hopings in x-direction that cross the branch cut
    py"""
    import kwant
    def hops_across_cut_py(syst):
        for hop in kwant.builder.HoppingKind((1, 0), $(lat.o), $(lat.o))(syst):
            if crosses_branchcut_py(hop):
                yield hop
    """
    syst[py"hops_across_cut_py"] = py"hopping_phase_py"

    #### Define the leads. ####
    # left lead
    sym_lead = kwant.TranslationalSymmetry((-a, 0))
    lead = kwant.Builder(sym_lead)

    function lead_shape(pos)
        (x,y) = pos
        return (-W / 2 < y < W / 2)
    end

    lead[lat.shape(lead_shape, (0, 0))] = 4 * t
    lead[lat.neighbors()] = -t

    #### Attach the leads and return the system. ####
    syst.attach_lead(lead)
    syst.attach_lead(lead.reversed())

    return syst
end



function plot_conductance(syst; energy, fluxes)
    # compute conductance

    normalized_fluxes = [flux / (2 * pi) for flux in fluxes]
    data = []
    for flux in fluxes
        smatrix = kwant.smatrix(syst, energy, params=Dict(:phi=>flux))
        append!(data,smatrix.transmission(1, 0))
    end

    pyplot.figure()
    pyplot.plot(normalized_fluxes, data)
    pyplot.xlabel("flux [flux quantum]")
    pyplot.ylabel("conductance [e^2/h]")
    pyplot.gcf()
end
