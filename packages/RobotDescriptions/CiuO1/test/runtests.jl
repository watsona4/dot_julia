using RobotDescriptions
using Test

@test isdir(RobotDescriptions.meshepath())
@test isdir(RobotDescriptions.urdfpath())
@test count(x -> endswith(x, ".urdf"), readdir(RobotDescriptions.urdfpath())) == 3
