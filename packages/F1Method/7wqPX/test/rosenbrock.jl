# This is quasi derived from the Rosenbrock function
# whereby F(x,p) is almost the gradient of the Rosenbrock function
# except the Hessian matroix is made non-symmetric by slightly altering
# F(x,p)


# State function ≈ gradient of Rosenbrock.
# With p = [a, b] the parameters defining the constants
# in Rosenbrocks function, and the slight alteration to make the
# Hessian matrix non-symmetric.
# Specifically, if r(x,y) denotes the rosenbrock function,
#     F₁([x, y], p) = ∂r/∂x
#     F₂([x, y], p) = 0.5 * ∂r/∂y
F(x,p) = [
    -2 * (p[1] - x[1]) - 4 * p[2] * (x[2] - x[1]^2) * x[1]
    p[2] * (x[2] - x[1]^2)
]
 
# Jacobian function of F w.r.t. p
∇ₓF(x,p) = ForwardDiff.jacobian(x -> F(x,p), x)

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

# Initialize the starting state and parameters
x₀ = rand(2)
p₀ = rand(2)
# Initialize the memory cache for storing reusable objects
mem = F1Method.initialize_mem(x₀, p₀)

# Define the functions via the F1 method
F1_objective(p) = F1Method.objective(f, F, ∇ₓF, mem, p, MyAlg())
F1_gradient(p) = F1Method.gradient(f, F, ∇ₓf, ∇ₓF, mem, p, MyAlg())
F1_Hessian(p) = F1Method.hessian(f, F, ∇ₓf, ∇ₓF, mem, p, MyAlg())

# Define the exact solution and objective for comparison
exact_solution(p) = [p[1], p[1]^2]
exact_objective(p) = f(exact_solution(p), p)

# Run the tests
@testset "objective" begin
    @test exact_objective(p₀) ≈ F1_objective(p₀)
end
@testset "gradient" begin
    @test ForwardDiff.jacobian(p -> [exact_objective(p)], p₀) ≈ F1_gradient(p₀)
end
@testset "Hessian" begin
    @test ForwardDiff.hessian(p -> exact_objective(p), p₀) ≈ F1_Hessian(p₀)
end



