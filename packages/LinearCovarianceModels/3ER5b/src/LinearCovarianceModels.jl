module LinearCovarianceModels

export LCModel, dim,
    # families
    generic_subspace, generic_diagonal, toeplitz, tree, trees,
    # ML degree
    ml_degree_witness, MLDegreeWitness,
    model, parameters, solutions, is_dual, ml_degree, verify,
    # solve specific instance
    mle, critical_points, covariance_matrix, logl, gradient_logl, hessian_logl, classify_point,
    # MLE helper
    mle_system, dual_mle_system, mle_system_and_start_pair, dual_mle_system_and_start_pair,
    # helpers
    vec_to_sym, sym_to_vec


using LinearAlgebra

import HomotopyContinuation
import DynamicPolynomials
import Distributions: Normal

const HC = HomotopyContinuation
const DP = DynamicPolynomials

include("tree_data.jl")

outer(A) = A*A'

"""
    rand_pos_def(n)

Create a random positive definite `n × n` matrix. The matrix is generated
by first creating a `n × n` matrix `X` where each entry is independently drawn
from the `Normal(μ=0, σ²=1.0)` distribution. Then `X*X'./n` is returned.
"""
rand_pos_def(n) = outer(rand(Normal(0, 1.0), n, n)) ./ n

n_vec_to_sym(k) = div(-1 + round(Int, sqrt(1+8k)), 2)
n_sym_to_vec(n) = binomial(n+1,2)

"""
    vec_to_sym(v)

Converts a vector `v` to a symmetrix matrix by filling the lower triangular
part columnwise.

### Example
```
julia> v = [1,2,3, 4, 5, 6];
julia> vec_to_sym(v)
3×3 Array{Int64,2}:
 1  2  3
 2  4  5
 3  5  6
 ```
"""
function vec_to_sym(s)
    n = n_vec_to_sym(length(s))
    S = Matrix{eltype(s)}(undef, n, n)
    l = 1
    for i in 1:n, j in i:n
        S[i,j] = S[j,i] = s[l]
        l += 1
    end
    S
end

"""
    sym_to_vec(S)

Converts a symmetric matrix `S` to a vector by filling the vector with lower triangular
part iterating columnwise.
"""
sym_to_vec(S) = (n = size(S, 1); [S[i,j] for i in 1:n for j in i:n])

"""
    LCModel(Σ::Matrix{<:DP.AbstractPolynomialLike})

Create a linear covariance model from the parameterization `Σ`.
This uses as input a matrix of polynomials created by the [`DynamicPolynomials`](https://github.com/JuliaAlgebra/DynamicPolynomials.jl) package.

## Example

```
using DynamicPolynomials # load polynomials package

# use DynamicPolynomials to create variables θ₁, θ₂, θ₃.
@polyvar θ[1:3]

# create our model as matrix of DynamicPolynomials
Σ = [θ[1] θ[2] θ[3]; θ[2] θ[1] θ[2]; θ[3] θ[2] θ[1]]

# create model
model = LCModel(Σ)
```
"""
struct LCModel{T1<:DP.AbstractPolynomialLike, T2<:Number}
    Σ::Matrix{T1}
    B::Vector{Matrix{T2}}

    function LCModel(Σ::Matrix{T1}, B::Vector{Matrix{T2}}) where {T1,T2}
        all(DP.maxdegree.(vec(Σ)) .<= 1) || throw(ArgumentError("Input is not a linear covariance model"))
        issymmetric(Σ) || throw(ArgumentError("Input is not a symmetric matrix!"))
        new{T1,T2}(Σ, B)
    end
end
LCModel(Σ::Matrix) = LCModel(Σ, get_basis(Σ))
LCModel(Σ::AbstractMatrix) = LCModel(Matrix(Σ))

function get_basis(Σ)
    vars = DP.variables(vec(Σ))
    map(1:length(vars)) do i
        [p(vars[i] => 1,
           vars[1:i-1]=>zeros(Int, max(i-1,0)),
           vars[i+1:end]=>zeros(Int, max(length(vars)-i,0))) for p in Σ]
    end
end

