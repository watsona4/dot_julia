using ValkyrieRobot
using ValkyrieRobot.BipedControlUtil
using Test
using RigidBodyDynamics: num_velocities

@testset "side" begin
    @test -left == right
    @test -right == left

    sides = [rand(Side) for i = 1 : 10000];
    @test isapprox(count(side -> side == left, sides) / length(sides), 0.5; atol = 0.05)

    @test flipsign_if_right(2., left) == 2.
    @test flipsign_if_right(2., right) == -2.
end

@testset "valkyrie" begin
    val = Valkyrie()
    @test num_velocities(val.mechanism) == 36
    meshdir = joinpath(dirname(ValkyrieRobot.urdfpath()), "urdf", "model", "meshes")

    num_obj = 0
    for (root, dirs, files) in walkdir(meshdir)
        for file in files
            if endswith(file, ".obj")
                num_obj += 1
            end
        end
    end
    @test num_obj == 60
end
