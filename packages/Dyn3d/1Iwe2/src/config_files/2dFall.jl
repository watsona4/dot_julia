#=
This is a system configure file, containing body and joint information.
The body itself is a 2d body, and moves in 2d space. This subroutine is passed
into Dyn3dRun.ipynb to set up a specific system of rigid bodies.

This sets up 2d hinged rigid bodies, connected to inertial space with a revolute
joint, and each connected to the next by revolute joint. All joints are passive,
the body system is under gravity.
=#

# problem dimension
ndim = 2
# numerical params
tf = 8
dt = 1e-3
scheme = "Liska"
st = 3
tol = 1e-4
num_params = NumParams(tf, dt, scheme, st, tol)
# gravity
gravity = [0., -1., 0., ]

# set up system config info
config_system = ConfigSystem(ndim, gravity, num_params)

# set up bodys
nbody = 8
# config_body = ConfigBody(nbody)
config_body = ConfigBody(nbody, 4,
   [0. 0.; 1. 0.; 1. 1.0/nbody; 0. 1.0/nbody], 1.0)
config_bodys = fill(config_body, nbody)

# set up joints
njoint = nbody
stiff = 0.075
damp = 0.0016
config_joints = Vector{ConfigJoint}(undef,njoint)

# set the first passive joint with no stiff and damp
dof_1 = Dof(3, "passive", 0., 0., Motions())
# config_joints[1] = ConfigJoint(njoint, "revolute",
#     zeros(Float64,6), zeros(Float64,6), 0, [dof_1], [0.])
config_joints[1] = ConfigJoint(njoint, "revolute",
    [0.,0.,0.,0.0,0.5,0.], zeros(Float64,6), 0, [dof_1], [0.])

# set all the rest joints
for i = 2:njoint
    config_joints[i] = ConfigJoint(njoint, "revolute")
    config_joints[i].joint_dof[1].stiff = stiff
    config_joints[i].joint_dof[1].damp = damp
    config_joints[i].body1 = i-1
end


println("Config info set up.")