Base.size(M::LCModel) = (size(M.Σ, 1), length(M.B))
Base.size(M::LCModel, i::Int) = size(M)[i]
function Base.show(io::IO, M::LCModel)
    println(io, "$(dim(M))-dimensional LCModel:")
    Base.print_matrix(io, M.Σ)
end
Base.broadcastable(M::LCModel) = Ref(M)

"""
    dim(M::LCModel)

Returns the dimension of the model.
"""
dim(M::LCModel) = length(M.B)

"""
    toeplitz(n::Integer)

Returns a symmetric `n×n` toeplitz matrix.
"""
function toeplitz(n::Integer)
    DP.@polyvar θ[1:n]
    sum(0:n-1) do i
        if i == 0
            θ[1] .* diagm(0 => ones(n))
        else
            θ[i+1] .* (diagm(i => ones(n-i)) + diagm(-i => ones(n-i)))
        end
    end |> LCModel
end

"""
    tree(n, id::String)

Get the covariance matrix corresponding to the tree with the given `id` on `n` leaves.
Returns `nothing` if the tree was not found.

## Example
```
julia> tree(4, "{{1, 2}, {3, 4}}")
4×4 Array{PolyVar{true},2}:
 t₁  t₅  t₇  t₇
 t₅  t₂  t₇  t₇
 t₇  t₇  t₃  t₆
 t₇  t₇  t₆  t₄
 ```
"""
function tree(n::Integer, id::String)
    4 ≤ n ≤ 7 || throw(ArgumentError("Only trees with 4 to 7 leaves are supported."))
    for data in TREE_DATA
        if data.n == n && data.id == id
            return make_tree(data.tree)
        end
    end
    nothing
end

function make_tree(tree::Matrix{Symbol})
    var_names = sort(unique(vec(tree)))
    D = Dict(map(v -> (v, DP.PolyVar{true}(String(v))), var_names))
    LCModel(map(v -> D[v], tree))
end

"""
    trees(n)

Return all trees with `n` leaves as a tuple (id, tree).
"""
function trees(n::Int)
    4 ≤ n ≤ 7 || throw(ArgumentError("Only trees with 4 to 7 leaves are supported."))
    map(d -> (id=d.id, tree=make_tree(d.tree)), filter(d -> d.n == n, TREE_DATA))
end


"""
    generic_subspace(n::Integer, m::Integer); pos_def::Bool=true)

Generate a generic family of symmetric ``n×n`` matrices living in an ``m``-dimensional
subspace. If `pos_def` is `true` then positive definite matrices are used as a basis.
"""
function generic_subspace(n::Integer, m::Integer; pos_def::Bool=true)
    m ≤ binomial(n+1,2) || throw(ArgumentError("`m=$m` is larger than the dimension of the space."))
    DP.@polyvar θ[1:m]
    if pos_def
        LCModel(sum(θᵢ .* rand_pos_def(n) for θᵢ in θ))
    else
        LCModel(sum(θᵢ .* Symmetric(randn(n,n)) for θᵢ in θ))
    end
end

"""
    generic_diagonal(n::Integer, m::Integer)

Generate a generic family of ``n×n`` diagonal matrices living in an ``m``-dimensional
subspace.
"""
function generic_diagonal(n::Integer, m::Integer)
    m ≤ n || throw(ArgumentError("`m=$m` is larger than the dimension of the space."))
    DP.@polyvar θ[1:m]
    LCModel(sum(θᵢ .* diagm(0 => randn(n)) for θᵢ in θ))
end


"""
    mle_system(M::LCModel)

Generate the MLE system corresponding to the family of covariances matrices
parameterized by `Σ`.
Returns the named tuple `(system, variables, parameters)`.
"""
function mle_system(M::LCModel)
    Σ = M.Σ
    θ = DP.variables(vec(Σ))
    m = DP.nvariables(θ)
    n = size(Σ, 1)
    N = binomial(n+1,2)

    DP.@polyvar k[1:N] s[1:N]

    K, S = vec_to_sym(k), vec_to_sym(s)
    l = -tr(K * Σ) + tr(S * K * Σ * K)
    ∇l = DP.differentiate(l, θ)
    KΣ_I = vec(K * Σ - Matrix(I, n,n))
    (system=[∇l; KΣ_I], variables=[θ; k], parameters=s)
