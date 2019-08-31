module ApproxFunOrthogonalPolynomials
using Base, LinearAlgebra, Reexport, BandedMatrices, BlockBandedMatrices, AbstractFFTs, FFTW, InfiniteArrays, BlockArrays, FillArrays, FastTransforms, IntervalSets, 
            DomainSets, Statistics, SpecialFunctions, FastGaussQuadrature
            
@reexport using ApproxFunBase

import AbstractFFTs: Plan, fft, ifft
import FFTW: plan_r2r!, fftwNumber, REDFT10, REDFT01, REDFT00, RODFT00, R2HC, HC2R,
                r2r!, r2r,  plan_fft, plan_ifft, plan_ifft!, plan_fft!

import ApproxFunBase: normalize!, flipsign, FiniteRange, Fun, MatrixFun, UnsetSpace, VFun, RowVector,
                    UnivariateSpace, AmbiguousSpace, SumSpace, SubSpace, WeightSpace, NoSpace, Space,
                    HeavisideSpace, PointSpace,
                    IntervalOrSegment, RaggedMatrix, AlmostBandedMatrix,
                    AnyDomain, ZeroSpace, ArraySpace, TrivialInterlacer, BlockInterlacer, 
                    AbstractTransformPlan, TransformPlan, ITransformPlan,
                    ConcreteConversion, ConcreteMultiplication, ConcreteDerivative, ConcreteIntegral,
                    ConcreteVolterra, Volterra, VolterraWrapper,
                    MultiplicationWrapper, ConversionWrapper, DerivativeWrapper, Evaluation, EvaluationWrapper,
                    Conversion, defaultConversion, defaultcoefficients, default_Fun, Multiplication, Derivative, Integral, bandwidths, 
                    ConcreteEvaluation, ConcreteDefiniteLineIntegral, ConcreteDefiniteIntegral, ConcreteIntegral,
                    DefiniteLineIntegral, DefiniteIntegral, ConcreteDefiniteIntegral, ConcreteDefiniteLineIntegral, IntegralWrapper,
                    ReverseOrientation, ReverseOrientationWrapper, ReverseWrapper, Reverse, NegateEven, Dirichlet, ConcreteDirichlet,
                    TridiagonalOperator, SubOperator, Space, @containsconstants, spacescompatible,
                    hasfasttransform, canonicalspace, domain, setdomain, prectype, domainscompatible, 
                    plan_transform, plan_itransform, plan_transform!, plan_itransform!, transform, itransform, hasfasttransform, 
                    CanonicalTransformPlan, ICanonicalTransformPlan,
                    Integral, 
                    domainspace, rangespace, boundary, 
                    union_rule, conversion_rule, maxspace_rule, conversion_type, maxspace, hasconversion, points, 
                    rdirichlet, ldirichlet, lneumann, rneumann, ivp, bvp, 
                    linesum, differentiate, integrate, linebilinearform, bilinearform, 
                    UnsetNumber, coefficienttimes, subspace_coefficients, sumspacecoefficients, specialfunctionnormalizationpoint,
                    Segment, IntervalOrSegmentDomain, PiecewiseSegment, isambiguous, Vec, eps, isperiodic,
                    arclength, complexlength,
                    invfromcanonicalD, fromcanonical, tocanonical, fromcanonicalD, tocanonicalD, canonicaldomain, setcanonicaldomain, mappoint,
                    reverseorientation, checkpoints, evaluate, extrapolate, mul_coefficients, coefficients, isconvertible,
                    clenshaw, ClenshawPlan, sineshaw,
                    toeplitz_getindex, toeplitz_axpy!, sym_toeplitz_axpy!, hankel_axpy!, ToeplitzOperator, SymToeplitzOperator, hankel_getindex, 
                    SpaceOperator, ZeroOperator, InterlaceOperator,
                    interlace!, reverseeven!, negateeven!, cfstype, pad!, alternatesign!, mobius,
                    extremal_args, hesseneigvals, chebyshev_clenshaw, recA, recB, recC, roots,splitatroots,
                    chebmult_getindex, intpow, alternatingsum,
                    domaintype, diagindshift, rangetype, weight, isapproxinteger, default_Dirichlet, scal!, dotu,
                    components, promoterangespace, promotedomainspace,
                    block, blockstart, blockstop, blocklengths, isblockbanded, pointscompatible, affine_setdiff, complexroots,
                    ℓ⁰, recα, recβ, recγ

