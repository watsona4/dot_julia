module RiemannHilbert
using Base, ApproxFun, SingularIntegralEquations, DualNumbers, LinearAlgebra,
        SpecialFunctions, FillArrays, DomainSets, FastTransforms, SparseArrays


import DomainSets: UnionDomain, TypedEndpointsInterval

import FastTransforms: ichebyshevtransform!


import SingularIntegralEquations: stieltjesforward, stieltjesbackward, undirected, Directed, stieltjesmoment!, JacobiQ, istieltjes, ComplexPlane, ℂ
import ApproxFunBase: mobius, pieces, npieces, piece, BlockInterlacer, interlacer, pieces_npoints,
                    ArraySpace, tocanonical, components_npoints, ScalarFun, VectorFun, MatrixFun,
                    dimension, evaluate, prectype, cfstype, Space, SumSpace, spacescompatible
import ApproxFunOrthogonalPolynomials: PolynomialSpace, recA, recB, recC, IntervalOrSegmentDomain, IntervalOrSegment

import Base: values, convert, getindex, setindex!, *, +, -, ==, <, <=, >, |, !, !=, eltype,
                >=, /, ^, \, ∪, size, reindex, tail, broadcast, broadcast!,
                isinf, in

# we need to import all special functions to use Calculus.symbolic_derivatives_1arg
# we can't do importall Base as we replace some Base definitions
import Base: sinpi, cospi, exp,
                asinh, acosh,atanh,
                sin, cos, sinh, cosh,
                exp2, exp10, log2, log10,
                tan, tanh, csc, asin, acsc, sec, acos, asec,
                cot, atan, acot, sinh, csch, asinh, acsch,
                sech, acosh, asech, tanh, coth, atanh, acoth,
                expm1, log1p, sinc, cosc,
                abs, sign, log, expm1, tan, abs2, sqrt, angle, max, min, cbrt, log,
                atan, acos, asin, inv, real, imag, abs

import LinearAlgebra: conj, transpose

import SpecialFunctions: airy, besselh, erfcx, dawson, erf, erfi,
                airyai, airybi, airyaiprime, airybiprime,
                hankelh1, hankelh2, besselj, bessely, besseli, besselk,
                besselkx, hankelh1x, hankelh2x, lfact,
                erfinv, erfcinv, erfc, beta, lbeta,
                eta, zeta, gamma,  lgamma, polygamma, invdigamma, digamma, trigamma

import DualNumbers: Dual, realpart, epsilon, dual
import FillArrays: AbstractFill

export cauchymatrix, rhmatrix, rhsolve, ℂ, istieltjes, KdV

include("LogNumber.jl")



function component_indices(it::BlockInterlacer, N::Int, kr::UnitRange)
    ret = Vector{Int}()
    ind = 1
    k_end = last(kr)
    for (M,j) in it
        N == M && j > k_end && return ret
        N == M && j ∈ kr && push!(ret, ind)
        ind += 1
    end
    ret
end


function component_indices(it::BlockInterlacer{NTuple{N,<:AbstractFill{Bool}}}, k::Int, kr::AbstractUnitRange) where N
    b = length(it.blocks)
    k + (first(kr)-1)*b:b:k + (last(kr)-1)*b
end

component_indices(sp::Space, k...) = component_indices(interlacer(sp), k...)

# # function fpstieltjes(f::Fun,z::Dual)
# #     x = mobius(domain(f),z)
# #     if !isinf(mobius(domain(f),Inf))
# #         error("Not implemented")
# #     end
# #     cfs = coefficients(f,Chebyshev)
# #     if realpart(x) ≈ 1
# #         c = -(log(dualpart(x))-log(2)) * sum(cfs)
# #         r = 0.0
# #         for k=2:2:length(cfs)-1
# #             r += 1/(k-1)
# #             c += -r*4*cfs[k+1]
# #         end
# #         r = 1.0
# #         for k=1:2:length(cfs)-1
# #             r += 1/(k-2)
# #             c += -(r+1/(2k))*4*cfs[k+1]
# #         end
# #         c
# #     elseif realpart(x) ≈ -1
# #         v = -(log(-dualpart(x))-log(2))
# #         if !isempty(cfs)
# #             c = -v*cfs[1]
# #         end
# #         r = 0.0
# #         for k=2:2:length(cfs)-1
# #             r += 1/(k-1)
# #             c += r*4*cfs[k+1]
# #             c += -v*cfs[k+1]
# #         end
# #         r = 1.0
# #         for k=1:2:length(cfs)-1
# #             r += 1/(k-2)
# #             c += -(r+1/(2k))*4*cfs[k+1]
# #             c += v*cfs[k+1]
# #         end
# #         c
# #     else
# #         error("Not implemented")
# #     end
# # end
# #
# # fpcauchy(x...) = fpstieltjes(x...)/(-2π*im)
#
#
#
# function stieltjesmatrix(space,pts::Vector,s::Bool)
#     n=length(pts)
#     C=Array(ComplexF64,n,n)
#     for k=1:n
#          C[k,:] = stieltjesforward(s,space,n,pts[k])
#     end
#     C
# end
#
# function stieltjesmatrix(space,pts::Vector)
#     n=length(pts)
#     C=zeros(ComplexF64,n,n)
#     for k=1:n
#         cfs = stieltjesbackward(space,pts[k])
#         C[k,1:min(length(cfs),n)] = cfs
#     end
#
#     C
# end


