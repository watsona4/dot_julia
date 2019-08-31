plural(::Type{Nanosecond}) = Nanoseconds
plural(::Type{Microsecond}) = Microseconds
plural(::Type{Millisecond}) = Milliseconds
plural(::Type{Second}) = Seconds
plural(::Type{Minute}) = Minutes
plural(::Type{Hour}) = Hours
plural(::Type{Day}) = Days
plural(::Type{Week}) = Weeks
plural(::Type{Month}) = Months
plural(::Type{Year}) = Years


Nanoseconds(x::Period) = Nanosecond(x)
Nanoseconds(x::CompoundPeriod) = sum(map(Nanosecond, x.periods))
Nanoseconds(x::ReverseCompoundPeriod) = sum(map(Nanosecond, x.cperiod.periods))

nanoseconds(x::T) where {T<:Union{Period,Compounds}} = Nanoseconds(x).value

TimeUnits(x::CompoundPeriod) = sum(map(mintype(x), x.periods))
TimeUnits(x::ReverseCompoundPeriod) = sum(map(mintype(x), x.cperiod.periods))
TimeUnits(x::Period) = x

Microseconds(x::T) where {T<:Nanosecond} = floor(x, Microsecond)
Microseconds(x::T) where {T<:Period} = Microsecond(x)
Microseconds(x::T) where {T<:Compounds} = Microseconds(TimeUnits(x))

microseconds(x::T) where {T<:Union{Period,Compounds}} = Microseconds(x).value

Milliseconds(x::T) where {T<:Union{Nanosecond, Microsecond}} = floor(x, Millisecond)
Milliseconds(x::T) where {T<:Period} = Millisecond(x)
Milliseconds(x::T) where {T<:Compounds} = Milliseconds(TimeUnits(x))

milliseconds(x::T) where {T<:Union{Period,Compounds}} = Milliseconds(x).value

Seconds(x::T) where {T<:Union{Nanosecond, Microsecond, Millisecond}} = floor(x, Second)
Seconds(x::T) where {T<:Period} = Second(x)
Seconds(x::T) where {T<:Compounds} = Seconds(TimeUnits(x))

seconds(x::T) where {T<:Union{Period,Compounds}} = Seconds(x).value

Minutes(x::T) where {T<:Union{Nanosecond, Microsecond, Millisecond, Second}} = floor(x, Minute)
Minutes(x::T) where {T<:Period} = Minute(x)
Minutes(x::T) where {T<:Compounds} = Minutes(TimeUnits(x))

minutes(x::T) where {T<:Union{Period,Compounds}} = Minutes(x).value

Hours(x::T) where {T<:Union{Nanosecond, Microsecond, Millisecond, Second, Minute}} = floor(x, Hour)
Hours(x::T) where {T<:Period} = Hour(x)
Hours(x::T) where {T<:Compounds} = Hours(TimeUnits(x))

hours(x::T) where {T<:Union{Period,Compounds}} = Hours(x).value

Days(x::T) where {T<:Union{Nanosecond, Microsecond, Millisecond, Second, Minute, Hour}} = floor(x, Day)
Days(x::T) where {T<:Period} = Day(x)
Days(x::T) where {T<:Compounds} = Days(TimeUnits(x))

days(x::T) where {T<:Union{Period,Compounds}} = Days(x).value

Weeks(x::T) where {T<:Union{Nanosecond, Microsecond, Millisecond, Second, Minute, Hour, Day}} = floor(x, Week)
Weeks(x::T) where {T<:Period} = Week(x)
Weeks(x::T) where {T<:Compounds} = Weeks(TimeUnits(x))

weeks(x::T) where {T<:Union{Period,Compounds}} = Weeks(x).value

Months(x::T) where {T<:Union{Nanosecond, Microsecond, Millisecond, Second, Minute, Hour, Day}} = Month(0)
Months(x::T) where {T<:Year} = floor(x, Month)
Months(x::T) where {T<:Period} = Month(x)
Months(x::CompoundPeriod) = sum(map(Month, x.periods))
Months(x::ReverseCompoundPeriod) = sum(map(Month, x.cperiod.periods))

months(x::T) where {T<:Union{Period,Compounds}} = Months(x).value

Years(x::T) where {T<:Union{Nanosecond, Microsecond, Millisecond, Second, Minute, Hour, Day}} = Year(0)
Years(x::T) where {T<:Month} = floor(x, Year)
Years(x::T) where {T<:Period} = Year(x)
Years(x::CompoundPeriod) = sum(map(Year, x.periods))
Years(x::ReverseCompoundPeriod) = sum(map(Year, x.cperiod.periods))

years(x::T) where {T<:Union{Period,Compounds}} = Years(x).value



for (P, Q) in ((:Years,:years), (:Months,:months), (:Weeks,:weeks), (:Days,:days),
               (:Hours,:hours), (:Minutes,:minutes), (:Seconds,:seconds),
               (:Milliseconds,:milliseconds), (:Microseconds,:microseconds),
               (:Nanoseconds,:nanoseconds))
    @eval begin
        $P(x::DateTime) = $P(CompoundPeriod(x))
        $Q(x::DateTime) = $Q(CompoundPeriod(x))
    end
end

for (P, Q) in ((:Years,:years), (:Months,:months), (:Days, :days))
    @eval begin
        $P(x::Date) = $P(CompoundPeriod(x))
        $Q(x::Date) = $Q(CompoundPeriod(x))
    end
end

for (P, Q) in ((:Hours,:hours), (:Minutes,:minutes), (:Seconds,:seconds),
               (:Milliseconds,:milliseconds), (:Microseconds,:microseconds),
               (:Nanoseconds,:nanoseconds))
    @eval begin
        $P(x::Time) = $P(CompoundPeriod(x))
        $Q(x::Time) = $Q(CompoundPeriod(x))
    end
end
