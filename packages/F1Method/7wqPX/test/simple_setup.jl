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