# stieltjesmatrix(space,n::Integer,s::Bool)=stieltjesmatrix(space,points(space,n),s)
# stieltjesmatrix(space,space2,n::Integer)=stieltjesmatrix(space,points(space2,n))



orientedleftendpoint(d::IntervalOrSegment) = RiemannDual(leftendpoint(d), sign(d))
orientedrightendpoint(d::IntervalOrSegment) = RiemannDual(rightendpoint(d), -sign(d))


# use 2nd kind to include endpoints
collocationpoints(d::IntervalOrSegmentDomain, m::Int) = points(d, m; kind=2)
collocationpoints(d::UnionDomain, ms::AbstractVector{Int}) = vcat(collocationpoints.(pieces(d), ms)...)
collocationpoints(d::UnionDomain, m::Int) = collocationpoints(d, pieces_npoints(d,m))

collocationpoints(sp::Space, m) = collocationpoints(domain(sp), m)


collocationvalues(f::ScalarFun, n) = f.(collocationpoints(space(f), n))
collocationvalues(f::Fun{<:Chebyshev}, n) = ichebyshevtransform!(coefficients(pad(f,n)); kind=2)
function collocationvalues(f::VectorFun, n)
    m = n÷size(f,1)
    mapreduce(f̃ -> collocationvalues(f̃,m), vcat, f)
end
function collocationvalues(f::MatrixFun, n)
    M = size(f,2)
    ret = Array{cfstype(f)}(undef, n, M)
    for J=1:M
        ret[:,J] = collocationvalues(f[:,J], n)
    end
    ret
end

collocationvalues(f::Fun{<:PiecewiseSpace}, n) = vcat(collocationvalues.(components(f), pieces_npoints(domain(f),n))...)

function evaluationmatrix!(E, sp::PolynomialSpace, x)
    x .= tocanonical.(Ref(sp), x)

    E[:,1] .= 1
    E[:,2] .= (recA(Float64,sp,0) .* x .+ recB(Float64,sp,0)) .* view(E,:,1)
    for j = 3:size(E,2)
        E[:,j] .= (recA(Float64,sp,j-2) .* x .+ recB(Float64,sp,j-2)) .* view(E,:,j-1) .- recC(Float64,sp,j-2).*view(E,:,j-2)
    end
    E
end


evaluationmatrix!(E, sp::PolynomialSpace) =
    evaluationmatrix!(E, sp, collocationpoints(sp, size(E,1)))

evaluationmatrix(sp::PolynomialSpace, x, n) =
    evaluationmatrix!(Array{Float64}(undef, length(x), n), sp,x)


function evaluationmatrix!(C, sp::PiecewiseSpace, ns::AbstractVector{Int}, ms::AbstractVector{Int})
    N, M = length(ns), length(ms)
    @assert N == M == npieces(sp)
    n, m = sum(ns), sum(ms)
    @assert size(C) == (n,m)

    C .= 0

    for J = 1:M
        jr = component_indices(sp, J, 1:ms[J])
        k_start = sum(view(ns,1:J-1))+1
        kr = k_start:k_start+ns[J]-1
        evaluationmatrix!(view(C, kr, jr), component(sp, J))
    end

    C
end


function evaluationmatrix!(C, sp::ArraySpace, ns::AbstractVector{Int}, ms::AbstractVector{Int})
    @assert length(ns) == length(ms) == length(sp)
    N = length(ns)

    n, m = sum(ns), sum(ms)
    @assert size(C) == (n,m)

    C .= 0

    for J = 1:N
        jr = component_indices(sp, J, 1:ms[J]) ∩ (1:m)
        k_start = sum(view(ns,1:J-1))+1
        kr = k_start:k_start+ns[J]-1
        evaluationmatrix!(view(C, kr, jr), sp[J])
    end

    C
end

