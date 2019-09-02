# Major changes from original:
#   range(A) -> range(0,length=A) range syntax
#   (lat(i,j) for i ... for j...) -> [lat(i,j) for i ... for j...], comprehension syntax
#   pyplot.show() -> pyplot.gcf() or import PyPlot and use that
#   onsite potential function must be defined as pythong function using py"""..."""
#       with L, L_well, t interpolated, and passed as py"...",
#   A.append(...) -> append!(A,...)

function make_system(a=1, t=1.0, W=10, L=30, L_well=10)
    # Start with an empty tight-binding system and a single square lattice.
    # `a` is the lattice constant (by default set to 1 for simplicity.
    lat = kwant.lattice.square(a)

    syst = kwant.Builder()

    #### Define the scattering region. ####
    # Potential profile
    # note that passing functions is tricky -- haven't yet figured out how to do it
    # easiest way is to define python functions directly and pass them
    py"""
    def potential(site, pot):
        (x, y) = site.pos
        if ($L - $L_well) / 2 < x < ($L + $L_well) / 2:
            return pot
        else:
            return 0

    def onsite(site, pot):
            return 4 * $t + potential(site, pot)
    """

    syst[[lat(x, y) for x in range(0,length=L) for y in range(0,length=W)]] = py"onsite"
    syst[lat.neighbors()] = -t

    #### Define and attach the leads. ####
    lead = kwant.Builder(kwant.TranslationalSymmetry((-a, 0)))
    lead[[lat(1, j) for j in range(0,length=W)]] = 4 * t ## note [lat...] not (lat...) for comprehension
    lead[lat.neighbors()] = -t
    syst.attach_lead(lead)
    syst.attach_lead(lead.reversed())

    return syst
end


function plot_conductance(syst, energy, welldepths)

    # Compute conductance
    data = []
    for welldepth in welldepths
        smatrix = kwant.smatrix(syst, energy, params=Dict(:pot=>-welldepth)) # note Dict(:pot=>) not dict(pot=)
        append!(data,smatrix.transmission(1, 0)) ## note append! not data.append
    end

    pyplot.figure()
    pyplot.plot(welldepths, data)
    pyplot.xlabel("well depth [t]")
    pyplot.ylabel("conductance [e^2/h]")
    pyplot.gcf() ## note gcf not show
end
