"""
The module provides example calculations for the second edition
of the book

> Kriele M. and Wolf, J.
> _Wertorientiertes Risikomanagement von Versicherungsunternehmen_,
>  2nd edition, Springer-Verlag, Berlin Heidelberg,  2016
> (to be published)

It is also intended to use these examples for future editions of
the English  translation of this book,
_Value-Oriented Risk Management of Insurance Companies_.
(The examples in both the first German edition and the first
 English edition are written in R).

The module consists of 4 distinct parts:

  - *SSTLife*: An extremely simplified example of the SST
(Swiss Solvency Test) calculation for life insurance.
The Swiss Solvency Test is the Swiss regulatory capital
requirement.  The resulting monetary requirement is referred
to as the "target capital" `ZK`.
  - *S2Life*: A simplified example of the S2 (Solvency 2)
calculation for non-life insurance. Solvency 2 is the new
regulatory capital requirement in the European Union. The
resulting monetary requirement is referred to as the
"Solvency capital requirement" `SCR`.
  - *S2NonLife*: A simplified example of the S2 calculation
for life insurance
  - *ECModel*: An extremely simplified example of an internal
economic capital model for non-life insurance. This model is
used to illustrate some techniques used in value based
management.

Note that we have simplified and (in part changed for our
exposition) the regulatory requirements for SST and Solvency 2.
Also note that the implementation of Solvency 2 may be slightly
different in different EU countries. For definitive information
about SST or Solvency 2, please consult the original literature
and any guidance issued by the supervisory authorities in the
jurisdiction of interest.
"""
module ValueOrientedRiskManagementInsurance

export es

using Distributions
using DataFrames#, DataArrays
using LinearAlgebra
using Random

# import Base.show, Base.isequal
# import Base.merge!
import Distributions.rand
import LinearAlgebra.⋅

## General functions --------------------------------------------
## Expected shortfall
es(x, α) =
  mean(sort(x, rev = true)[1:ceil(Integer, (1 - α) * length(x))])

# Simplfied Swiss Solvency Test----------------------------------
include("SST/SST__Types.jl")
include("SST/SST_Functions.jl")

# Simplified Life insurer ---------------------------------------
include("Life/Life__Types.jl")
include("Life/Life_Constructors.jl")
include("Life/Life_Functions.jl")

# Simplified Solvency 2 Life ------------------------------------
include("S2Life/S2Life__Types.jl")
include("S2Life/S2Life_Constructors.jl")
include("S2Life/S2Life_Functions.jl")

# Simplified Solvency 2 Non-Life --------------------------------
include("S2NonLife/S2NonLife__Types.jl")
include("S2NonLife/S2NonLife_Functions.jl")

# Simple economic capital model ---------------------------------
include("ECModel/ECModel__Types.jl")
include("ECModel/ECModel_Functions.jl")

end # module