evaluationmatrix!(C, sp::PiecewiseSpace) =
    evaluationmatrix!(C, sp, pieces_npoints(sp, size(C,1)), pieces_npoints(sp, size(C,2)))

evaluationmatrix!(C, sp::ArraySpace) =
    evaluationmatrix!(C, sp, components_npoints(sp, size(C,1)), components_npoints(sp, size(C,2)))


evaluationmatrix(sp::Space, n::Int) = evaluationmatrix!(Array{Float64}(undef,n,n), sp)


function fpstieltjesmatrix!(C, sp, d)
    m, n = size(C)
    pts = collocationpoints(d, m)
    if d == domain(sp)
        stieltjesmoment!(view(C,1,:), sp, Directed{false}(orientedrightendpoint(d)), finitepart)
        for k=2:m-1
            stieltjesmoment!(view(C,k,:), sp, Directed{false}(pts[k]))
        end
        stieltjesmoment!(view(C,m,:), sp, Directed{false}(orientedleftendpoint(d)), finitepart)
    elseif leftendpoint(d) ∈ domain(sp) && rightendpoint(d) ∈ domain(sp)
        stieltjesmoment!(view(C,1,:), sp, orientedrightendpoint(d), finitepart)
        for k=2:m-1
            stieltjesmoment!(view(C,k,:), sp, pts[k])
        end
        stieltjesmoment!(view(C,m,:), sp, orientedleftendpoint(d), finitepart)
    elseif leftendpoint(d) ∈ domain(sp)
        for k=1:m-1
            stieltjesmoment!(view(C,k,:), sp, pts[k])
        end
        stieltjesmoment!(view(C,m,:), sp, orientedleftendpoint(d), finitepart)
    elseif rightendpoint(d) ∈ domain(sp)
        stieltjesmoment!(view(C,1,:), sp, orientedrightendpoint(d), finitepart)
        for k=2:m
            stieltjesmoment!(view(C,k,:), sp, pts[k])
        end
    else
        for k=1:m
            stieltjesmoment!(view(C,k,:), sp, pts[k])
        end
    end
    C
end

fpstieltjesmatrix!(C, sp) = fpstieltjesmatrix!(C, sp, domain(sp))

fpstieltjesmatrix(sp::Space, d::Domain, n::Int, m::Int) =
    fpstieltjesmatrix!(Array{ComplexF64}(undef, n, m), sp, d)

fpstieltjesmatrix(sp::Space, n::Int, m::Int) =
    fpstieltjesmatrix!(Array{ComplexF64}(undef, n, m), sp, domain(sp))


# we group points together by piece
function fpstieltjesmatrix!(C, sp::PiecewiseSpace, ns::AbstractVector{Int}, ms::AbstractVector{Int})
    N, M = length(ns), length(ms)
    @assert N == M == npieces(sp)
    n, m = sum(ns), sum(ms)
    @assert size(C) == (n,m)

    for J = 1:M
        jr = component_indices(sp, J, 1:ms[J])
        k_start = 1
        for K = 1:N
            k_end = k_start + ns[K] - 1
            kr = k_start:k_end
            fpstieltjesmatrix!(view(C, kr, jr), component(sp, J),  domain(component(sp, K)))
            k_start = k_end+1
        end
    end

    C
end


fpstieltjesmatrix(sp::PiecewiseSpace, ns::AbstractVector{Int}, ms::AbstractVector{Int}) =
    fpstieltjesmatrix!(Array{ComplexF64}(undef, sum(ns), sum(ms)), sp, ns, ms)

fpstieltjesmatrix!(C, sp::PiecewiseSpace) = fpstieltjesmatrix!(C, sp, pieces_npoints(sp, size(C,1)), pieces_npoints(sp, size(C,2)))
fpstieltjesmatrix(sp::PiecewiseSpace, n::Int, m::Int) = fpstieltjesmatrix(sp, pieces_npoints(sp, n), pieces_npoints(sp, m))


# we group indices together by piece
function fpstieltjesmatrix(sp::ArraySpace, ns::AbstractArray{Int}, ms::AbstractArray{Int})
    @assert size(ns) == size(ms) == size(sp)
    N = length(ns)

    n, m = sum(ns), sum(ms)
    C = zeros(ComplexF64, n, m)

    for J = 1:N
        jr = component_indices(sp, J, 1:ms[J]) ∩ (1:m)
        k_start = sum(view(ns,1:J-1))+1
        kr = k_start:k_start+ns[J]-1
        fpstieltjesmatrix!(view(C, kr, jr), sp[J])
    end

    C
end

