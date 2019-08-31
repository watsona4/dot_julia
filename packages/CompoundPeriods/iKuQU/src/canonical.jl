const CompoundPeriodZero = Nanosecond(0)
const CompoundPeriodEmpty = CompoundPeriod(CompoundPeriodZero)

canonical(x::Nanosecond) = Dates.canonicalize(Microsecond(0)+x)
canonical(x::Microsecond) = Dates.canonicalize(x+Nanosecond(0))
canonical(x::Millisecond) = Dates.canonicalize(x+Microsecond(0))
canonical(x::Second) = Dates.canonicalize(x+Millisecond(0))
canonical(x::Minute) = Dates.canonicalize(x+Second(0))
canonical(x::Hour) = Dates.canonicalize(x+Minute(0))
canonical(x::Day) = Dates.canonicalize(x+Hour(0))
canonical(x::Week) = Dates.canonicalize(x+Day(0))
canonical(x::Month) = Dates.canonicalize(Year(0)+x)
canonical(x::Year) = Dates.canonicalize(x+Month(0))

function canonical(x::CompoundPeriod)
    c = Dates.canonicalize(x)
    length(c) == 0 && return CompoundPeriodZero
    res = c.periods[1]
    !signbit(res) && return c
    c = c - res
    for p in c.periods
        x, y = fldmod(p)
        res = res + x + y
    end
    return res
end



fldmod2(x::Int64, y::Month) = (Year(x), y)
fldmod2(x::Int64, y::Day) = (Week(x), y)
fldmod2(x::Int64, y::Hour) = (Day(x), y)
fldmod2(x::Int64, y::Minute) = (Hour(x), y)
fldmod2(x::Int64, y::Second) = (Minute(x), y)
fldmod2(x::Int64, y::Millisecond) = (Second(x), y)
fldmod2(x::Int64, y::Microsecond) = (Millisecond(x), y)
fldmod2(x::Int64, y::Nanosecond) = (Microsecond(x), y)

fldmod(x::Year)::Year = x
fldmod(x::Month)::Tuple{Year,Month} = fldmod2(fldmod(x, Month(MONTHS_PER_YEAR))...,)
fldmod(x::Week)::Week = x
fldmod(x::Day)::Tuple{Week,Day} = fldmod2(fldmod(x, Day(DAYS_PER_WEEK))...,)
fldmod(x::Hour)::Tuple{Day,Hour} = fldmod2(fldmod(x, Hour(HOURS_PER_DAY))...,)
fldmod(x::Minute)::Tuple{Hour,Minute} = fldmod2(fldmod(x, Minute(MINUTES_PER_HOUR))...,)
fldmod(x::Second)::Tuple{Minute,Second} = fldmod2(fldmod(x, Second(SECONDS_PER_MINUTE))...,)
fldmod(x::Millisecond)::Tuple{Second,Millisecond} = fldmod2(fldmod(x, Millisecond(MILLISECONDS_PER_SECOND))...,)
fldmod(x::Microsecond)::Tuple{Millisecond,Microsecond} = fldmod2(fldmod(x, Microsecond(MICROSECONDS_PER_MILLISECOND))...,)
fldmod(x::Nanosecond)::Tuple{Microsecond,Nanosecond} = fldmod2(fldmod(x, Nanosecond(NANOSECONDS_PER_MICROSECOND))...,)
