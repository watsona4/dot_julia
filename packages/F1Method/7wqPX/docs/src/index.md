# F1Method.jl Documentation

This package provides an efficient tool to compute gradient and Hessian matrix of an objective function implicitly defined by the solution of a steady-state problem.

## Why the F-1 method?

When using Newton-type algorithms for optimization, computing the gradient and Hessian can be computationally expensive.
A typical scientific application is to optimize the parameters of a model which solves for a root through another iterative Newton-like algorithm.
In this case, there are a number of shortcuts that can be leveraged.
This was the motivation for the work of [Pasquier et al. (2019, in preparation)](), and for this package.

## Usage

```@meta
DocTestSetup = quote
    using F1Method
    using LinearAlgebra, DiffEqBase, ForwardDiff
end
```

This is an example use of the software.
We define a state function, ``\boldsymbol{F}(\boldsymbol{x},\boldsymbol{p})``, to which we apply a solver based on Newton's method (for root searching) to find the steady-state solution, ``\boldsymbol{x}``, such that ``\boldsymbol{F}(\boldsymbol{x},\boldsymbol{p}) = 0``.
This defines the steady-state solution as an implicit function of the parameters, ``\boldsymbol{p}``.
We denote this solution by ``\boldsymbol{s}(\boldsymbol{p})``.
The Newton solver requires the Jacobian, ``\nabla_{\boldsymbol{x}}\boldsymbol{F}``, to update the state iterates.
Hence, we start by creating the functions `F(x,p)` and `∇ₓF(x,p)`.
As an example, we use a simple model with only two state variables and two parameters.
(Note here for simplicity we use the [ForwardDiff](https://github.com/JuliaDiff/ForwardDiff.jl) package to evaluate the Jacobian.)

```jldoctest usage
# State function F
F(x,p) = [
    -2 * (p[1] - x[1]) - 4 * p[2] * (x[2] - x[1]^2) * x[1]
    p[2] * (x[2] - x[1]^2)
]

# Jacobian of F wrt p
∇ₓF(x,p) = ForwardDiff.jacobian(x -> F(x,p), x)

# output

∇ₓF (generic function with 1 method)
```

We also define a cost function `f(x,p)` (that we wish to minimize under the constraint that ``\boldsymbol{F}(\boldsymbol{x},\boldsymbol{p}) = 0``).
(The F-1 method requires that we provide the derivatives w.r.t. the state, `x`, hence the use of ForwardDiff again for this example.)

```jldoctest usage
# Define mismatch function f(x,p) and its derivative ∇ₓf(x,p)
# (Note ∇ₓF and ∇ₓf are required by the F1 method)
function state_mismatch(x)
    δ(x) = x .- 1
    return 0.5δ(x)'δ(x)
end
function parameter_mismatch(p)
    δ(p) = log.(p)
    return 0.5δ(p)'δ(p)
end
f(x,p) = state_mismatch(x) + parameter_mismatch(p)
∇ₓf(x,p) = ForwardDiff.jacobian(x -> [f(x,p)], x)

# output

∇ₓf (generic function with 1 method)
```

Once these are set up, we need to let the F-1 method know how to solve for the steady-state.
We do this by using the [DiffEqBase](https://github.com/JuliaDiffEq/DiffEqBase.jl) API.
For that, we first write a small Newton solver algorithm, we overload the `solve` function from DiffEqBase, and we overload the `SteadyStateProblem` constructor.

```jldoctest usage
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

# output


```

We chose an initial value for the state, `x`, and the parameters, `p`:

```jldoctest usage
x₀, p₀ = [1.0, 2.0], [3.0, 4.0]

# output

([1.0, 2.0], [3.0, 4.0])
```

Finally, we wrap the objective, gradient, and Hessian functions defined by the F-1 method.

```jldoctest usage
# Initialize the cache for storing reusable objects
mem = F1Method.initialize_mem(x₀, p₀)
# Define the functions via the F1 method
F1_objective(p) = F1Method.objective(f, F, ∇ₓF, mem, p, MyAlg())
F1_gradient(p) = F1Method.gradient(f, F, ∇ₓf, ∇ₓF, mem, p, MyAlg())
F1_Hessian(p) = F1Method.hessian(f, F, ∇ₓf, ∇ₓF, mem, p, MyAlg())

# output

F1_Hessian (generic function with 1 method)
```

We can now use these directly to compute objective, gradient, and Hessian:

```jldoctest usage
F1_objective(p₀)

# output

35.56438050824269
```

```jldoctest usage
F1_gradient(p₀)

# output

1×2 Array{Float64,2}:
 50.3662  0.346574
```


```jldoctest usage
F1_Hessian(p₀)

# output

2×2 Array{Float64,2}:
 52.989   0.0
  0.0    -0.0241434
```