end

"""
    dual_mle_system(M::LCModel)

Generate the dual MLE system corresponding to the family of covariances matrices
parameterized by `Σ`.
Returns the named tuple `(system, variables, parameters)`.
"""
function dual_mle_system(M::LCModel)
    Σ = M.Σ
    θ = DP.variables(vec(Σ))
    m = DP.nvariables(θ)
    n = size(Σ, 1)
    N = binomial(n+1,2)

    DP.@polyvar k[1:N] s[1:N]

    K, S = vec_to_sym(k), vec_to_sym(s)
    l = -tr(K * Σ) + tr(S * Σ)
    ∇l = DP.differentiate(l, θ)
    KΣ_I = vec(K * Σ - Matrix(I, n,n))
    (system=[∇l; KΣ_I], variables=[θ; k], parameters=s)
end

"""
    mle_system_and_start_pair(M::LCModel)

Generate the mle_system and a corresponding start pair `(x₀,p₀)`.
"""
function mle_system_and_start_pair(M::LCModel)
    system, vars, params = mle_system(M)
    θ = DP.variables(vec(M.Σ))
    θ₀ = randn(ComplexF64, length(θ))
    Σ₀ = [p(θ => θ₀) for p in M.Σ]
    K₀ = inv(Σ₀)
    x₀ = [θ₀; sym_to_vec(K₀)]
    A, b = HC.linear_system(DP.subs.(system[1:length(x₀)], Ref(vars => x₀)), params)
    p₀ = A \ b

    (system=system, x₀=x₀, p₀=p₀, variables=vars, parameters=params)
end

"""
    dual_mle_system_and_start_pair(M::LCModel)

Generate the dual MLE system and a corresponding start pair `(x₀,p₀)`.
"""
function dual_mle_system_and_start_pair(M::LCModel)
    system, vars, params = dual_mle_system(M)
    θ = DP.variables(vec(M.Σ))
    θ₀ = randn(ComplexF64, length(θ))
    Σ₀ = [p(θ => θ₀) for p in M.Σ]
    K₀ = inv(Σ₀)
    x₀ = [θ₀; sym_to_vec(K₀)]
    A, b = HC.linear_system(DP.subs.(system[1:length(x₀)], Ref(vars => x₀)), params)
    p₀ = A \ b

    (system=system, x₀=x₀, p₀=p₀, variables=vars, parameters=params)
end

"""
    MLDegreeWitness

Data structure holding an MLE model. This also holds a set of solutions for a generic instance,
which we call a witness.
"""
struct MLDegreeWitness{T1, T2, V<:AbstractVector}
    model::LCModel{T1,T2}
    solutions::Vector{V}
    p::Vector{ComplexF64}
    dual::Bool
end


function MLDegreeWitness(Σ::AbstractMatrix, solutions, p, dual)
    MLDegreeWitness(LCModel(Σ), solutions, p, dual)
end

function Base.show(io::IO, R::MLDegreeWitness)
    println(io, "MLDegreeWitness:")
    println(io, " • ML degree → $(length(R.solutions))")
    println(io, " • model dimension → $(dim(model(R)))")
    println(io, " • dual → $(R.dual)")
end

"""
    model(W::MLDegreeWitness)

Obtain the model corresponding to the `MLDegreeWitness` `W`.
"""
model(R::MLDegreeWitness) = R.model

"""
    solutions(W::MLDegreeWitness)

Obtain the witness solutions corresponding to the `MLDegreeWitness` `W`
with given parameters.
"""
solutions(W::MLDegreeWitness) = W.solutions

"""
    parameters(W::MLDegreeWitness)

Obtain the parameters of the `MLDegreeWitness` `W`.
"""
parameters(W::MLDegreeWitness) = W.p

"""
    is_dual(W::MLDegreeWitness)

Indicates whether `W` is a witness for the dual MLE.
"""
is_dual(W::MLDegreeWitness) = W.dual

"""
    ml_degree(W::MLDegreeWitness)

Returns the ML degree.
"""
ml_degree(W::MLDegreeWitness) = length(solutions(W))


