# Construct body-joint system
Constructing the body-joint system requires filling in a lot of detailed information,
like body-joint hierarchy information, body inertia, joint degree of freedoms type etc.
In this section we introduce the construction of the system in two aspects:
- User-oriented set up(front end)
- Code-oriented construction(back end)

## User-oriented set up
To set up a body-joint system, one needs to know how to set body properties and
joint properties, also the hierarchy information. In this section we introduce
how to set up the body-joint system, together with other information needed to
enclosure the problem we're interested in.

The set up of the problem generally has 3 parts: set up body, set up joint, and
set up system information like the dimension of this problem, gravity, numerical
parameters etc. We will use these information provided by the user to construct
every single body, every single joint, and finally connect them with hierarchy
information. Some examples of providing user-set-up information are listed in
`src/config_files` for user convenience. Here we take the `2dFall.jl` as an example
to show the procedure of setting up the problem.

`ConfigDataType`

## Code-oriented construction

Before running any dynamics, we need to construct the body-joint system, connecting
bodies by joints in the correct hierarchy using supplied configuration information.
In order to do that, three key functions are used:
- [`AddBody`](@ref AddBody)
- [`AddJoint`](@ref AddJoint)
- [`AssembleSystem`](@ref AssembleSystem)

which is responsible for add a body to the body system, add a joint to the joint system and
assemble the body-joint system and fill in extra hierarchy information. These three functions
are also bundled in the correct sequential order in
- [`BuildChain(cbs, cjs, csys)`](@ref BuildChain)

In order to solve for the rigid body-joint chain system, we choose body velocity $v$
and joint displacement $qJ$ as main variables in the time marching scheme. We also
need to construct a structure that stores and updates the body-joint chain's intermediate
variables such as all kinds of transformation matrices $X$, body position in the inertial
space $x_i$ and so on. All information of the body-joint system is bundled into a `BodyDyn`
structure.








## Methods
```@autodocs
Modules = [ConfigDataType, ConstructSystem]
Order   = [:type, :function]
```

## Index
```@index
Pages = ["construct_system.md"]
```
