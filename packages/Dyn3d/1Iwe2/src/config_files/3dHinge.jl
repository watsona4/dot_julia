#=
This is a system configure file, containing body and joint information.
The body itself is a 2d body, and moves in 3d space. The body shape can be
quadrilateral or triangle. This subroutine is passed
into Dyn3dRun.ipynb to set up a specific system of rigid bodies.

This sets up 3d hinged rigid bodies, the first joint is a planar type with hold
motion on x, oscillatory active motion on y and passive on θ. The rest joints
are connected to each other by revolute joint with an angle α.
=#

# problem dimension
ndim = 3
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
α = π/2/nbody
shape = "quadrilateral"
if shape == "quadrilateral"
    config_body = ConfigBody(nbody, 4,
        [0. 0.; 1. 0.; cos(α) 1.0/nbody+sin(α); 0. 1.0/nbody], 0.01)
elseif shape == "triangle"
    config_body = ConfigBody(nbody, 3,
        [0. 0.; 1. 0.; cos(α) sin(α); 0. 1.0/nbody], 0.01)
end
config_bodys = fill(config_body, nbody)

# set up joints
njoint = nbody
stiff = 0.1
damp = 0.01
config_joints = Vector{ConfigJoint}(undef,njoint)

# set the joint_dof of the first active joint
dof₁ = Vector{Dof}(undef,3)
dof₁[1] = Dof(3, "passive", 0., 0., Motions())
dof₁[2] = Dof(4, "active", 0., 0., Motions("hold",[0.]))
active_motion = Motions("oscillatory", [0.5, 1., 0.])
dof₁[3] = Dof(5, "active", 0., 0., active_motion)
# set the first active joint
config_joints[1] = ConfigJoint(njoint, "planar",
    # zeros(Float64,6), zeros(Float64,6), 0, dof₁, zeros(Float64,3))
    zeros(Float64,6), zeros(Float64,6), 0, dof₁, [0.,π/2,0.])


# set the rest passive joint
dofₚ = Dof(3, "passive", stiff, damp, Motions())
for i = 2:njoint
    config_joints[i] = ConfigJoint(njoint, "revolute",
        [0., α, 0., 1.0/njoint, 0., 0.],
        [0., 0., 0, 0., 0., 0.],
        i-1, [dofₚ], [0.])
end

println("Config info set up.")