fpstieltjesmatrix(sp::ArraySpace, n::Int, m::Int) =
    fpstieltjesmatrix(sp, reshape(pieces_npoints(sp, n), size(sp)), reshape(pieces_npoints(sp, m), size(sp)))


cauchymatrix(x...) = stieltjesmatrix(x...)/(-2π*im)
function fpcauchymatrix(x...)
    C = fpstieltjesmatrix(x...)
    C ./= (-2π*im)
    C
end

## riemannhilbert
function multiplicationmatrix(G, n)
    N, M = size(G)
    @assert N == M
    sp = space(G)
    ret = spzeros(cfstype(G), n, n)
    m = n ÷ N
    pts = collocationpoints(sp, m)
    for K=1:N,J=1:M
        kr = (K-1)*m .+ (1:m)
        jr = (J-1)*m .+ (1:m)
        V = view(ret, kr, jr)
        view(V, diagind(V)) .= collocationvalues(G[K,J],m)
    end
    ret
end

function rhmatrix(g::ScalarFun, n)
    sp = rhspace(g)
    C₋ = fpcauchymatrix(sp, n, n)
    g_v = collocationvalues(g-1, n)
    E = evaluationmatrix(sp, n)
    C₋ .= g_v .* C₋
    E .- C₋
end

function rhmatrix(g::MatrixFun, n)
    sp = vector_rhspace(g)
    C₋ = fpcauchymatrix(sp, n, n)
    G = multiplicationmatrix(g-I, n)
    E = evaluationmatrix(sp, n)
    E .- G*C₋
end

function rh_sie_solve(G::MatrixFun, n)
    sp = vector_rhspace(G)
    cfs = rhmatrix(G, n) \ (collocationvalues(G-I, n))
    U = hcat([Fun(sp, cfs[:,J]) for J=1:size(G,2)]...)
end

struct RHProblem{GTyp,CM,RHMTyp}
    G::GTyp
    C₋::CM
    RP::RHMTyp
end

# function RHProblem(G)
#     RHProblem(G,

scalar_rhspace(d::AbstractInterval) = Legendre(d)
scalar_rhspace(d::UnionDomain) = PiecewiseSpace(Legendre.(components(d)))
array_rhspace(sz, d::Domain) = ArraySpace(scalar_rhspace(d), sz)
vector_rhspace(sz1, d::Domain) = ArraySpace(scalar_rhspace(d), sz1)
vector_rhspace(f::Fun) = vector_rhspace(size(f,1), domain(f))

rhspace(g::Fun{<:ArraySpace}) = array_rhspace(size(g), domain(g))
rhspace(g::Fun) = scalar_rhspace(domain(g))

rhsolve(g::ScalarFun, n) = 1+cauchy(Fun(rhspace(g), rhmatrix(g, n) \ (collocationvalues(g-1, n))))
function rhsolve(G::MatrixFun, n)
    U = rh_sie_solve(G, n)
    I+cauchy(U)
end



## AffineSpace

struct AffineSpace{DD,RR} <: Space{DD,RR}
    domain::DD
end

AffineSpace(d::Domain) = AffineSpace{typeof(d),prectype(d)}(d)
spacescompatible(::AffineSpace, ::AffineSpace) = true


dimension(::AffineSpace) = 2

function evaluate(v::AbstractVector{T}, s::AffineSpace, x::V) where {T,V}
    @assert length(v) ≤ 2
    (isempty(v) || x ∉ domain(s)) && return zero(promote_type(T,V))
    length(v) == 1 && return v[1] + zero(x)
    v[1] + v[2]*x
end

Fun(::typeof(identity), S::AffineSpace) = Fun(S, [0.0,1.0])
Fun(::typeof(identity), S::ComplexPlane) = Fun(Space(S), [0.0,1.0])

Space(d::ComplexPlane) = AffineSpace(d)

*(φ::Fun, z::Fun{<:AffineSpace}) = z*φ

function *(z::Fun{<:AffineSpace}, φ::Fun{<:JacobiQ})
    a = coefficient(z,1)
    b = coefficient(z,2)
    u = istieltjes(φ)
    x = Fun(domain(u))
    b*sum(u)+stieltjes(a*u + b*x*u)
end

*(z::Fun{<:AffineSpace}, φ::Fun{<:ConstantSpace}) = Fun(space(z),Number(φ)*coefficients(z))
*(z::Fun{<:AffineSpace}, Φ::Fun{<:SumSpace}) = mapreduce(f -> z*f, +, components(Φ))
*(z::Fun{<:AffineSpace}, Φ::Fun{<:ArraySpace}) = Fun(z.*Array(Φ))

include("KdV.jl")



end #module
