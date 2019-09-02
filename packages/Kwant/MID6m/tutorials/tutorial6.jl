using PyPlot, PyCall, LinearAlgebra, Revise
using Kwant
kwant = Kwant; plt = PyPlot


include("magnetic_texture.jl")

syst = make_system().finalized()

params = Dict(:r0=>20, :delta=>10, :J=>1)
wf = kwant.wave_function(syst, energy=-1, params=params)
psi = wf(0)[2,:]

plot_vector_field(syst; r0=20, delta=10)

# even (odd) indices correspond to spin up (down)
up, down = psi[2:2:end], psi[1:2:end]
density = abs2.(up) + abs2.(down)

# spin down components have a minus sign
spin_z = abs2.(up) - abs2.(down)

# spin down components have a minus sign
spin_y = 1im * (conj(down) .* up - conj(up) .* down)

rho = kwant.operator.Density(syst)
rho_sz = kwant.operator.Density(syst, sigma_z)
rho_sy = kwant.operator.Density(syst, sigma_y)

# calculate the expectation values of the operators with 'psi'
density = rho(psi)
spin_z = rho_sz(psi)
spin_y = rho_sy(psi)

plot_densities(syst, [
    ('$σ_0$', density),
    ('$σ_z$', spin_z),
    ('$σ_y$', spin_y),
])

J_0 = kwant.operator.Current(syst)
J_z = kwant.operator.Current(syst, sigma_z)
J_y = kwant.operator.Current(syst, sigma_y)

# calculate the expectation values of the operators with 'psi'
current = J_0(psi)
spin_z_current = J_z(psi)
spin_y_current = J_y(psi)

plot_currents(syst, [
    ('$J_{σ_0}$', current),
    ('$J_{σ_z}$', spin_z_current),
    ('$J_{σ_y}$', spin_y_current),
])

def following_m_i(site, r0, delta):
    m_i = field_direction(site.pos, r0, delta)
    return np.dot(m_i, sigma)

J_m = kwant.operator.Current(syst, following_m_i)

# evaluate the operator
m_current = J_m(psi, params=dict(r0=25, delta=10))

plot_currents(syst, [
    (r"$J_{\mathbf{m}_i}$", m_current),
    ("$J_{σ_z}$", spin_z_current),
])


def circle(site):
    return np.linalg.norm(site.pos) < 20

rho_circle = kwant.operator.Density(syst, where=circle, sum=True)

all_states = np.vstack((wf(0), wf(1)))
dos_in_circle = sum(rho_circle(p) for p in all_states) / (2 * pi)
print("density of states in circle:", dos_in_circle)

def left_cut(site_to, site_from):
    return site_from.pos[0] <= -39 and site_to.pos[0] > -39

def right_cut(site_to, site_from):
    return site_from.pos[0] < 39 and site_to.pos[0] >= 39

J_left = kwant.operator.Current(syst, where=left_cut, sum=True)
J_right = kwant.operator.Current(syst, where=right_cut, sum=True)

Jz_left = kwant.operator.Current(syst, sigma_z, where=left_cut, sum=True)
Jz_right = kwant.operator.Current(syst, sigma_z, where=right_cut, sum=True)

print('J_left:', J_left(psi), ' J_right:', J_right(psi))
print('Jz_left:', Jz_left(psi), ' Jz_right:', Jz_right(psi))

J_m = kwant.operator.Current(syst, following_m_i)
J_z = kwant.operator.Current(syst, sigma_z)

J_m_bound = J_m.bind(params=dict(r0=25, delta=10, J=1))
J_z_bound = J_z.bind(params=dict(r0=25, delta=10, J=1))

# Sum current local from all scattering states on the left at energy=-1
wf_left = wf(0)
J_m_left = sum(J_m_bound(p) for p in wf_left)
J_z_left = sum(J_z_bound(p) for p in wf_left)

plot_currents(syst, [
    (r'$J_{\mathbf{m}_i}$ (from left)', J_m_left),
    (r'$J_{σ_z}$ (from left)', J_z_left),
])
