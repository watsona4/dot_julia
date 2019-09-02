# Changes from original file:
#   pyimport tinyarray
#   range(A) -> range(0,length=A)
#   A.append(...) -> append!(A,...)

tinyarray = pyimport("tinyarray")
    sigma_0 = tinyarray.array([[1, 0], [0, 1]])
    sigma_x = tinyarray.array([[0, 1], [1, 0]])
    sigma_y = tinyarray.array([[0, -1im], [1im, 0]])
    sigma_z = tinyarray.array([[1, 0], [0, -1]])


function make_system(t=1.0, alpha=0.5, e_z=0.08, W=10, L=30)
    # Start with an empty tight-binding system and a single square lattice.
    # `a` is the lattice constant (by default set to 1 for simplicity).
    lat = kwant.lattice.square()

    syst = kwant.Builder()

    #### Define the scattering region. ####
    syst[[lat(x, y) for x in range(0,length=L) for y in range(0,length=W)]] =
        4 * t * sigma_0 + e_z * sigma_z # note [...] for comprehension and 1:L/W for range(L/W) also no \ for line break
    # hoppings in x-direction
    syst[kwant.builder.HoppingKind((1, 0), lat, lat)] =
        -t * sigma_0 + 1im * alpha * sigma_y / 2 ## note 1im not 1j
    # hoppings in y-directions
    syst[kwant.builder.HoppingKind((0, 1), lat, lat)] =
        -t * sigma_0 - 1im * alpha * sigma_x / 2

    #### Define the left lead. ####
    lead = kwant.Builder(kwant.TranslationalSymmetry((-1, 0)))

    lead[[lat(0, j) for j in range(0,length=W)]] = 4 * t * sigma_0 + e_z * sigma_z
    # hoppings in x-direction
    lead[kwant.builder.HoppingKind((1, 0), lat, lat)] =
        -t * sigma_0 + 1im * alpha * sigma_y / 2
    # hoppings in y-directions
    lead[kwant.builder.HoppingKind((0, 1), lat, lat)] =
        -t * sigma_0 - 1im * alpha * sigma_x / 2

    #### Attach the leads and return the finalized system. ####
    syst.attach_lead(lead)
    syst.attach_lead(lead.reversed())

    return syst
end


function plot_conductance(syst, energies)
    # Compute conductance
    data = []
    for energy in energies
        smatrix = kwant.smatrix(syst, energy)
        append!(data,smatrix.transmission(1, 0))
    end

    pyplot.figure()
    pyplot.plot(energies, data)
    pyplot.xlabel("energy [t]")
    pyplot.ylabel("conductance [e^2/h]")
    pyplot.gcf() ## note gcf not show
end
