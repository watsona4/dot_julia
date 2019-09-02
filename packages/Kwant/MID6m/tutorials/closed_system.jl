# Tutorial 2.4.2. Closed systems
# ==============================
#
# Physics background
# ------------------
#  Fock-darwin spectrum of a quantum dot (energy spectrum in
#  as a function of a magnetic field)
#
# Kwant features highlighted
# --------------------------
#  - Use of `hamiltonian_submatrix` in order to obtain a Hamiltonian
#    matrix.

# For eigenvalue computation
sla = pyimport("scipy.sparse.linalg")


function make_system(;a=1, t=1.0, r=10)
    # Start with an empty tight-binding system and a single square lattice.
    # `a` is the lattice constant (by default set to 1 for simplicity).

    lat = kwant.lattice.square(a, norbs=1)

    syst = kwant.Builder()

    # Define the quantum dot
    # def circle(pos):
    #     (x, y) = pos
    #     rsq = x ** 2 + y ** 2
    #     return rsq < r ** 2
    function circle(pos)
        (x, y) = pos
        R = hypot(x,y)
        return R < r
    end

    py"""
    def hopx(site1, site2, B):
        # The magnetic field is controlled by the parameter B
        y = site1.pos[1]
        return -$t * $exp(-1j * B * y)
    """
    # function hopx(site1,site2,B)
    #     y = site1.pos[2]
    #     return -t * exp(-1im*B*y)
    # end

    syst[lat.shape(circle, (0, 0))] = 4 * t
    # hoppings in x-direction
    syst[kwant.builder.HoppingKind((1, 0), lat, lat)] = py"hopx"
    # hoppings in y-directions
    syst[kwant.builder.HoppingKind((0, 1), lat, lat)] = -t

    # It's a closed system for a change, so no leads
    return syst
end


function plot_spectrum(syst, Bfields)

    energies = Array{Float64}(undef,15,0)
    for B in Bfields
        # Obtain the Hamiltonian as a sparse matrix
        ham_mat = syst.hamiltonian_submatrix(params=Dict(:B=>B), sparse=true)

        # we only calculate the 15 lowest eigenvalues
        ev = sla.eigsh(ham_mat.tocsc(), k=15, sigma=0,
                       return_eigenvectors=false)

        energies = hcat(energies,ev)
    end

    pyplot.figure()
    pyplot.plot(Bfields, energies')
    pyplot.xlabel("magnetic field [arbitrary units]")
    pyplot.ylabel("energy [t]")
    pyplot.gcf()
end

function sorted_eigs(ev)
    evals, evecs = ev
    perm = sortperm(evals)
    return evals[perm],evecs[:,perm]
    # evals, evecs = map(np.array, zip(*sorted(zip(evals, evecs.transpose()))))
    # return evals, evecs.transpose()
end

function plot_wave_function(syst, B=0.001)
    # Calculate the wave functions in the system.
    ham_mat = syst.hamiltonian_submatrix(sparse=true, params=Dict(:B=>B))
    evals, evecs = sorted_eigs(sla.eigsh(ham_mat.tocsc(), k=20, sigma=0))

    # Plot the probability density of the 10th eigenmode.
    kwant.plotter.map(syst, abs2.(evecs[:, 9]),
                      colorbar=false, oversampling=1)
end


function plot_current(syst, B=0.001)
    # Calculate the wave functions in the system.
    ham_mat = syst.hamiltonian_submatrix(sparse=true, params=Dict(:B=>B))
    evals, evecs = sorted_eigs(sla.eigsh(ham_mat.tocsc(), k=20, sigma=0))

    # Calculate and plot the local current of the 10th eigenmode.
    J = kwant.operator.Current(syst)
    current = J(evecs[:, 9], params=Dict(:B=>B))
    kwant.plotter.current(syst, current, colorbar=false)
end
