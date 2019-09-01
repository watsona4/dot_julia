#=
This is a system configure file, containing body and joint information.
The body itself is a 2d circle, and moves in 2d space. This subroutine is passed
into Dyn3dRun.ipynb to set up a specific system of rigid bodies. The circle
is freely falling, with the joint un-mounted from inertial space by a planar joint

This circle is in x-z plane and falls in z direction.
=#

# problem dimension
ndim = 2
# numerical params
tf = 1.0
dt = 1e-3
scheme = "BH3"
st = 3
tol = 1e-4
num_params = NumParams(tf, dt, scheme, st, tol)
# gravity
gravity = [0., 0., -1.0]
# plot direction
plot_dir = (1,3)

# set up system config info
config_system = ConfigSystem(ndim, gravity, num_params)

# set up bodys
function circle(z₀::Vector{Float64}, r::Float64, n::Int)
    # z₀ for circle center location, r for radius and n for # of points on circle
    verts = zeros(n,2)
    for i = 1:n
        verts[i,:] = [r*cos(2π/(n-1)*(i-1)) + z₀[1], r*sin(2π/(n-1)*(i-1)) + z₀[2]]
    end
    verts
end

nbody = 1
nverts = 51
verts = circle([0.,0.], 0.2, nverts)
config_body = ConfigBody(nbody, nverts, verts, 0.01)
config_bodys = fill(config_body, nbody)

# set up joints
njoint = nbody
config_joints = Vector{ConfigJoint}(undef,njoint)

# set the first passive joint with no stiff and damp
dofₚ = Dof(6, "passive", 0., 0., Motions())
config_joints[1] = ConfigJoint(njoint, "custom_prismatic_in_z",
    zeros(Float64,6), zeros(Float64,6), 0, [dofₚ], [0.])

println("Config info set up.")
