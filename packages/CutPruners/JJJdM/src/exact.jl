export exactpruning!

# Exact pruning
"""
    exactpruning!(man::AbstractCutPruner, solver::MathProgBase.AbstractMathProgSolver;
                  ub=Inf, lb=-Inf, epsilon=1e-5)


Remove dominated cuts in CutPruner `man`.

We use a LP solver to determine whether a cut is dominated or not.

# Arguments
* `man::AbstractCutPruner`
    Cut pruner where to remove cuts
* `solver`
    Solver used to solve LP
* `ub::Union{Float64, Vector{Float64}}`
    State x upper bound
* `lb::Union{Float64, Vector{Float64}}`
    State x lower bound
* `epsilon::Float64`
    Pruning's tolerance
"""
function exactpruning!(man::AbstractCutPruner, solver::MathProgBase.AbstractMathProgSolver; ub=Inf, lb=-Inf, epsilon=1e-5)
    K = getdominated(man.A, man.b, man.islb, man.isfun, solver, lb, ub, epsilon)
    removecuts!(man, K)
end

"""Return dominated cuts."""
function getdominated(A, b, islb, isfun, solver, lb, ub, epsilon)
    red = Int[]
    if size(A, 1) == 1
        return red
    end
    for i in 1:size(A, 1)
        if isdominated(A, b, islb, isfun, i, solver, lb, ub, epsilon)
            push!(red, i)
        end
    end
    red
end

"""State whether a cut is dominated with a tolerance epsilon."""
function isdominated(A, b, islb, isfun, k, solver, lb, ub, epsilon)
    # we use MathProgBase to solve the test
    # For instance, if islb & isfun, the LP becomes:
    # min - y
    #     x ∈ R^n, y ∈ R
    #     y <= (A[k, :] - A[i, :])*x + b[k] - b[i]     ∀ i != k

    # we formulate an equivalent problem as
    # min c'*z
    # s.t H*z <= h

    # get problem's dimension
    ncuts, nx = size(A)
    # allocate arrays
    h = zeros(ncuts - 1)
    H = zeros(ncuts - 1, nx + 1)
    c = zeros(nx + 1)
    c[1] = (islb) ? -1 : 1

    λk = @view A[k, :]

    ic = 0
    for ix in 1:ncuts
        if ix != k
            ic += 1
            δb = b[k] - b[ix]
            @inbounds h[ic] = ((isfun&islb) || (~isfun&~islb)) ? δb : -δb
            @inbounds H[ic, 1] = (islb) ? 1 : -1

            for jx in 1:nx
                dl = A[ix, jx] - λk[jx]
                @inbounds H[ic, jx+1] = (islb) ? dl : -dl
            end
        end
    end

    # update lower and upper bound if Vector
    lbx = isa(lb, Vector) ? vcat(-Inf, lb) : lb
    ubx = isa(ub, Vector) ? vcat( Inf, ub) : ub

    # solve the LP with MathProgBase
    res = linprog(c, H, -Inf, h, lbx, ubx, solver)
    if res.status == :Optimal
        res = res.objval
        return (islb) ? -res < epsilon : res > -epsilon
    else
        return false
    end
end
