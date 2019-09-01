#=
This is a system configure file, containing body and joint information.
The body itself is a 2d body, and moves in 3d space. The body shape can be
quadrilateral or triangle. This subroutine is passed
into Dyn3dRun.ipynb to set up a specific system of rigid bodies.

This sets up 3d hinged rigid bodies, connected to inertial space with a
prismatic joint, and each connected to the  next by a prismatic joint.
The first joint has active oscillatory motion while the others are all passive.
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
gravity = [0., 0., 0., ]

# set up system config info
config_system = ConfigSystem(ndim, gravity, num_params)

# set up bodys
nbody = 6
α = π/2/nbody
shape = "triangle"
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
stiff = 0.03
damp = 0.01
config_joints = Vector{ConfigJoint}(undef,njoint)

# set the joint_dof of the first active joint
active_motion = Motions("oscillatory", [0.25, 1., 0.])
dof₁ = Dof(6, "active", 0., 0., active_motion)
config_joints[1] = ConfigJoint(njoint, "prismatic",
    zeros(Float64,6), zeros(Float64,6), 0, [dof₁], [0.5])

# set the rest passive joint
dofₚ = Dof(6, "passive", stiff, damp, Motions())
for i = 2:njoint
    config_joints[i] = ConfigJoint(njoint, "prismatic",
        [0., α, 0., 0., 0., 0.],
        [0., 0., 0, 0., 0., 0.],
        i-1, [dofₚ], [0.])
end

println("Config info set up.")
