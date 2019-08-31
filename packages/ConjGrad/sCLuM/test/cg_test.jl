using LinearAlgebra, SparseArrays
using ConjGrad
using Test
using BenchmarkTools

function test_cg()
    tA = sprandn(1000,1000,.1) .+ 100.0*sparse(1.0I, 1000, 1000)
    A = tA'*tA
    b = rand(1000)
    true_x = A\b

    function preccc(x, y)
        return @. x = y
    end

    comm = missing
    x, exit_code, num_iters = cg((x)->(A * x) , b,
                                 tol=1e-16,
                                 maxIter=1000,
                                 precon=preccc,
                                 verbose=false,
                                 comm=comm
                                 )
    if norm(true_x - x) < 1e-16
        return true
    else
        return false, x, true_x
    end

end

@test test_cg()
