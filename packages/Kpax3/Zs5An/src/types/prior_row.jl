# This file is part of Kpax3. License is MIT.

abstract type PriorRowPartition end

"""
# Ewens-Pitman distribution

## Description

The Ewens-Pitman distribution is a discrete probability distribution on the
partitions of the set N = {1, ..., n} (n = 1, 2, ...). It is a two parameters
generalization of the Ewens sampling formula. The latter is also known as the
Chinese Restaurant Process or as the marginal distribution of a Dirichlet
Process.

## Fields

* `α` Real number (see details)
* `θ` Real number (see details)

## Details

The two parameters must satisfy either
* α < 0 and θ = -Lα for some L ∈ {1, 2, ...}
* 0 ≤ α < 1 and θ > − α

The special case α = 0 and θ > 0 corresponds to the Ewens sampling formula.

## References

Aldous, D. J. (1985) Exchangeability and related topics. In *École d'Été de
Probabilités de Saint-Flour XIII — 1983*. Lecture Notes in Mathematics
**1117**, 1-198. Springer Berlin Heidelberg.
<http://dx.doi.org/10.1007/BFb0099421>.

Gnedin, A. and Pitman, J. (2006) Exchangeable Gibbs partitions and Stirling
triangles. *Journal of Mathematical Sciences* **138**(3), 5674-5685.
<http://dx.doi.org/10.1007/s10958-006-0335-z>.

Kerov, S. (2006) Coherent random allocations, and the Ewens-Pitman formula.
*Journal of Mathematical Sciences*, **138**(3).
<http://dx.doi.org/10.1007/s10958-006-0338-9>.

Pitman, J. (1995) Exchangeable and Partially Exchangeable Random Partitions.
*Probability Theory and Related Fields* **102**(2), 145-158.
<http://dx.doi.org/10.1007%2FBF01213386>.

Pitman, J. (2006) Combinatorial Stochastic Processes. In *Ecole d’Eté de
Probabilités de Saint-Flour XXXII – 2002*. Lecture Notes in Mathematics
**1875**. Springer Berlin Heidelberg. <http://dx.doi.org/10.1007/b11601500>.
"""
abstract type EwensPitman <: PriorRowPartition end

"""
# Ewens-Pitman distribution

## Description

Ewens-Pitman distribution with 0 < α < 1,  θ > -α and θ ≠ 0.

## Fields

* `α` Real number greater than zero and lesser than one
* `θ` Real number greater than `-α` but different from zero
"""
struct EwensPitmanPAUT <: EwensPitman
  α::Float64
  θ::Float64
end

"""
# Ewens-Pitman distribution

## Description

Ewens-Pitman distribution with 0 < α < 1 and θ = 0.

## Fields

* `α` Real number greater than zero and lesser than one
"""
struct EwensPitmanPAZT <: EwensPitman
  α::Float64
end

"""
# Ewens-Pitman distribution

## Description

Ewens-Pitman distribution with α = 0 and θ > 0. This is equivalent to the Ewens
sampling formula.

## Fields

* `θ` Real number greater than zero
"""
struct EwensPitmanZAPT <: EwensPitman
  θ::Float64
end

"""
# Ewens-Pitman distribution

## Description

Ewens-Pitman distribution with α < 0 and θ > 0. θ = -Lα for some
L ∈ {1, 2, ...}.

## Fields

* `α` Real number lesser than zero
* `L` Integer number greater than zero
"""
struct EwensPitmanNAPT <: EwensPitman
  α::Float64
  L::Int
end

# TODO: Julia v0.4
# we can't document this constructor: the type has already been documented

#=
# Constructor of an object of (super)type EwensPitman

## Description

Create an appropriate EwensPitman type according to the arguments' values.

## Usage

EwensPitman(α, θ)

## Arguments

* `α` Real number
* `θ` Real number
=#
function EwensPitman(α::Real,
                     θ::Float64)
  α = float(α)

  if α == zero(Float64)
    if θ > zero(Float64)
      EwensPitmanZAPT(θ)
    else
      throw(KDomainError(string("When argument α is zero, argument θ must be ",
                                "positive.")))
    end
  elseif zero(Float64) < α < one(Float64)
    if θ == zero(Float64)
      EwensPitmanPAZT(α)
    elseif θ > -α
      EwensPitmanPAUT(α, θ)
    else
      throw(KDomainError(string("When argument α is non-negative, argument θ ",
                                "must be greater than -α.")))
    end
  elseif α < zero(Float64)
    throw(KDomainError(string("When argument α is negative, provide an ",
                              "integer L to define parameter θ.")))
  else
    throw(KDomainError("Argument α cannot be greater than or equal to 1."))
  end
end

function EwensPitman(α::Real,
                     L::Int)
  α = float(α)

  if α < zero(Float64)
    if L > zero(Int)
      EwensPitmanNAPT(α, L)
    else
      throw(KDomainError("Argument L must be positive."))
    end
  else
    throw(KDomainError(string("When argument α is non-negative, provide a ",
                              "real value for parameter θ.")))
  end
end
