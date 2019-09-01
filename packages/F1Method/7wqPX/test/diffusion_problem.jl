
using Test, FormulaOneMethod

#@testset "Testing in a diffusion system" begin

    using LinearAlgebra, SparseArrays, SuiteSparse, DiffEqBase, FormulaOneMethod

    # 2D Laplacian
    function laplacian_2D(nx, ny, k)
        # the 4 neighbours in 2D, in Cartesian coordinates
        Ns = [CartesianIndex(ntuple(x -> x == d ? 1 : 0, 2)) for d in 1:2]
        neighbors = [Ns; -Ns]
        # Laplacian
        Δ = sparse([], [], Vector{Float64}(), nx*ny, nx*ny)
        R = CartesianIndices((nx,ny))
        # Fill the Laplacian within the borders
        for d in 1:2
            N = Ns[d]
            # R′ is the range of indices without the borders in dimension `d`
            R′ = CartesianIndices((nx,ny) .- 2 .* N.I)
            R′ = [r + N for r in R′]
            # Convert to linear indices to build the Laplacian
            u = vec(LinearIndices((nx,ny))[R′])
            in = LinearIndices((nx,ny))[first(R) + N] - LinearIndices((nx,ny))[first(R)]
            # Build the Laplacian (not the fastest way but easier-to-read code)
            Δ += sparse(u, u      , -2k[d], nx*ny, nx*ny)
            Δ += sparse(u, u .- in, +k[d], nx*ny, nx*ny)
            Δ += sparse(u, u .+ in, +k[d], nx*ny, nx*ny)
        end
        return Δ
    end

    # Create a small diffusion problem
    nx = 50
    ny = 40
    n = nx * ny
    m = 4 # parameters


    T(p) = -laplacian_2D(nx ,ny, [p[1], p[2]])

    # TODO make this cleaner, something with a comprehension list maybe
    # A local source (fixing the source at the center to be p[3]
    source_index = LinearIndices((nx,ny))[Int(round(nx/2)),Int(round(ny/2))]
    source_vec = zeros(n)
    source_vec[source_index] = 1
    source(x,p) = source_vec .* (p[3] .- x)
    ∇source(x,p) = -sparse(Diagonal(source_vec))

    # A global sink
    sink(x,p) = p[4] * x / n
    ∇sink(x,p) = p[4] * I / n

    # Define state function F(x,p) and Jacobian ∇ₓF(x,p)
    F(x,p) = -T(p) * x + source(x,p) - sink(x,p)
    ∇ₓF(x,p) = -T(p) + ∇source(x,p) - ∇sink(x,p)

    # Basic Newton solver
    function newton_solve(F, ∇ₓF, x; Ftol=1e-10)
        while norm(F(x)) ≥ Ftol
            x .-= ∇ₓF(x) \ F(x)
        end
        return x
    end

    # Create a type for the solver's algorithm
    struct MyAlg <: DiffEqBase.AbstractSteadyStateAlgorithm end

    # Overload DiffEqBase's solve function
    function DiffEqBase.solve(prob::DiffEqBase.AbstractSteadyStateProblem,
                              alg::MyAlg;
                              Ftol=1e-10)
        # Define the functions according to DiffEqBase.SteadyStateProblem type
        p = prob.p
        t = 0
        x0 = copy(prob.u0)
        dx, df = copy(x0), copy(x0)
        F(x) = prob.f(dx, x, p, t)
        ∇ₓF(x) = prob.f(df, dx, x, p, t)
        # Compute `u_steady` and `resid` as per DiffEqBase using my algorithm
        x_steady = newton_solve(F, ∇ₓF, x0, Ftol=Ftol)
        resid = F(x_steady)
        # Return the common DiffEqBase solution type
        DiffEqBase.build_solution(prob, alg, x_steady, resid; retcode=:Success)
    end

    # Overload DiffEqBase's SteadyStateProblem constructor
    function DiffEqBase.SteadyStateProblem(F, ∇ₓF, x, p)
        f(dx, x, p, t) = F(x, p)
        f(df, dx, x, p, t) = ∇ₓF(x, p)
        return DiffEqBase.SteadyStateProblem(f, x, p)
    end

    # Define objective function f(x,p) and ∇ₓf(x,p)
    function state_mismatch(x)
        δ(x) = x - ones(n)
        return 0.5δ(x)'δ(x)
    end
    function parameter_mismatch(p)
        δ(p) = log.(p)
        return 0.5δ(p)'δ(p)
    end
    f(x,p) = state_mismatch(x) + parameter_mismatch(p)
    function ∇ₓf(x,p)
        δ(x) = x - ones(n)
        return δ(x)'
    end

    # TODO test the derivatives are correct!
    F1 = FormulaOneMethod
    # Initialize the cache for storing reusable objects
    x₀ = rand(n)
    p₀ = rand(m)
    mem = F1.initialize_mem(x₀, p₀)

    # Compute the objective function, 𝑓̂(𝒑)
    objective(p) = F1.f̂(f, F, ∇ₓF, mem, p, MyAlg())
    objective(p₀)

    # Compute the gradient, ∇𝑓̂(𝒑)
    gradient(p) = F1.∇f̂(f, F, ∇ₓf, ∇ₓF, mem, p, MyAlg())
    gradient(p₀)

    # Compute the Hessian matrix, ∇²𝑓̂(𝒑)
    Hessian(p) = F1.∇²f̂(f, F, ∇ₓf, ∇ₓF, mem, p, MyAlg())
    Hessian(p₀)

#end