"""
    ml_degree_witness(Σ::LCModel; ml_degree=nothing, max_tries=5, dual=false)

Compute a [`MLDegreeWitness`](@ref) for a given model Σ. If the ML degree is already
known it can be provided to stop the computations early. The stopping criterion is based
on a heuristic, `max_tries` indicates how many different parameters are tried a most until
an agreement is found.
"""
ml_degree_witness(Σ; kwargs...) = ml_degree_witness(LCModel(Σ); kwargs...)
function ml_degree_witness(M::LCModel; ml_degree=nothing, max_tries = 5, dual=false)
    if dual
        F, x₀, p₀, x, p = dual_mle_system_and_start_pair(M)
    else
        F, x₀, p₀, x, p = mle_system_and_start_pair(M)
    end
    result = HC.monodromy_solve(F, x₀, p₀; target_solutions_count=ml_degree,
                                            parameters=p, max_loops_no_progress=5)
    if HC.nsolutions(result) == ml_degree
        return MLDegreeWitness(M, HC.solutions(result), result.parameters, dual)
    end

    best_result = result
    result_agreed = false
    for i in 1:max_tries
        q₀ = randn(ComplexF64, length(p₀))
        S_q₀ = HC.solutions(HC.solve(F, HC.solutions(result); parameters=p, start_parameters=p₀, target_parameters=q₀))
        new_result = HC.monodromy_solve(F, S_q₀, q₀; parameters=p, max_loops_no_progress=3)
        if HC.nsolutions(new_result) == HC.nsolutions(best_result)
            result_agreed = true
            break
        elseif HC.nsolutions(new_result) > HC.nsolutions(best_result)
            best_result = new_result
        end
    end
    MLDegreeWitness(M, HC.solutions(best_result), best_result.parameters, dual)
end


"""
    verify(W::MLDegreeWitness; trace_tol=1e-5, options...)

Tries to verify that the computed ML degree witness is complete, i.e., that
the ML degree is correct. This uses the [`verify_solution_completeness`](https://www.juliahomotopycontinuation.org/HomotopyContinuation.jl/stable/monodromy/#HomotopyContinuation.verify_solution_completeness)
of HomotopyContinuation.jl. All caveats mentioned there apply.
The `options` are also passed to `verify_solution_completeness`.
"""
function verify(W::MLDegreeWitness; trace_tol=1e-5, kwargs...)
    if W.dual
        F, var, params = dual_mle_system(model(W))
    else
        F, var, params = mle_system(model(W))
    end
    HC.verify_solution_completeness(F, solutions(W), parameters(W); parameters=params, trace_tol=trace_tol, kwargs...)
end

"""
    critical_points(W::MLDegreeWitness, S::AbstractMatrix;
            only_positive_definite=true, only_non_negative=false,
            options...)

Compute all critical points to the MLE problem of `W` for the given sample covariance matrix
`S`. If `only_positive_definite` is `true` only positive definite solutions are considered.
If `only_non_negative` is `true` only non-negative solutions are considered.
The `options` are argument passed to the [`solve`](https://www.juliahomotopycontinuation.org/HomotopyContinuation.jl/stable/solving/#HomotopyContinuation.solve) routine from `HomotopyContinuation.jl`.
"""
function critical_points(W::MLDegreeWitness, S::AbstractMatrix;
               only_positive_definite=true, only_non_negative=false, kwargs...)
    issymmetric(S) || throw("Sample covariance matrix `S` is not symmetric. Consider wrapping it in `Symmetric(S)` to enforce symmetry.")
    if W.dual
        F, var, params = dual_mle_system(model(W))
    else
        F, var, params = mle_system(model(W))
    end
    result = HC.solve(F, solutions(W); parameters=params,
                         start_parameters=W.p,
                         target_parameters=sym_to_vec(S),
                         kwargs...)

    m = size(model(W), 2)
    θs = map(s -> s[1:m], HC.real_solutions(result))
    if only_positive_definite
        filter!(θs) do θ
            isposdef(covariance_matrix(model(W), θ))
        end
    end

    if only_non_negative
        filter!(θs) do θ
            all(covariance_matrix(model(W), θ) .≥ 0)
        end
    end

    res = map(θs) do θ
        (θ, logl(model(W), θ, S), classify_point(model(W), θ, S))
    end

    if !isempty(res)
        best_val = maximum(θs)
        for i in 1:length(res)
            if first(res[i]) == best_val && res[i][3] == :local_maximum
                res[i] = (res[i][1], res[i][2], :global_maximum)
            end
        end
    end
    res
