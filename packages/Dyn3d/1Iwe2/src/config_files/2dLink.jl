#=
This is a system configure file, containing body and joint information.
The body itself is a 2d body, and moves in 2d space. This subroutine is passed
into Dyn3dRun.ipynb to set up a specific system of rigid bodies.

This sets up 2d hinged rigid bodies, connected to inertial space with a revolute
joint, and each connected to the next by revolute joint. The first joint has
active oscillatory motion while the others are all passive.
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
stiff = 0.0075
damp = 0.0016
config_joints = Vector{ConfigJoint}(undef,njoint)

# ------------------------------------------------------------------------------
# set the first active joint
active_motion = Motions("oscillatory", [π/4, 1., 0.])
active_dof = Dof(3, "active", 0., 0., active_motion)
config_joints[1] = ConfigJoint(njoint, "revolute",
                               zeros(Float64,6), zeros(Float64,6),
                               0, [active_dof], [0.])

# set the rest passive joint
for i = 2:njoint
#     config_joints[i] = deepcopy(config_joints[1])
    config_joints[i] = ConfigJoint(njoint, "revolute")
    config_joints[i].joint_dof[1].stiff = stiff
    config_joints[i].joint_dof[1].damp = damp
    config_joints[i].body1 = i-1
end
# ------------------------------------------------------------------------------

# ------------------------------------------------------------------------------
# dof = Dof(3, "passive", stiff, damp, Motions())
#
# config_joints[1] = ConfigJoint(njoint, "revolute",
#     [0.,0.,0.,1.0,1.0,0.], zeros(Float64,6), 0, [dof], [0.])
#
# for i = 2:njoint
#     config_joints[i] = ConfigJoint(njoint, "revolute", [0., 0., 0., 1./njoint, 0., 0.],
#         zeros(Float64,6), i-1, [dof], [π/4])
# end
# ------------------------------------------------------------------------------

println("Config info set up.")
