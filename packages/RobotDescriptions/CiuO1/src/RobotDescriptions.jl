__precompile__()

module RobotDescriptions

using RigidBodyDynamics
using MechanismGeometries

export getmechanism, getvisual, getrobot

urdfpath() = joinpath(@__DIR__, "..", "urdf")
meshepath() = joinpath(@__DIR__, "..", "meshes")

const robots = ["kukalwr",
                "denso060",
                "puma560"]

urdf(robot_name::String) = joinpath(urdfpath(), robot_name * ".urdf")

"""
Return a `RigidBodyDynamics.Mechanism` of a robot 
# Examples
```jldoctest; output = false
julia> using RobotDescriptions
julia> mechanism = getmechanism("kukalwr");
```
"""
function getmechanism(robot_name, T = Float64; remove_fixed_tree_joints = true)
    if robot_name in robots
        mechanism = RigidBodyDynamics.parse_urdf(T, urdf(robot_name))
        remove_fixed_tree_joints && remove_fixed_tree_joints!(mechanism)
        return mechanism
    else
       error("You must use one of the existing templates, possible choices are:\n $(robots)") 
    end

end

"""
Return a `MechanismGeometries.URDF.URDFVisuals` of a robot 
# Examples
```jldoctest; output = false
julia> using RobotDescriptions
julia> visual = getvisual("kukalwr");
```
"""
function getvisual(robot_name)
    if robot_name in robots
        return URDFVisuals(urdf(robot_name), package_path = [meshepath()])
    else 
        error("You must use one of the existing templates, possible choices are:\n $(robots)") 
    end
end

"""
Return a `RigidBodyDynamics.Mechanism` and `MechanismGeometries.URDF.URDFVisuals` of a robot 
# Examples
```jldoctest; output = false
julia> using RobotDescriptions
julia> mechanism, visual = getrobot("kukalwr");
```
"""
function getrobot(robot_name, T = Float64, remove_fixed = true)
    if robot_name in robots
        return getmechanism(robot_name, T, remove_fixed_tree_joints = remove_fixed), getvisual(robot_name) 
    else
        error("You must use one of the existing templates, possible choices are:\n $(robots)") 
    end
end    

end # module
