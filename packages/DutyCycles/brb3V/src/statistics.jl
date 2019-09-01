# provide functions like mean(::AbstractDutyCycle) and
# rms(::AbstractDutyCycle)

# DO NOT overwrite Statistics.mean as this has different semantics.
"""

Calculate the mean (time-averaged) value of a DutyCycle.

!!! note
    There is already a `mean` function in julia's standard library,
    `Statistics.mean`. It has different semantics: It is used to
    calculate an average from a collection or iteration which could
    make sense to be a DutyCycle itself, so it is one) whilst this
    mean function calculates the time-average of a single
    argument. Naturally, both can be combined as
    `Statistics.mean(DutyCycles.mean, x)` where `x` is the
    collection or iteration of values that can include one or more
    DutyCycle numbers.

"""
function mean(d::DC) where {DC<:AbstractDutyCycle{T,U,V} where {T,U,V}}
    return sum(values(d) .* fractionaltimes(d))
    vals = collect(values(d))
    ft = collect(fractionaltimes(d))
    N = length(vals)
    s = vals[1] * ft[1]
    for i = 2:N
        s += vals[i] * ft[i]
    end
    return s # sum s is already normalized correctly in a valid
             # DutyCycle (due to phase normalization)
end
mean(n::Number) = n
function mean(q::Unitful.AbstractQuantity{T,D,U}) where {T,D,U}
    if T <: AbstractDutyCycle
        units = unit(q)
        return mean((q / units)::T) * units
    else
        return q
    end
end

"""

Calculate the root-mean-squared value of a DutyCycle or a Number
(which is the identity but useful for writing code that does not care
whether it is given a DutyCycle or a Number).

"""
function rms(d::DC) where {DC<:AbstractDutyCycle}
    vals = collect(values(d))
    ft = collect(fractionaltimes(d))
    sumsquares = vals[1]^2 * ft[1]
    for i = 2:length(vals)
        sumsquares += vals[i]^2 * ft[i]
    end
    return sqrt(sumsquares)
end
rms(n::Number) = n
function rms(q::Unitful.AbstractQuantity{T,D,U}) where {T,D,U}
    if T <: AbstractDutyCycle
        units = unit(q)
        unitless = (q / units)::T
        return rms(unitless) * units
    else
        return q
    end
end

"""

Calculate a type-appropriate average (dispatching on the type,
specifically the Unitful.Dimension part) which could be a
root-mean-square (see [`rms`](@ref)) or a simple average, also known
as mean (see [`mean`](@ref)).

To implement this for custom types, see [`autoavgfunc`](@ref).

Note that certain dimensions (units) can have either a "typical" rms
or simple mean average, depending on context. For example, lengths
could be seen as calling for an average when used as a dimension, or
as rms when used as an oscillation amplitude. Here the convention is
followed that electrical currents and voltages have rms averages and
all other units have mean averages.

Note that this function is used implicitly for comparisons involving a
DutyCycle and a normal number.

"""
autoavg(d::AbstractDutyCycle) =
    autoavgfunc(Unitful.NoDims)(d)
autoavg(
    q::Unitful.AbstractQuantity{T,D,U}
) where {T<:AbstractDutyCycle,D,U} =
    autoavgfunc(D)(q)
autoavg(n::Number) = autoavgfunc(dimension(n))(n)

"""

Helper function for [`autoavg`](@ref). Returns a
function that calculates the type appropriate average. Used by
[`Base.show`](@ref) to determine what to print as a summary of the
type appropriate averaging method. Exported for ease of amending with
custom functions.

"""
autoavgfunc(
    ::Any # actually Unitful.Dimensions{(...)}
) = mean # default to mean (normal average)
autoavgfunc(
    # the type as it is probably meant to be in Unitful
    ::Unitful.Dimensions{(Unitful.Dimension{:Current}(1//1))}
) = rms # use root-mean-square (rms) for an electrical current
autoavgfunc(
    # the type as it is actually (currently) implemented in Unitful
    ::Unitful.Dimensions{(Unitful.Dimension{:Current}(1//1), )}
) = rms # use root-mean-square (rms) for an electrical current
autoavgfunc(
    ::Unitful.Dimensions{(
        Unitful.Dimension{:Current}(-1//1),
        Unitful.Dimension{:Length}(2//1),
        Unitful.Dimension{:Mass}(1//1),
        Unitful.Dimension{:Time}(-3//1)
    )}
) = rms # use root-mean-square (rms) for an (electrical) voltage

"""

Calculate the maximum value assumed by a DutyCycle (or another
number). Can be used with a non-empty iterator or a collection and
will then return the absolute minimum value assumed by any of the
items in it.

"""
maxval(itr) = mapreduce(maxval, max, itr)
maxval(arg1::Number, arg2::Number, args::Number...) =
    maxval([arg1; arg2; args...])
maxval(n::Number) =
    maxval(_extractdutycycle(n)) * _extractnondutycycle(n)
maxval(d::AbstractDutyCycle) = maximum(values(d))
maxval(r::Real) = r

"""

Calculate the maximum value assumed by a DutyCycle (or another
number). Can be used with a non-empty iterator or a collection and
will then return the absolute maximum value assumed by any of the
items in it.

"""
minval(itr) = mapreduce(minval, min, itr)
minval(arg1::Number, arg2::Number, args::Number...) =
    minval([arg1; arg2; args...])
minval(n::Number) =
    minval(_extractdutycycle(n)) * _extractnondutycycle(n)
minval(d::AbstractDutyCycle) = minimum(values(d))
minval(r::Real) = r

"""

Calculate the extrema (minimal and maximal values) ever assumed by one
or more dutycycles and returns them as a pair (minimum, maximum) of
non-DutyCycle numbers. Can be used with a non-empty iterator or a
collection and will then return the absolute maximum value assumed by
any of the items in it.

"""
extremavals(itr) = mapreduce(
    extremavals,
    (a, b) -> (min(a[1], b[1]), max(a[2], b[2])),
    itr
)
extremavals(arg1::Number, arg2::Number, args::Number...) =
    extremavals([arg1; arg2; args...])
extremavals(n::Number) =
    extremavals(_extractdutycycle(n)) * _extractnondutycycle(n)
extremavals(d::AbstractDutyCycle) = extrema(values(d))
extremavals(r::Real) = (r, r)
