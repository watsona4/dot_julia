@testset "HERK" begin
    # preparation for testing HERK
    methods = ["Liska", "BH3", "BH5"]
    sts = [3, 3, 5]
    path = "../src/config_files/2dLink.jl"
    include(path)

    # begin time marching
    for k in 1:length(methods)
        # build body chain
        bodys, joints, system = BuildChain(config_bodys, config_joints, config_system)
        system.num_params.tf = 1e-3

        # use different methods
        system.num_params.scheme = methods[k]
        system.num_params.st = sts[k]

        # init system
        bd = BodyDyn(bodys, joints, system)
        bd, soln = InitSystem!(bd)

        herk = HERKBody(system.num_params,HERKFuncM, HERKFuncGT, HERKFuncG,
                        (HERKFuncf,HERKFuncgti), (UpdatePosition!,UpdateVelocity!))

        while soln.t < system.num_params.tf
            soln, bd = herk(soln, bd, _isfixedstep=true)
        end
    end
end

# @testset "BlockLU" begin
#     n = 30
#     t = rand(1:n)
#     A = rand(n,n)
#     b = rand(n)
#     @test BlockLU(A, b, t, n-t) ≈ A\b
# end