end

"""
    covariance_matrix(M::LCModel, θ)

Compute the covariance matrix corresponding to the value of `θ` and the given model
`M`.
"""
covariance_matrix(W::MLDegreeWitness, θ) = covariance_matrix(model(W), θ)
covariance_matrix(M::LCModel, θ) = sum(θ[i] * M.B[i] for i in 1:size(M,2))


"""
    logl(M::LCModel, θ, S::AbstractMatrix)

Evaluate the log-likelihood ``log(det(Σ⁻¹)) - tr(SΣ⁻¹)`` of the MLE problem.
"""
function logl(M::LCModel, θ, S::AbstractMatrix)
    logl(covariance_matrix(M, θ), S)
end
logl(Σ::AbstractMatrix, S::AbstractMatrix) = -logdet(Σ) - tr(S*inv(Σ))

"""
    gradient_logl(M::LCModel, θ, S::AbstractMatrix)

Evaluate the gradient of the log-likelihood ``log(det(Σ⁻¹)) - tr(SΣ⁻¹)`` of the MLE problem.
"""
gradient_logl(M::LCModel, θ, S::AbstractMatrix) = gradient_logl(M.B, θ, S)
function gradient_logl(B::Vector{<:Matrix}, θ, S::AbstractMatrix)
    Σ = sum(θ[i] * B[i] for i in 1:length(B))
    Σ⁻¹ = inv(Σ)
    map(1:length(B)) do i
        -tr(Σ⁻¹ * B[i]) + tr(S *  Σ⁻¹ * B[i] * Σ⁻¹)
    end
end

"""
    hessian_logl(M::LCModel, θ, S::AbstractMatrix)

Evaluate the hessian of the log-likelihood ``log(det(Σ⁻¹)) - tr(SΣ⁻¹)`` of the MLE problem.
"""
hessian_logl(M::LCModel, θ, S::AbstractMatrix) = hessian_logl(M.B, θ, S)
function hessian_logl(B::Vector{<:Matrix}, θ, S::AbstractMatrix)
    m = length(B)
    Σ = sum(θ[i] * B[i] for i in 1:m)
    Σ⁻¹ = inv(Σ)
    H = zeros(eltype(Σ), m, m)
    for i in 1:m, j in i:m
        kernel = Σ⁻¹ * B[i] * Σ⁻¹ * B[j]
        H[i,j] = H[j,i] = tr(kernel) - 2tr(S * kernel * Σ⁻¹)
    end
    Symmetric(H)
end

"""
    classify_point(M::LCModel, θ, S::AbstractMatrix)

Classify the critical point `θ` of the log-likelihood function.
"""
function classify_point(M::LCModel, θ, S::AbstractMatrix)
    H = hessian_logl(M, θ, S)
    emin, emax = extrema(eigvals(H))
    if emin < 0 && emax < 0
        :local_maximum
    elseif emin > 0 && emax > 0
        :local_minimum
    else
        :saddle_point
    end
end


"""
    mle(W::MLDegreeWitness, S::AbstractMatrix; only_positive_definite=true, only_positive=false)

Compute the MLE for the matrix `S` using the MLDegreeWitness `W`.
Returns the parameters for the MLE covariance matrix or `nothing` if no solution was found
satisfying the constraints (see options below).

## Options

* `only_positive_definite`: controls whether only positive definite
covariance matrices should be considered.
* `only_positive`: controls whether only (entrywise) positive covariance matrices
should be considered.
"""
function mle(W::MLDegreeWitness, S::AbstractMatrix; only_positive_definite=true, only_positive=false, kwargs...)
    is_dual(W) && throw(ArgumentError("`mle` is currently only supported for MLE not dual MLE."))
    results = critical_points(W, S; kwargs...)
    ind = findfirst(r -> r[3] == :global_maximum, results)
    isnothing(ind) ? nothing : results[ind][1]
end

end # module
