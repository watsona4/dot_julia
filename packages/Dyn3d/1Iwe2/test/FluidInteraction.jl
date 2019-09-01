@testset "FluidInteraction" begin
    @testset "DetermineNP" begin
        @test DetermineNP(1, 0.02) == 201
        @test DetermineNP(1, 0.01) == 401
        @test DetermineNP(2, 0.02) == 101
        @test DetermineNP(3, 0.02) == 65
        @test DetermineNP(4, 0.02) == 49
    end

    # Construct a BodyDyn structure
    include("../test/config_body.jl")
    bodys, joints, system = BuildChain(config_bodys, config_joints, config_system)
    bd = BodyDyn(bodys, joints, system)
    bd, soln = InitSystem!(bd)
    herkbody = Dyn3d.HERKBody(system.num_params,HERKFuncM, HERKFuncGT, HERKFuncG,
                (HERKFuncf,HERKFuncgti), (UpdatePosition!,UpdateVelocity!))

    # create fluid-body interface
    Δx = 0.02
    bgs = GenerateBodyGrid(bd; np=DetermineNP(nbody, Δx))
    @test bgs[1].np == 201
    @test length(bgs[1].points) == 201

    # cut out in 2d
    bgs = CutOut2d(bd,bgs)
    @test bgs[1].np == 51
    @test length(bgs[1].points) == 51

    # check intial body points position
    bgs = AcquireBodyGridKinematics(bd,bgs)
    @test isapprox(hcat(bgs[1].q_i...)'[:,1],1:0.02:2)

    # advance body solver for one step
    soln.dt = 0.01
    soln, bds = herkbody(soln, bd; _isfixedstep=true, _outputmode=true)
    NS = 3

    # check body points position & velocity
    bkins = Vector{Array{Float64,2}}(undef,NS)
    for k = 1:NS
        bgs = AcquireBodyGridKinematics(bds[k],bgs)
        coord = hcat(bgs[1].q_i...)'[:,[1,2]]
        motion = hcat(bgs[1].v_i...)'[:,[1,2]]
        for i = 2:length(bgs)
            coord = [coord[1:end-1,:]; hcat(bgs[i].q_i...)'[:,[1,2]]]
            motion = [motion[1:end-1,:]; hcat(bgs[i].v_i...)'[:,[1,2]]]
        end
        bkins[k] = [coord motion]
    end
    @test all(bkins[3][:,2] .≈ 0.99995)
    @test all(bkins[3][:,4] .≈ -0.01)

    # integrate body force and test
    f = [-0.649779 -0.785108; 0.313551 -0.834843; -0.328143 -1.0316; 0.271288 -1.14996;
     -0.280372 -1.26448; 0.250311 -1.36147; -0.249826 -1.44837; 0.227311 -1.52607;
      -0.222081 -1.59596; 0.203026 -1.6592; -0.195263 -1.71636; 0.178144 -1.76822;
       -0.168865 -1.81507; 0.152962 -1.85744; -0.142688 -1.89551; 0.127615 -1.92966;
        -0.116636 -1.95998; 0.102171 -1.98676; -0.0906599 -2.01005; 0.0766686 -2.03005;
         -0.0647301 -2.04679; 0.0511295 -2.06041; -0.0388282 -2.07091; 0.0255696 -2.0784;
          -0.0129412 -2.08286; 2.84082e-14 -2.08437; 0.0129412 -2.08286; -0.0255696 -2.0784;
           0.0388282 -2.07091; -0.0511295 -2.06041; 0.0647301 -2.04679; -0.0766686 -2.03005;
            0.0906599 -2.01005; -0.102171 -1.98676; 0.116636 -1.95998; -0.127615 -1.92966;
             0.142688 -1.89551; -0.152962 -1.85744; 0.168865 -1.81507; -0.178144 -1.76822;
              0.195263 -1.71636; -0.203026 -1.6592; 0.222081 -1.59596; -0.227311 -1.52607;
               0.249826 -1.44837; -0.250311 -1.36147; 0.280372 -1.26448; -0.271288 -1.14996;
                0.328143 -1.0316; -0.313551 -0.834843; 0.649779 -0.785108]

    for i = 1:size(f,1)
        bgs[1].f_ex3d[i][[1,2]] = f[i,:]*Δx^2
    end
    bgs = IntegrateBodyGridDynamics(bd,bgs)

    @test isapprox(sum(f[:,1])*Δx^2, bgs[1].f_ex6d[4]; atol=1e-7)
    @test isapprox(sum(f[:,2])*Δx^2, bgs[1].f_ex6d[5]; atol=1e-7)

end
