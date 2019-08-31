# foreach nonempty Period in a CompoundPeriod, get type of Period
typesof(x::CompoundPeriod) = map(typeof, x.periods)
typesof(x::P) where {P<:Period} = (P,)

# the extremal Periods with nonzero value
max(x::CompoundPeriod) = isempty(x) ? x : x.periods[1]
min(x::CompoundPeriod) = isempty(x) ? x : x.periods[end]
minmax(x::CompoundPeriod) = min(x), max(x)

maxtype(x::CompoundPeriod) = typeof(max(x))
mintype(x::CompoundPeriod) = typeof(min(x))

max(x::ReverseCompoundPeriod) = isempty(x) ? x : x.cperiod.periods[1]
min(x::ReverseCompoundPeriod) = isempty(x) ? x : x.cperiod.periods[end]
minmax(x::ReverseCompoundPeriod) = min(x), max(x)

maxtype(x::ReverseCompoundPeriod) = typeof(max(x))
mintype(x::ReverseCompoundPeriod) = typeof(min(x))

max(x::Period) = x
min(x::Period) = x
minmax(x::Period) = x, x

maxtype(x::T) where {T<:Period} = T
mintype(x::T) where {T<:Period} = T

Base.zero(::Type{CompoundPeriod}) = Nanosecond(0)
Base.zero(::Type{ReverseCompoundPeriod}) = Nanosecond(0)

# CompoundPeriod(::Time) is exported from Dates
CompoundPeriod(dt::Date) = Year(dt)+Month(dt)+Day(dt)
CompoundPeriod(dtm::DateTime) = CompoundPeriod(Date(dtm)) + CompoundPeriod(Time(dtm))

Time(tm::CompoundPeriod) = Time(hour(tm),minute(tm),second(tm),millisecond(tm),microsecond(tm),nanosecond(tm))
function Date(dt::CompoundPeriod)
    yr = year(dt)       
    mo = max(1, month(dt))
    dy = max(1, day(dt))
    return Date(yr, mo, dy)
end
DateTime(dtm::CompoundPeriod)  = Date(dtm) + Time(hour(dtm), minute(dtm), second(dtm), millisecond(dtm))

signbit(period::Period) = signbit(period.value)
signbit(cperiod::CompoundPeriod) = signbit(max(canonical(cperiod)))
sign(cperiod::CompoundPeriod) = sign(max(canonical(cperiod)))
