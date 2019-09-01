const MAX_REPETITIONS = 128

"""

The default maximum number of repetitions of a full period of a DutyCycle that
will be "unrolled" to combine two DutyCycles with different periods to
a common period or approximation thereof.

"""

default_maxrepetitions(::Any) = MAX_REPETITIONS

const DEFAULT_PERIOD = Measurements.measurement(20, 1e-6) * Unitful.ms

"""

Return the default period for any DutyCycle with no period
specified. Corresponds to 50 Hz, the electrical grid frequency in
Europe, with some arbitrarily chosen uncertainty to enforce incoherent
behavior with DutyCycle objects with a specified period (if that comes
from a different source).

!!! note
    This period is used to promote non-dutycycles to DutyCycles: By
    default all values are assumed to "cycle" through a constant value
    at 50 Hz.

!!! info "Design Rationale"
    Giving all duty cycles a (slightly) uncertain period ensures that
    coherence and incoherence can be modelled even using values that
    come with no information regarding their temporal
    variation. Assuming them to actually be constant in time ensures
    consistency and allows upgrading code that uses "normal" (constant
    in time) numbers to use dutycycles.

To change this default behavior, provide a method taking one argument
(the value being promoted to a DutyCycle) to return the period to be
used in that instance. For example, the following code changes the
default to use a period corresponding to a 60 Hz (instead of 50 Hz)
frequency:

```jldoctest
using DutyCycles, Unitful
using Unitful: Ω, mA, Hz
DutyCycles.default_period(::Number) = 50Hz/60Hz*default_period()
I = dutycycle(0.5, onvalue = 50mA)
U = dutycycle(0.5, onvalue = 50Ω * 50mA)
uconvert(Hz, fundamental_frequency(U * I))

# output

60.0 ± 3.0e-6 Hz
```

Another example is changing the default treatmeant of phase coherency
between automatically promoted numbers of behaving coherently to
behaving incoherently:

```jldoctest
using DutyCycles, Unitful, Measurements
using Unitful: Ω, mA, mW, Hz
DutyCycles.default_period(::Number) = 1/((60±3e-6)*Hz)
I = dutycycle(0.5, onvalue = 50mA)
U = dutycycle(0.5, onvalue = 50Ω * 50mA)
uconvert(Hz, fundamental_frequency(U * I))

# output

0.0 Hz
```

The output of a zero frequency (with undefined uncertainty) means that
the DutyCycles were treated incoherently during the multiplication
`U*I`.

"""
default_period(firstvalue::Any) = default_period()
default_period() = DEFAULT_PERIOD
# convert the default period to a requested type U, if possible
default_period(::Type{T}, firstvalue::Any) where {T<:Any} =
    convert_warn(T, default_period(firstvalue), "default period")
