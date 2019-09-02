module MultRoot
using Polynomials
import PolynomialRoots
using LinearAlgebra
include("../utils.jl")
## The main function here is `MultRoot.multroot`

## Polynomial root finder for polynomials with multiple roots
##
## Based on "Computing multiple roots of inexact polynomials"
## https://doi.org/10.1090/S0025-5718-04-01692-8
## Author: Zhonggang Zeng
## Journal: Math. Comp. 74 (2005), 869-903
##
## Zeng has a MATLAB package `multroot`, from which this name is derived.
## Basic idea is
## 1) for polynomial p we do gcd decomposition p = u * v; p' = u * w. Then roots(v) are the roots without multiplicities.
## 2) can repeat with u to get multiplicities.
##
## This is from Gauss, as explained in paper. Zeng shows how to get u,v,w when the polynomials
## are inexact due to floating point approximations or even model error. This is done in his
## algorithm II.
## 3) Zeng's algorithm I (pejroot) uses the pejorative manifold of Kahan and Gauss-Newton to
## improve the root estimates from algorithm II (roots(v)). The pejorative manifold is defined by
## the multiplicities l and is operationalized in evalG and evalJ from Zeng's paper.


using ..AGCD
monic(p) = p/p[end]
rcoeffs(p) = reverse(p.a)
function proots(zs)
    rs = PolynomialRoots.roots(zs)
    if all(iszero.(imag(rs)))
        return real.(rs)
    else
        return rs
    end
end


## map monic(p) to a point in C^n
## p = 1x^n + a1x^n-1 + ... + an_1 x + an -> (a1,a2,...,an)
function p2a(p::Poly)
    p = monic(p)
    rcoeffs(p)[2:end]
end
function p2a(p::Vector{T}) where {T}
    a,pn = reverse(p[1:end-1]),p[end]
    a .* (1/p[end])
end


## get value of gl(z). From p16
function evalG(zs::Vector, ls::Vector)
    length(zs) == length(ls) || throw("Length mismatch")

    s = prod([poly([z])^l for (z,l) in zip(zs, ls)])  # \prod (x-z_i)^l_i
    p2a(s)
#    rcoeffs(s)[2:end]
end

## get jacobian J_l(z), p16

## get jacobian J_l(z), p16
function evalJ!(J, zs::Vector{T}, ls::Vector) where {T}
    length(zs) == length(ls) || throw("Length mismatch")

    n, m = sum(ls), length(zs)
    u = evalG(zs, ls .- 1)
    pushfirst!(u, one(T))

#    x = Polynomials.variable(T)
#    u = prod((x-z)^(l-1) for (z,l) in zip(zs, ls))  # \prod (x-z_i)^l_i


    for j in 1:m
        s = -ls[j] * u

        for (l, zl) in zip(1:m, zs)
            l == j && continue
            s = AGCD._polymul(s, (one(T), -zl))
        end
    J[:,j] = s#rceffs(s)
    end
    J
end
function evalJ(zs::Vector{T}, ls) where {T}
    n, m = sum(ls), length(zs)
    J = zeros(T, n, m)
    evalJ!(J, zs, ls)
    J
end

## Gauss-Newton iteration to solve weighted least squares problem
## G_l(z) = a, where a is related to monic version of polynomial p
## l is known multiplicity structure of polynomial p = (x-z1)^l1 * (x-z2)^l2 * ... * (x-zn)^ln
## Algorithm I, p17
pejroot(p::Poly, z0, ls; kwargs...) = pejroot(Polynomials.coeffs(p), z0, ls; kwargs...)
function pejroot(p::Vector{T}, z0::Vector{S}, l::Vector{Int};
                 wts::Union{Vector, Nothing}=nothing, # weight vector
                 τ = sqrt(eps(real(T))),
                 maxsteps = 100
                 ) where {T, S <: Union{T, Complex{T}}}


    a = p2a(p)
    λ = min(sqrt(eps(real(T))), norm(p,2) * eps(real(T))^(2/3))
    if wts == nothing
        wts = map(aj -> min(1, 1/abs(aj)), a)
    end

    ## Solve WJ Δz = W(Gl(z) - a) in algorithm I
    zk = copy(z0);
    J = evalJ(zk, l)

    deltak = AGCD.weighted_least_square(J, evalG(zk,l).-a, wts)
    zk .-=  deltak
    δ0 = norm(deltak, 2)

    cvg = false

    for ctr in 1:maxsteps

        AGCD.weighted_least_square!(deltak, evalJ!(J, zk,l), evalG(zk,l).-a, wts)
        zk .-= deltak
        δ1 = norm(deltak, 2)


        Δ = δ0 - δ1

        if Δ < 0 && ctr > 2
            @debug "Growing delta. Best guess is being returned."
            break
        end

        ## add extra abs(delta) < 100*eps() condition
        if δ1^2 < Δ * τ# || δ1 < λ
            cvg = true
            break
        end

        δ0 = δ1
    end

    if !cvg @info ("""The multiplicity count may be in error--the initial guess for the roots failed to improve when refined along the pejorative manifold.""")
        return(z0)
    end
    return(zk)
end


