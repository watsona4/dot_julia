#=
This is a system configure file, containing body and joint information.
The body itself is a 2d body, and moves in 2d space. This subroutine is passed
into Dyn3dRun.ipynb to set up a specific system of rigid bodies.

This sets up a 2d X shape windmill structure with 2 body. The first body has planar
joint
=#

# problem dimension
ndim = 2
# numerical params
tf = 2
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
nbody = 2
# config_body = ConfigBody(nbody)
config_body = ConfigBody(nbody, 4,
    [0. 0.; 1. 0.; 1. 1.0/nbody; 0. 1.0/nbody], 1.0)
config_bodys = fill(config_body, nbody)

# set up joints
njoint = nbody
config_joints = Vector{ConfigJoint}(undef,njoint)

# set the first active joint
motion₁ = Motions("oscillatory", [π/4, 1., 0.])
dof₁ = Dof(3, "active", 0., 0., motion₁)
config_joints[1] = ConfigJoint(njoint, "revolute",
                               [0.,0.,0.,0.5,0.5,0.], zeros(Float64,6),
                               0, [dof₁], [0.])

# set the second active hold joint
motion₂ = Motions("hold", [-π/2])
dof₂ = Dof(3, "active", 0., 0., motion₂)
config_joints[2] = ConfigJoint(njoint, "revolute",
                               [0.,0.,0.,0.125,0.,0.], [0.,0.,0.,0.375,0.,0.],
                               1, [dof₂], [0.])
# ------------------------------------------------------------------------------

println("Config info set up.")
