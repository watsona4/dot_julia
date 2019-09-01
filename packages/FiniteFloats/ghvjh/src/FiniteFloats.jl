module FiniteFloats

export AbstractFinite,
       Finite64, Finite32, Finite16,
       finite,
       typemaxneg, typeminneg,
       square, cube 

import Base: hash, promote_rule, convert,
    string, show, 
    typemax, typemin, floatmax, floatmin,
    significand, exponent, precision,
    unsigned, signed, float,
    prevfloat, nextfloat, isequal, isless,
    (==), (!=), (<), (<=), (>=), (>),
    (+), (-), (*), (/), (^),
    inv, div, rem, fld, mod, cld,
    round, trunc, ceil, floor,
    abs, signbit, copysign, flipsign, sign,
    frexp, ldexp, modf,
    min, max, minmax,
    clamp, sqrt, cbrt, hypot,
    exp, expm1, exp2, exp10,
    log, log1p, log2, log10,
    rad2deg, deg2rad, mod2pi, rem2pi,
    sin, cos, tan, csc, sec, cot,
    asin, acos, atan, acsc, asec, acot,
    sinh, cosh, tanh, csch, sech, coth,
    asinh, acosh, atanh, acsch, asech, acoth,
    sincos, sinc, sinpi, cospi,
    sind, cosd, tand, cscd, secd, cotd,
    asind, acosd, atand, acscd, asecd, acotd

import LinearAlgebra
import LinearAlgebra: adjoint, adjoint!, axpby!, axpy!,
          bunchkaufman, bunchkaufman!, cholesky, cholesky!,
          cond, condskeel, copy_transpose!,
          copyto!, cross, det, diag, diagind, diagm, dot,
          eigen, eigen!, eigmax, eigmin, eigvals,
          eigvals!, eigvecs, factorize, fill!,
          hessenberg, hessenberg!,
          isdiag, ishermitian, isposdef, isposdef!,
          issuccess, issymmetric, istril, istriu, kron, ldiv!,
          ldlt, ldlt!, lmul!, logabsdet, logdet,
          lowrankdowndate, lowrankdowndate!, lowrankupdate,
          lowrankupdate!, lq, lq!, lu, lu!, 
          lyap, mul!, norm, normalize, normalize!, nullspace,
          opnorm, ordschur, ordschur!, pinv, qr, qr!,
          rank, rdiv!, rmul!, schur, schur!,
          svd, svd!, svdvals, svdvals!, sylvester,
          tr, transpose, transpose!,
          tril, tril!, triu, triu!

include("types.jl")

include("linearalgebra_types.jl")
include("linearalgebra.jl")

end # FiniteFloats