import DomainSets: Domain, indomain, UnionDomain, ProductDomain, FullSpace, Point, elements, DifferenceDomain,
            Interval, ChebyshevInterval, boundary, ∂, rightendpoint, leftendpoint,
            dimension, WrappedDomain
            
import BandedMatrices: bandrange, bandshift,
                inbands_getindex, inbands_setindex!, bandwidth, AbstractBandedMatrix,
                colstart, colstop, colrange, rowstart, rowstop, rowrange,
                bandwidths, _BandedMatrix, BandedMatrix            

import Base: values, convert, getindex, setindex!, *, +, -, ==, <, <=, >, |, !, !=, eltype, iterate,
                >=, /, ^, \, ∪, transpose, size, tail, broadcast, broadcast!, copyto!, copy, to_index, (:),
                similar, map, vcat, hcat, hvcat, show, summary, stride, sum, cumsum, sign, imag, conj, inv,
                complex, reverse, exp, sqrt, abs, abs2, sign, issubset, values, in, first, last, rand, intersect, setdiff,
                isless, union, angle, join, isnan, isapprox, isempty, sort, merge, promote_rule,
                minimum, maximum, extrema, argmax, argmin, findmax, findmin, isfinite,
                zeros, zero, one, promote_rule, repeat, length, resize!, isinf,
                getproperty, findfirst, unsafe_getindex, fld, cld, div, real, imag,
                @_inline_meta, eachindex, firstindex, lastindex, keys, isreal, OneTo,
                Array, Vector, Matrix, view, ones, @propagate_inbounds, print_array,
                split

import LinearAlgebra: BlasInt, BlasFloat, norm, ldiv!, mul!, det, eigvals, dot, cross,
                qr, qr!, rank, isdiag, istril, istriu, issymmetric, ishermitian,
                Tridiagonal, diagm, diagm_container, factorize, nullspace,
                Hermitian, Symmetric, adjoint, transpose, char_uplo                

import InfiniteArrays: Infinity, InfRanges, AbstractInfUnitRange, OneToInf                    

import FastTransforms: ChebyshevTransformPlan, IChebyshevTransformPlan, plan_chebyshevtransform,
                        plan_chebyshevtransform!, plan_ichebyshevtransform, plan_ichebyshevtransform!,
                        pochhammer

import BlockBandedMatrices: blockbandwidths, subblockbandwidths

# we need to import all special functions to use Calculus.symbolic_derivatives_1arg
# we can't do importall Base as we replace some Base definitions
import SpecialFunctions: sinpi, cospi, airy, besselh,
                    asinh, acosh,atanh, erfcx, dawson, erf, erfi,
                    sin, cos, sinh, cosh, airyai, airybi, airyaiprime, airybiprime,
                    hankelh1, hankelh2, besselj, besselj0, bessely, besseli, besselk,
                    besselkx, hankelh1x, hankelh2x, exp2, exp10, log2, log10,
                    tan, tanh, csc, asin, acsc, sec, acos, asec,
                    cot, atan, acot, sinh, csch, asinh, acsch,
                    sech, acosh, asech, tanh, coth, atanh, acoth,
                    expm1, log1p, lfact, sinc, cosc, erfinv, erfcinv, beta, lbeta,
                    eta, zeta, gamma,  lgamma, polygamma, invdigamma, digamma, trigamma,
                    abs, sign, log, expm1, tan, abs2, sqrt, angle, max, min, cbrt, log,
                    atan, acos, asin, erfc, inv

include("ultraspherical.jl")
include("Domains/Domains.jl")
include("Spaces/Spaces.jl")
include("roots.jl")
include("specialfunctions.jl")
include("fastops.jl")

end
