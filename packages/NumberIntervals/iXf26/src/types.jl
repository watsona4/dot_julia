
import Base: promote_rule, convert, real, show
import IntervalArithmetic: Interval

export convert, real, show
export NumberInterval

function _is_valid_interval(lo, hi)
    if isinf(lo) && lo == hi
        return false # intervals cannot represent infinities
    elseif hi >= lo
        return true
    elseif hi == -Inf && lo == Inf
        return true # allow empty interval
    elseif isnan(hi) && isnan(lo)
        return true # allow NaN interval
    end
    return false
end

"""
    NumberInterval(lo, hi)

Interval which behaves like a number under standard arithmetic operations and
comparisons and raises an `IndeterminateException` when the results of these
operations cannot be rigorously determined.
"""
struct NumberInterval{T <: AbstractFloat} <: AbstractFloat
    lo::T
    hi::T
    NumberInterval(lo, hi) = _is_valid_interval(lo, hi) ?
        new{typeof(lo)}(lo, hi) : error("invalid interval ($lo , $hi)")
end

# for now only treat Reals; restriction from IntervalArithmetic
NumberInterval(a::T, b::T) where T <: Union{Integer, Rational, Irrational} =
    NumberInterval(float(a), float(b))

NumberInterval(a::Interval) = NumberInterval(a.lo, a.hi)
(::Type{NumberInterval{T}})(a::NumberInterval{T}) where T = a

Interval(a::NumberInterval) = Interval(a.lo, a.hi)

NumberInterval(a) = NumberInterval(Interval(a))
NumberInterval(a::NumberInterval) = a
NumberInterval{T}(a) where T = NumberInterval(Interval{T}(a))
NumberInterval{S}(a::T) where {S, T <: Union{Integer, Rational, Irrational}} =
    NumberInterval(Interval{S}(a))

real(a::NumberInterval{T}) where {T <: Real} = a

_promote_interval_type(::Type{Interval{T}}) where T = NumberInterval{T}
_promote_interval_type(a::Type) = a

# promote everything like Interval, except promote Interval to NumberInterval
promote_rule(::Type{NumberInterval{T}}, b::Type) where T =
    _promote_interval_type(promote_rule(Interval{T}, b))

function show(io::IO, i::NumberInterval)
    print(io, "x ∈ ")
    show(io, Interval(i))
end