"""
        identify_z0s_ls(p; ...)

Step one of the algorithm identifies initial guesses for the roots and
identifies the pejorative manifold.

"""
function identify_z0s_ls(p::Vector{T};
                         θ::Real=sqrt(eps(real(T))),
                         ρ::Real=cbrt(eps(real(T)))*θ, # initial residual tolerance
                         ϕ::Real=100.0,          # residual tolerance growth factor
                         precondition = false
                         ) where {T}



    q = AGCD._polyder(p)
    if precondition
        p,q, phi, alpha = AGCD.precondition(p,AGCD._polyder(p))
    else
        phi = one(T)
    end

    u_j, v_j, w_j, residual = AGCD.agcd(p, q, θ=θ,  ρ=ρ)


    ## bookkeeping
    ρ = max(ρ, ϕ * norm(residual))
    rs = PolynomialRoots.roots(v_j)
    zs = proots(v_j)
    N = length(zs)
    ls = ones(Int, N)

    p0 = u_j

    while AGCD._degree(p0) > 0

        if AGCD._degree(p0) == 1
            z = proots(p0)[1]
            tmp, ind = findmin(abs.(zs .- z))
            ls[ind] = ls[ind] + 1
            break
        end


        u_j, v_j, w_j, residual= AGCD.agcd(p0, θ=θ, ρ=ρ, maxk=N+1)

        ## need to worry about residual between
        ## u0 * v0 - monic(p0) and u0 * w0 - monic(Polynomials.polyder(p0))
        ## resiudal tolerance grows with m, here it depends on
        ## initial value and previous residual times a growth tolerance, ϕ
        ρ = max(ρ, ϕ * abs(residual))
        ## update multiplicities
        for z in proots(v_j)
            tmp, ind = findmin(abs.(zs .- z))
            ls[ind] = ls[ind] + 1
        end

        ## rename
        p0 = u_j
    end

    # remove preconditioning from roots
    phi * zs, ls, ρ

end

"""
    multroot(p; [θ, ρ, ϕ, δ])

Find roots of polynomial `p`,

The `multroot` function returns the roots and their multiplicities
for `Poly` objects. It performs better than `roots` when the
polynomial has multiplicities.

Based on "Computing multiple roots of inexact polynomials"
Zhonggang Zeng
Journal: Math. Comp. 74 (2005), 869-903
https://doi.org/10.1090/S0025-5718-04-01692-8

Zeng has a MATLAB package `multroot`, from which this name is derived.

Basic idea is:
* for polynomial p we do gcd decomposition p = u * v; p' = u * w. Then roots(v) are the roots without multiplicities.
* can repeat with u to get multiplicities.

The basic idea is from Gauss, as explained in paper. Zeng shows how to get u,v,w when the polynomials
are inexact due to floating point approximations or even model error. This is done in his
algorithm II.

Zeng's algorithm I (pejroot) uses the pejorative manifold of Kahan and Gauss-Newton to
improve the root estimates from algorithm II (roots(v)). The pejorative manifold is defined by
the multiplicities l and is operationalized in `evalG` and `evalJ` from Zeng's paper.

Examples:
```
x = poly([0.0]);
p = (x-1)^4 * (x-2)^3 * (x-3)^3 * (x-4)
multroot(p) # ([4.0, 3.0, 2.0, 1.0], [1, 3, 3, 4])

## For "prettier" printing, results can be coerced to a dict
Dict(k=>v for (k, v) in zip(multroot(p)...))
## Dict{Float64,Int64} with 4 entries:
##   4.0 => 1
##   2.0 => 3
##   1.0 => 4
##   3.0 => 3

## compare to
roots(p)
# 11-element Array{Complex{Float64},1}:
#   4.000000000049711 + 0.0im
#   3.000340992482669 + 0.0005901104690775108im
#   3.000340992482669 - 0.0005901104690775108im
#  2.9993180137669726 + 0.0im
#  2.0006129094631833 + 0.0im
#  1.9996935459268157 + 0.0005303204210266187im
#  1.9996935459268157 - 0.0005303204210266187im
#  1.0006651061397798 + 0.00066713538542472im
#  1.0006651061397798 - 0.00066713538542472im
#  0.9993348938107887 + 0.0006630950464016094im
#  0.9993348938107887 - 0.0006630950464016094im

## Large order polynomials prove difficult. We can't match the claims in Zeng's paper
## as we don't get the pejorative manifold structure right.
p = poly(1.0:7.0);
multroot(p^2) ## should be 1,2,3,4,...,7 all with multplicity 2, but
## ([7.00028, 6.99972, 6.00088, 5.99912, 5.00102, 4.99898, 4.00055, 3.99945, 3.00014, 2.99986, 2.00002, 1.99998, 1.0, 0.999999], [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])

## nearby roots can be an issue
delta = 0.00001  ## delta = 0.0001 works as desired.
p = (x-1 - delta)*(x-1)*(x-1 + delta)
multroot(p)
## ([1.0], [3])
```
"""
function multroot(ps::Vector{T};
                  θ::Real=1e-2 * sqrt(eps(real(T))),      # 1e-8 in paper
                  ρ::Real=(eps(real(T)))^(5/6), # 1e-10 in paper
                  ϕ::Real=100.0,             # residual tolerance growth factor
                  τ::Real= θ,       # passed to solve y sigma
                  precondition=true
                  ) where {T}

    p = float.(ps[1:findlast(!iszero,ps)])

    # simple cases
    AGCD._degree(p) == 0 && error("Degree of `p` must be atleast 1")
    if AGCD._degree(p) == 1
        return (-p[1:1]/p[end], [1])
    end

    # two steps
    zs, ls, rho = identify_z0s_ls(p, θ=θ, ρ=ρ, ϕ=ϕ, precondition=precondition)

    if maximum(ls) > 1
        zs = pejroot(p, zs, ls, τ=τ)
    end

    return (zs, ls)

end

## Different interfaces

## can pass in Poly too
multroot(p::Poly; kwargs...) = multroot(Polynomials.coeffs(p); kwargs...)
## Can pass in function
multroot(f::Function; kwargs...) = multroot(as_poly(Float64, f); kwargs...)


end
