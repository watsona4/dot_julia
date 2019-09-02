# This file is a part of JuliaFEM.
# License is MIT: see https://github.com/JuliaFEM/MortarContact2DAD.jl/blob/master/LICENSE

using MortarContact2DAD, Test
using MortarContact2DAD: project_from_master_to_slave_ad,
                         project_from_slave_to_master_ad
using ForwardDiff

function get_func_1(max_iterations)
    function func_1(u)
        x1 = [0.0, 0.0] + u[1:2]
        x2 = [0.0, 2.0] + u[3:4]
        x3 = [0.5, 0.5] + u[5:6]
        t1_ = (x2-x1) / norm(x2-x1)
        n1 = n2 = [0.0 1.0; -1.0 0.0] * t1_
        x1_ = DVTI(x1, x2)
        n1_ = DVTI(n1, n2)
        slave = Element(Seg2, [1, 2])
        xi1 = project_from_master_to_slave_ad(slave, x1_, n1_, x3;
                                              debug=true, max_iterations=max_iterations)
        return [xi1]
    end
    return func_1
end

J = ForwardDiff.jacobian(get_func_1(10), zeros(6))
@test isapprox(J, [-0.25 -0.75 0.25 -0.25 0.0 1.0])
@test_throws Exception ForwardDiff.jacobian(get_func_1(0), zeros(6))

function get_func_2(max_iterations)
    function func_2(u)
        x1 = [0.0, 0.0] + u[1:2]
        x2 = [0.0, 2.0] + u[3:4]
        x3 = [0.5, -1.0] + u[5:6]
        x4 = [0.5,  1.0] + u[7:8]
        t1 = (x2-x1) / norm(x2-x1)
        n1 = n2 = [0.0 1.0; -1.0 0.0] * t1
        x1_ = DVTI(x1, x2)
        n1_ = DVTI(n1, n2)
        x2_ = DVTI(x3, x4)
        master = Element(Seg2, [3, 4])
        xi2 = project_from_slave_to_master_ad(master, x1, n1, x2_;
                                              max_iterations=max_iterations)
        return [xi2]
    end
    return func_2
end

J = ForwardDiff.jacobian(get_func_2(10), zeros(8))
@test isapprox(J, [0.25  1.0  -0.25  0.0  0.0  -0.5  0.0  -0.5])
@test_throws Exception ForwardDiff.jacobian(get_func_2(0), zeros(8))
