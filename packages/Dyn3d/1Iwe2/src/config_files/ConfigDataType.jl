module ConfigDataType

export ConfigBody, ConfigJoint, ConfigSystem, Dof, Motions, NumParams

import Base: show

#-------------------------------------------------------------------------------
"""
    Motions(type::String, parameters::Vector{Float64})

A structure representing active motion of a joint, allowing different types of motion,
can be time-dependent.

## Fields
- `motion_type`: Allow choices of "hold", "velocity", "oscillatory", "ramp_1", "ramp_2"
- `motion_params`: Numerical parameters provided to describe the motion

## Constructors

- `Motions(): Provide no active motion`
- `Motions("hold", [qJ])`: Hold the joint at constant qJ and vJ=0
- `Motions("velocity",[qJ,vJ])`: Specify constant vJ of this joint with initial angle qJ
- `Motions("oscillatory",[amp,freq,phase])` specify a oscillatory motion through
    \$qJ = amp*cos(2π*freq*t+phase)\$
- `Motions("ramp_1",[a,t₁,t₂,t₃,t₄])`: Describes a ramp motion in [^1]
- `Motions("ramp_2",[a])`: Describes a decelerating motion with an initial velocity

[^1]: Eldredge, Jeff, Chengjie Wang, and Michael Ol. "A computational study of a canonical pitch-up,
pitch-down wing maneuver." In 39th AIAA fluid dynamics conference, p. 3687. 2009.

## Functions
- `(m::Motions)(t)`: Evalutes the motion type at time t, return joint angle qJ and
    velocity vJ
"""
mutable struct Motions
    motion_type::String
    motion_params::Vector{Float64}
end

Motions() = Motions("", [])

function (m::Motions)(t)
    if m.motion_type == "hold"
        q = m.motion_params[1]
        v = 0

    elseif m.motion_type == "velocity"
        q = m.motion_params[1] + t*m.motion_params[2]
        v = m.motion_params[2]

    elseif m.motion_type == "oscillatory"
        amp = m.motion_params[1]
        freq = m.motion_params[2]
        phase = m.motion_params[3]
        arg = 2π*freq*t + phase
        q = amp*cos(arg)
        v = -2π*freq*amp*sin(arg)

    elseif m.motion_type == "ramp_1"
        # Eldredge ramp from 2009 AIAA paper
        # parameters are a and t[4], this motion is not periodic
        a = m.motion_params[1]
        tᵣ = m.motion_params[2:5]
        f(t) = cosh(a*(t-tᵣ[1]))
        g(t) = cosh(a*(t-tᵣ[2]))
        u(t) = cosh(a*(t-tᵣ[3]))
        n(t) = cosh(a*(t-tᵣ[4]))

        ḟ(t) = a*sinh(a*(t-tᵣ[1]))
        ġ(t) = a*sinh(a*(t-tᵣ[2]))
        u̇(t) = a*sinh(a*(t-tᵣ[3]))
        ṅ(t) = a*sinh(a*(t-tᵣ[4]))

        q = log(f(t)*n(t)/(g(t)*u(t)))
        v = g(t)*u(t)/(f(t)*n(t))*
              (-f(t)*n(t)*(ġ(t)*u(t)+u̇(t)*g(t))/(g(t).^2*u(t).^2)
                  + (ḟ(t)*n(t)+ṅ(t)*f(t))/(g(t)*u(t)))

    elseif m.motion_type == "ramp_2"
        a = m.motion_params[1]
        q = 0.5*(tanh(a*t) + 1)
        v = 0.5*a*sech(a*t).^2
    else
        error("This motion type does not exist")
    end

    return q, v
end
#-------------------------------------------------------------------------------
"""
    Dof(dof_id::Int,dof_type::String,stiff::Float64,damp::Float64,motion::Motions)

Set up a single degree of freedom(dof) information in a joint. A joint may have a
maximum 6 dofs and minimum 1 dof(either active or passive). Here we don't allow it
to have 0 since there's no reason to do this. If we want the parent body and child
body to have no relative motion(i.e. they're rigidly connected together), we can
set the second joint has only one dof and this dof has active "hold" motion.

## Fields
- `dof_id`: Choose from 1 to 6 and is corresponding to [Ox, Oy, Oz, x, y, z].
- `dof_type`: "passive" or "active"
- `stiff`: Non-dimensional stiffness of a string associated with this degree of
    freedom. Only has effect on solving the system when this dof is passive.
- `damp`: Similar to stiff, this assigns the damping coefficient of this dof.
- `motion`: Defines the motion of this dof. Refer to type `Motion`
"""
mutable struct Dof
    dof_id::Int
    dof_type::String
    stiff::Float64
    damp::Float64
    motion::Motions
end

