# Tutorial 2.7. Spin textures
# ===========================
#
# Physics background
# ------------------
#  - Spin textures
#  - Skyrmions
#
# Kwant features highlighted
# --------------------------
#  - operators
#  - plotting vector fields

sigma_0 = [1 0; 0 1]
sigma_x = [0 1; 1 0]
sigma_y = [0 -1im; 1im 0]
sigma_z = [1 0; 0 -1]

# vector of Pauli matrices σ_αiβ where greek
# letters denote spinor indices
sigma = [sigma_x, sigma_y, sigma_z]

function field_direction(pos; r0, delta)
    x, y = pos
    r = norm(pos)
    r_tilde = (r - r0) / delta
    theta = (tanh(r_tilde) - 1) * (pi / 2)

    if r == 0
        m_i = [0, 0, -1]
    else
        m_i = [
            (x / r) * sin(theta),
            (y / r) * sin(theta),
            cos(theta),
        ]
    end

    return m_i
end


py"""
def scattering_onsite(site, r0, delta, J):
    m_i = $field_direction(site.pos, r0=r0, delta=delta)
    return J * (m_i[0]*$(sigma[1]) + m_i[1]*$(sigma[2]) + m_i[2]*$(sigma[3]))
"""


py"""
def lead_onsite(site, J):
    return J * $sigma_z
"""


lat = kwant.lattice.square(norbs=2)

function make_system(L=80)

    syst = kwant.Builder()

    function square(pos)
        return all(-L/2 < p < L/2 for p in pos)
    end

    syst[lat.shape(square, (0, 0))] = -4sigma_0#py"scattering_onsite"
    syst[lat.neighbors()] = -sigma_0

    lead = kwant.Builder(kwant.TranslationalSymmetry((-1, 0)),
                         conservation_law=-sigma_z)

    lead[lat.shape(square, (0, 0))] = py"lead_onsite"
    lead[lat.neighbors()] = -sigma_0

    syst.attach_lead(lead)
    syst.attach_lead(lead.reversed())

    return syst
end

#NOTE: for some reason s.tag becomes s[2] in converting to julia. might work on this.
function plot_vector_field(syst; params...)
    xmin, ymin = minimum(s[2] for s in syst.sites)
    xmax, ymax = maximum(s[2] for s in syst.sites)
    x = broadcast((x,y)->x,range(xmin,stop=xmax),range(ymin,stop=ymax)')
    y = broadcast((x,y)->y,range(xmin,stop=xmax),range(ymin,stop=ymax)')

    m_i = map((w,z)->field_direction((w,z); params...), x,y)
    m_i_x, m_i_y, m_i_z = map(w->map(z->z[w],m_i),(1,2,3))

    fig, ax = plt.subplots(1, 1)
    im = ax.quiver(x, y, m_i_x,m_i_y,m_i_z, pivot="mid", scale=75)
    fig.colorbar(im)
    plt.gcf()
end


# function plot_densities(syst, densities)
#     fig, axes = plt.subplots(1, len(densities))
#     for ax, (title, rho) in zip(axes, densities)
#         kwant.plotter.map(syst, rho, ax=ax, a=4)
#         ax.set_title(title)
#     end
#     plt.show()
# end
#
#
# function plot_currents(syst, currents)
#     fig, axes = plt.subplots(1, len(currents))
#     if not hasattr(axes, "__len__")
#         axes = (axes,)
#     end
#     for ax, (title, current) in zip(axes, currents)
#         kwant.plotter.current(syst, current, ax=ax, colorbar=false)
#         ax.set_title(title)
#     end
#     plt.gcf()
# end
