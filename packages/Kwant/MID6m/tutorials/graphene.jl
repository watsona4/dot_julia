# Tutorial 2.5. Beyond square lattices: graphene
# ==============================================
#
# Physics background
# ------------------
#  Transport through a graphene quantum dot with a pn-junction
#
# Kwant features highlighted
# --------------------------
#  - Application of all the aspects of tutorials 1-3 to a more complicated
#    lattice, namely graphene


# For computing eigenvalues
sla = pyimport("scipy.sparse.linalg")

# For plotting


# Define the graphene lattice
sin_30, cos_30 = (1 / 2, sqrt(3) / 2)
graphene = kwant.lattice.general([(1, 0), (sin_30, cos_30)],
                                 [(0, 0), (0, 1 / sqrt(3))])
a, b = kwant.lattice.Monatomic.(graphene.sublattices)


function make_system(;r=10, w=2.0, pot=0.1)

    #### Define the scattering region. ####
    # circular scattering region
    function circle(pos)
        x, y = pos
        return hypot(x,y) < r
    end

    syst = kwant.Builder()

    # w: width and pot: potential maximum of the p-n junction
    py"""
    def potential(site):
        (x, y) = site.pos
        d = y * $cos_30 + x * $sin_30
        return $pot * $tanh(d / $w)
    """

    syst[graphene.shape(circle, (0, 0))] = py"potential"

    # specify the hoppings of the graphene lattice in the
    # format expected by builder.HoppingKind
    hoppings = (((0, 0), a, b), ((0, 1), a, b), ((-1, 1), a, b))
    syst[[kwant.builder.HoppingKind(hopping) for hopping in hoppings]] = -1

    # Modify the scattering region
    deleteat!(syst,a(0,0))
    syst[a(-2, 1), b(2, 2)] = -1

    #### Define the leads. ####
    # left lead
    sym0 = kwant.TranslationalSymmetry(graphene.vec((-1, 0)))

    function lead0_shape(pos)
        x, y = pos
        return (-0.4 * r < y < 0.4 * r)
    end

    lead0 = kwant.Builder(sym0)
    lead0[graphene.shape(lead0_shape, (0, 0))] = -pot
    lead0[[kwant.builder.HoppingKind(hopping) for hopping in hoppings]] = -1

    # The second lead, going to the top right
    sym1 = kwant.TranslationalSymmetry(graphene.vec((0, 1)))

    function lead1_shape(pos)
        v = pos[2] * sin_30 - pos[1] * cos_30
        return (-0.4 * r < v < 0.4 * r)
    end

    lead1 = kwant.Builder(sym1)
    lead1[graphene.shape(lead1_shape, (0, 0))] = pot
    lead1[[kwant.builder.HoppingKind(hopping) for hopping in hoppings]] = -1

    return syst, [lead0, lead1]
end


function compute_evs(syst)
    # Compute some eigenvalues of the closed system
    sparse_mat = syst.hamiltonian_submatrix(sparse=true)

    evs = sla.eigs(sparse_mat, 2)[1]
    print(real(evs))
end


function plot_conductance(syst, energies)
    # Compute transmission as a function of energy
    data = []
    for energy in energies
        smatrix = kwant.smatrix(syst, energy)
        append!(data,smatrix.transmission(0, 1))
    end

    pyplot.figure()
    pyplot.plot(energies, data)
    pyplot.xlabel("energy [t]")
    pyplot.ylabel("conductance [e^2/h]")
    pyplot.gcf()
end


function plot_bandstructure(flead, momenta)
    bands = kwant.physics.Bands(flead)
    energies = [bands(k) for k in momenta]

    pyplot.figure()
    pyplot.plot(momenta, energies)
    pyplot.xlabel("momentum [(lattice constant)^-1]")
    pyplot.ylabel("energy [t]")
    pyplot.gcf()
end
