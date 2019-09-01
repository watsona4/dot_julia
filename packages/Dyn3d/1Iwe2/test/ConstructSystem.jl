@testset "JointType" begin
    kind_group = ["revolute", "prismatic", "cylindrical", "planar", "spherical"]
    for i = 1:length(kind_group)
        j = ChooseJoint(kind_group[i])
        @test j.nudof == length(j.udof)
        @test j.ncdof == length(j.cdof)
        @test (6,j.nudof) == size(j.S)
        @test (6,j.ncdof) == size(j.T)
    end
    j = ChooseJoint("free")

end

@testset "ConfigDataType" begin
    # check print results
    config_body = ConfigBody(4)
    dof = Vector{Dof}(undef,3)
    dof[1] = Dof(3, "passive", 0., 0., Motions())
    dof[2] = Dof(4, "passive", 0., 0., Motions())
    dof[3] = Dof(5, "active", 0., 0., Motions("hold",[0.]))
    config_joint = ConfigJoint(1, "planar",
            [0., 0., 0., 1., 0., 0.],
            zeros(Float64,6), 0, dof, zeros(Float64,3))

    print(config_body)
    print(config_joint)

    # check active motion functions
    m₁ = Motions("hold", [0.1]); q₁,v₁ = m₁(2.0)
    m₂ = Motions("velocity", [-0.1,0.2]); q₂,v₂ = m₂(2.0)
    m₃ = Motions("oscillatory", [0.5,1.0,π/4]); q₃,v₃ = m₃(1/16)
    m₄ = Motions("ramp_1",[4.0,π/2, π, 3π/2, 2π]); q₄,v₄ = m₄(π)
    m₅ = Motions("ramp_2",[1.0]); q₅,v₅ = m₅(π/2)
    @test q₁ == 0.1
    @test q₂ ≈ 0.3 && v₂ == 0.2
    @test q₃ ≈ 0.5*cos(0.375π) && v₃ ≈ -π*sin(0.375π)
    @test q₄ ≈ 11.873223433811388 && v₄ ≈ 3.9999442028141754
    @test q₅ ≈ 0.9585761678336372 && v₅ ≈ 0.07941579659003167

end

@testset "ConstructSystem" begin
    path ="../src/config_files"
    names = readdir(path)

    # tests through every config files in config_files folder
    for k = 1:length(names)
        if names[k][1] == '2' || names[k][1] == '3'
            # load config files
            include(path*'/'*names[k])

            # check ConfigDataType
            @test njoint == nbody
            for i = 1:length(config_bodys)
                @test config_bodys[i].nverts == size(config_bodys[i].verts,1)
                @test length(config_joints[i].joint_dof) ==
                      length(config_joints[i].qJ_init)
            end

            # check BuildChain
            bodys, joints, system = BuildChain(config_bodys, config_joints,
                                               config_system)

            # init system
            bd = BodyDyn(bodys, joints, system)
            bd, soln = InitSystem!(bd)

            # test printing using one example
            if k == 3
                print(bodys[1])
                print(joints[1])
                print(system)
            end

            @test system.ndof == system.nudof + system.ncdof
        end
    end

    # create soln structure
    soln_1 = Soln(2.0, 0.01, zeros(Float64,3), zeros(Float64,3))
    soln_2 = Soln(5.0)

end
