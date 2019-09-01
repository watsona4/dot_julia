#=
This is a system configure file, containing body and joint information.
The body itself is a 2d body, and moves in 2d space. This subroutine is passed
into Dyn3dRun.ipynb to set up a specific system of rigid bodies.

This sets up 2d hinged rigid bodies, disconnected from the inertial space,
and each connected to the next by revolute joint. The first joint is planar type
and is passive, while the other joints either passive or have active oscillatory
motion. Here all the other joints are active.
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
nbody = 4
config_body = ConfigBody(nbody)
config_bodys = fill(config_body, nbody)

# set up joints
njoint = nbody
stiff = 0.6
damp = 0.1
config_joints = Vector{ConfigJoint}(undef,njoint)

# set the first active revolute joint
active_motion = Motions("oscillatory", [π/4, 1., 0.])
dof₁ = Dof(3, "active", 0., 0., active_motion)
config_joints[1] = ConfigJoint(njoint, "revolute",
    zeros(Float64,6), zeros(Float64,6), 0, [dof₁], [0.])

# set the rest planar passive joint
dof₂ = Vector{Dof}(undef,3)
dof₂[1] = Dof(3, "passive", stiff, damp, Motions())
dof₂[2] = Dof(4, "passive", stiff, damp, Motions())
dof₂[3] = Dof(5, "active", 0., 0., Motions("hold",[0.]))

for i = 2:njoint
    config_joints[i] = ConfigJoint(njoint, "planar",
        [0., 0., 0., 1.0/njoint, 0., 0.],
        zeros(Float64,6), i-1, dof₂, zeros(Float64,3))
end

println("Config info set up.")
