#=
This is a system configure file, containing body and joint information.
The body itself is a 2d body, and moves in 3d space. The body shape can be
quadrilateral or triangle. This subroutine is passed
into Dyn3dRun.ipynb to set up a specific system of rigid bodies.

This sets up 3d cylindrical rigid bodies, connected to inertial space with a
cylindrical joint, passive in θ and hold in z. Each following joint is connected
to the previous one by a  cylindrical joint. The system is under gravity.
=#

# problem dimension
ndim = 3
# numerical params
tf = 4
dt = 1e-3
scheme = "Liska"
st = 3
tol = 1e-4
num_params = NumParams(tf, dt, scheme, st, tol)
# gravity
gravity = [0., -9.8, 0., ]

# set up system config info
config_system = ConfigSystem(ndim, gravity, num_params)

# set up bodys
nbody = 4
α = 0.
shape = "quadrilateral"
if shape == "quadrilateral"
    config_body = ConfigBody(nbody, 4,
        [0. 0.; 1. 0.; cos(α) 1.0/nbody+sin(α); 0. 1.0/nbody], 0.01)
elseif shape == "triangle"
    config_body = ConfigBody(nbody, 3,
        [0. 0.; 1. 0.; cos(α) sin(α)], 0.01)
end
config_bodys = fill(config_body, nbody)

# set up joints
njoint = nbody
θ = π/4
config_joints = Vector{ConfigJoint}(undef,njoint)

# set the first joint
dof₁ = Vector{Dof}(undef,2)
dof₁[1] = Dof(3, "passive", 0., 0., Motions())
dof₁[2] = Dof(6, "active", 0., 0., Motions("hold", [0.]))
config_joints[1] = ConfigJoint(njoint, "cylindrical",
    [θ, 0., 0., 0., 0., 0.],
    zeros(Float64,6), 0, dof₁, [0., 0.])

# set the rest passive joint
dofₚ = Vector{Dof}(undef,2)
dofₚ[1] = Dof(3, "passive", 0.03, 0.1, Motions())
dofₚ[2] = Dof(6, "passive", 0.3, 0.01, Motions())
for i = 2:njoint
    config_joints[i] = ConfigJoint(njoint, "cylindrical",
        [0., 0., 0., 1.0/njoint, 0., 0.],
        [0., 0., 0, 0., 0., 0.],
        i-1, dofₚ, [0., 0.])
end

println("Config info set up.")
