# Tutorial 2.6. "Superconductors": orbitals, conservation laws and symmetries
# ===========================================================================
#
# Physics background
# ------------------
# - conductance of a NS-junction (Andreev reflection, superconducting gap)
#
# Kwant features highlighted
# --------------------------
# - Implementing electron and hole ("orbital") degrees of freedom
#   using conservation laws.
# - Use of discrete symmetries to relate scattering states.

tau_x = [0 1; 1 0]
tau_y = [0  -1im; 1im  0]
tau_z = [1   0  ;  0  -1]

function make_system(;a=1, W=10, L=10, barrier=1.5, barrierpos=(3, 4),
                mu=0.4, Delta=0.1, Deltapos=4, t=1.0)
    # Start with an empty tight-binding system. On each site, there
    # are now electron and hole orbitals, so we must specify the
    # number of orbitals per site. The orbital structure is the same
    # as in the Hamiltonian.
    lat = kwant.lattice.square(norbs=2)
    syst = kwant.Builder()

    #### Define the scattering region. ####
    # The superconducting order parameter couples electron and hole orbitals
    # on each site, and hence enters as an onsite potential.
    # The pairing is only included beyond the point 'Deltapos' in the scattering region.
    # syst[(lat(x, y) for x in range(Deltapos) for y in range(W))] = (4 * t - mu) * tau_z
    # syst[(lat(x, y) for x in range(Deltapos, L) for y in range(W))] = (4 * t - mu) * tau_z + Delta * tau_x
    #
    # The tunnel barrier
    syst[[lat(x, y) for x in range(barrierpos[1], stop=barrierpos[2])
         for y in range(0,length=W)]] = (4 * t + barrier - mu) * tau_z

    # Hoppings
    syst[lat.neighbors()] = -t * tau_z
    #### Define the leads. ####
    # Left lead - normal, so the order parameter is zero.
    sym_left = kwant.TranslationalSymmetry((-a, 0))
    # Specify the conservation law used to treat electrons and holes separately.
    # We only do this in the left lead, where the pairing is zero.
    lead0 = kwant.Builder(sym_left, conservation_law=-tau_z, particle_hole=tau_y)
    lead0[[lat(0, j) for j in range(0,length=W)]] = (4 * t - mu) * tau_z
    lead0[lat.neighbors()] = -t * tau_z
    # Right lead - superconducting, so the order parameter is included.
    sym_right = kwant.TranslationalSymmetry((a, 0))
    lead1 = kwant.Builder(sym_right)
    lead1[[lat(0, j) for j in range(0,length=W)]] = (4 * t - mu) * tau_z + Delta * tau_x
    lead1[lat.neighbors()] = -t * tau_z

    #### Attach the leads and return the system. ####
    syst.attach_lead(lead0)
    syst.attach_lead(lead1)

    return syst
end


function plot_conductance(syst; energies)
    # Compute conductance
    data = []
    for energy in energies
        smatrix = kwant.smatrix(syst, energy)
        # Conductance is N - R_ee + R_he
        append!(data,smatrix.submatrix((0, 0), (0, 0)).shape[1] -
                    smatrix.transmission((0, 0), (0, 0)) +
                    smatrix.transmission((0, 1), (0, 0)))
    end
    pyplot.figure()
    pyplot.plot(energies, data)
    pyplot.xlabel("energy [t]")
    pyplot.ylabel("conductance [e^2/h]")
    pyplot.gcf()
end

function check_PHS(syst)
    # Scattering matrix
    s = kwant.smatrix(syst, 0)
    # Electron to electron block
    s_ee = convert(Array,s.submatrix((0,0), (0,0)))
    # Hole to hole block
    s_hh = convert(Array,s.submatrix((0,1), (0,1)))
    println("s_ee: \n", round.(s_ee; digits=3))
    println("s_hh: \n", round.(s_hh[end:-1:1, end:-1:1], digits=3))
    println("s_ee - s_hh^*: \n",
          round.((s_ee - conj(s_hh[end:-1:1, end:-1:1])), digits=3), "\n")
    # Electron to hole block
    s_he = convert(Array,s.submatrix((0,1), (0,0)))
    # Hole to electron block
    s_eh = convert(Array,s.submatrix((0,0), (0,1)))
    println("s_he: \n", round.(s_he, digits=3))
    println("s_eh: \n", round.(s_eh[end:-1:1,end:-1:1], digits=3))
    println("s_he + s_eh^*: \n",
          round.(s_he + conj(s_eh[end:-1:1,end:-1:1]), digits=3))
end
