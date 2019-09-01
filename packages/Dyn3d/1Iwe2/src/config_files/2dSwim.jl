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
tf = 4
dt = 1e-3
scheme = "BH5"
st = 5
tol = 1e-4
num_params = NumParams(tf, dt, scheme, st, tol)
# gravity
gravity = [0., 0., 0., ]

# set up system config info
config_system = ConfigSystem(ndim, gravity, num_params)

# set up bodys
nbody = 6
config_body = ConfigBody(nbody)
config_bodys = fill(config_body, nbody)

# set up joints
njoint = nbody
gap = 0.03
config_joints = Vector{ConfigJoint}(undef,njoint)

# set the first passive joint with no stiff and damp
dofₚ = Vector{Dof}(undef,3)
[dofₚ[i] = Dof(i+2, "passive", 0., 0., Motions()) for i = 1:3]
config_joints[1] = ConfigJoint(njoint, "planar",
    zeros(Float64,6), zeros(Float64,6), 0, dofₚ, zeros(Float64,3))

# set the rest active joint with oscillatory motion
Δh = 0.0
for i = 2:njoint
    global Δh = Δh + 1.0/njoint
    active_motion = Motions("oscillatory", [π/4, 1., -2π/njoint*Δh])
    dofₐ = Dof(3, "active", 0., 0., active_motion)
    config_joints[i] = ConfigJoint(njoint, "revolute",
       [0., 0., 0., 1.0/njoint+gap, 0., 0.],
       [0., 0., 0., -gap, 0., 0.],
       i-1, [dofₐ], [0.])
end

println("Config info set up.")