Dof() = Dof(3, "passive", 0.03, 0.01, Motions())
#-------------------------------------------------------------------------------
"""
    ConfigBody(nbody::Int,nverts::Int,verts::Matrix{Float64},ρ::Float64)

Set up configuration information for the a single body in the body system. Here we
assume that all bodies has the same shape if more than one body exists. A single
body is an infinitely thin body in y direction. It must have polygon shape and is
described in z-x space. For example if we describe a rectangle in z-x space, for 3d
problem it's just fine. For 2d problem in x-y space, this rectangle has a projection
 of a line in x-y space. The vertices local coordinates are described in clockwise
direction as a convention.

## Fields
- `nbody`: Number of bodies in total
- `nverts`: Number of vertices for one body
- `verts`: Polygon vertices coordinates starting from the left bottom vert and
    going in clockwise direction. Each line describes the (z,x) coordinate of
    this vertice. Usually the z-dimesion has unit length 1 for 2-d problem.
- `ρ`: Density of this body in mass per area

## Body setup

         ^(y)
         |
         |----->(x)
        /
     (-z)
"""
mutable struct ConfigBody
    nbody::Int
    nverts::Int
    verts::Array{Float64,2}
    ρ::Float64
end

ConfigBody(nbody) = ConfigBody(nbody, 4,
    [0. 0.; 1. 0.; 1. 1.0/nbody; 0. 1.0/nbody], 0.01)

function show(io::IO, m::ConfigBody)
    println(io, " nbody = $(m.nbody)")
    println(io, " nverts = $(m.nverts)")
    println(io, " verts = $(m.verts)")
    println(io, " ρ = $(m.ρ)")
end

#-------------------------------------------------------------------------------
"""
    ConfigJoint(njoint,joint_type,shape1,shape2,body1,joint_dof,qJ_init)

Set up configuration information for a single joint. A joint allows one/multiple
degree of freedoms from 1 to 6.

## Fields

- `njoint`: Int, total number of joints for this body-joint system
- `joint_type`: String, allows "revolute", "prismatic", "cylindrical", "planar",
    "spherical", "free" and "custom". Detailed information is described in `JointType`
    section
- `shape1`: Vector{Float64} with 6 elements. It describes the location of this
    joint in its parent body coordinate. If shape1 is used on the first joint,
    then it's the orientation of this first joint to inertial system. It is written
    with [θx, θy, θz, x, y, z].
- `shape2`: Vector{Float64} with 6 elements. It describes the location of this
    joint in its child body coordinate. Normally, shape2 is zeros(Float64,6) if
    there's no distance gap or angle gap between two adjacent bodies.
- `body1`: the parent body id of this joint
- `joint_dof`: Vector{Float64}. The size of joint_dof depends on the number of
    specified dof, refers to type `Dof`.
- `qJ_init`: Vector{Float64}. It is the initial angle/displacement of this joint
    with respect to its parent body. The size should be the same as the number of
    dof specified.
"""
mutable struct ConfigJoint
    njoint::Int
    joint_type::String
    shape1::Vector{Float64}
    shape2::Vector{Float64}
    body1::Int
    joint_dof::Vector{Dof}
    qJ_init::Vector{Float64}
end

ConfigJoint(njoint,joint_type) = ConfigJoint(njoint, joint_type,
    [0., 0., 0., 1.0/njoint, 0., 0.], zeros(Float64,6),
    0, [Dof()], [0.])

function show(io::IO, m::ConfigJoint)
    println(io, " joint type = $(m.joint_type)")
    println(io, " joint position in parent body coord = $(m.shape1)")
    println(io, " joint position in child body coord = $(m.shape2)")
    for i = 1:size(m.joint_dof,1)
        if m.joint_dof[i].dof_type == "passive"
            println(io, " joint unconstrained dof = ",
            "$(m.joint_dof[i].dof_id), under $(m.joint_dof[i].dof_type) motion")
        else
            println(io, " joint unconstrained dof = ",
            "$(m.joint_dof[i].dof_id), under $(m.joint_dof[i].dof_type) ",
            "$(m.joint_dof[i].motion.motion_type) motion")
        end
    end
    println(io, " initial unconstrained dof position = $(m.qJ_init)")
end

#-------------------------------------------------------------------------------
"""
    NumParams(tf::Float64,dt::Float64,scheme::String,st::Int,tol::Float64)

Numerical parameters needed for the time marching scheme.

## Fields
- `tf`: The end time of this run
- `dt`: Time step size
- `scheme`: Applies the implicit Runge-kutta method of different coefficient, choices
    are "Liska"(2nd order), "BH3"(3rd order), "BH5"(4th order), "Euler"(1st order),
    "RK2"(2nd order), "RK22"(2nd order).
- `st`: The number of stages of this RK scheme
- `tol`: Tolerance used in time marching for adptive time step

"""
mutable struct NumParams
    tf::Float64
    dt::Float64
    scheme::String
    st::Int
    tol::Float64
end

#-------------------------------------------------------------------------------
"""
    ConfigSystem(ndim::Int,gravity::Vector{Float64},num_params::NumParams)

Additional system information to define this problem.

## Fields
- `ndim`: Dimension of this problem. Choices are 2 or 3
- `gravity`: Non-dimensional gravity. It is in [x,y,z] direction. So if we're
    describing a 2d problem with gravity pointing downward, it should be [0.,-1.,0.]
- `num_params`: Refer to type `NumParams`
"""
mutable struct ConfigSystem
    ndim::Int
    gravity::Vector{Float64}
    num_params::NumParams
end

end # module
