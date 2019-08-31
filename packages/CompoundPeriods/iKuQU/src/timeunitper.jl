const MONTHS_PER_YEAR = Int64(12)
const DAYS_PER_WEEK = Int64(7)
const HOURS_PER_DAY = Int64(24)
const HOURS_PER_WEEK = HOURS_PER_DAY * DAYS_PER_WEEK
const MINUTES_PER_HOUR = Int64(60)
const MINUTES_PER_DAY = MINUTES_PER_HOUR * HOURS_PER_DAY
const MINUTES_PER_WEEK = MINUTES_PER_DAY * DAYS_PER_WEEK
const SECONDS_PER_MINUTE = Int64(60)
const SECONDS_PER_HOUR = SECONDS_PER_MINUTE * MINUTES_PER_HOUR
const SECONDS_PER_DAY = SECONDS_PER_HOUR * HOURS_PER_DAY
const SECONDS_PER_WEEK = SECONDS_PER_DAY * DAYS_PER_WEEK
const MILLISECONDS_PER_SECOND = Int64(1_000)
const MICROSECONDS_PER_MILLISECOND = Int64(1_000)
const NANOSECONDS_PER_MICROSECOND  = Int64(1_000)
const MICROSECONDS_PER_SECOND = Int64(1_000_000)
const NANOSECONDS_PER_MILLISECOND  = Int64(1_000_000)
const NANOSECONDS_PER_SECOND  = Int64(1_000_000_000)
const MILLISECONDS_PER_DAY = MILLISECONDS_PER_SECOND * SECONDS_PER_DAY
const MICROSECONDS_PER_DAY = MICROSECONDS_PER_SECOND * SECONDS_PER_DAY
const NANOSECONDS_PER_DAY = NANOSECONDS_PER_SECOND * SECONDS_PER_DAY
const MILLISECONDS_PER_WEEK = MILLISECONDS_PER_DAY * DAYS_PER_WEEK
const MICROSECONDS_PER_WEEK = MICROSECONDS_PER_DAY * DAYS_PER_WEEK
const NANOSECONDS_PER_WEEK = NANOSECONDS_PER_DAY * DAYS_PER_WEEK


Day(x::Week) = Day(x.value * DAYS_PER_WEEK)
Hour(x::Week) = Hour(x.value * HOURS_PER_WEEK)
Minute(x::Week) = Minute(x.value * MINUTES_PER_WEEK)
Second(x::Week) = Second(x.value * SECONDS_PER_WEEK)
Millisecond(x::Week) = Millisecond(x.value * MILLISECONDS_PER_WEEK)
Microsecond(x::Week) = Microsecond(x.value * MICROSECONDS_PER_WEEK)
Nanosecond(x::Week) = Nanosecond(x.value * NANOSECONDS_PER_WEEK)

Hour(x::Day) = Hour(x.value * HOURS_PER_DAY)
Minute(x::Day) = Minute(x.value * MINUTES_PER_DAY)
Second(x::Day) = Second(x.value * SECONDS_PER_DAY)
Millisecond(x::Day) = Millisecond(x.value * MILLISECONDS_PER_DAY)
Microsecond(x::Day) = Microsecond(x.value * MICROSECONDS_PER_DAY)
Nanosecond(x::Day) = Nanosecond(x.value * NANOSECONDS_PER_DAY)

Minute(x::Hour) = Minute(x.value * MINUTES_PER_HOUR)
Second(x::Hour) = Second(x.value * SECONDS_PER_HOUR)
Millisecond(x::Hour) = Millisecond(x.value * (MILLISECONDS_PER_SECOND * SECONDS_PER_HOUR))
Microsecond(x::Hour) = Microsecond(x.value * (MICROSECONDS_PER_SECOND * SECONDS_PER_HOUR))
Nanosecond(x::Hour) = Nanosecond(x.value * (NANOSECONDS_PER_SECOND * SECONDS_PER_HOUR))

Second(x::Minute) = Second(x.value * SECONDS_PER_MINUTE)
Millisecond(x::Minute) = Millisecond(x.value * (MILLISECONDS_PER_SECOND * SECONDS_PER_MINUTE))
Microsecond(x::Minute) = Microsecond(x.value * (MICROSECONDS_PER_SECOND * SECONDS_PER_MINUTE))
Nanosecond(x::Minute) = Nanosecond(x.value * (NANOSECONDS_PER_SECOND * SECONDS_PER_MINUTE))

Millisecond(x::Second) = Millisecond(x.value * MILLISECONDS_PER_SECOND)
Microsecond(x::Second) = Microsecond(x.value * MICROSECONDS_PER_SECOND)
Nanosecond(x::Second) = Nanosecond(x.value * NANOSECONDS_PER_SECOND)

Microsecond(x::Millisecond) = Microsecond(x.value * MICROSECONDS_PER_MILLISECOND)
Nanosecond(x::Millisecond) = Nanosecond(x.value * NANOSECONDS_PER_MILLISECOND)

Nanosecond(x::Microsecond) = Nanosecond(x.value * NANOSECONDS_PER_MICROSECOND)

#=
for P in (:Hour, :Minute, :Second, :Millisecond, :Microsecond, :Nanosecond)
  @eval Day(x::$P) = Day(canonical(x))
end
for P in (:Minute, :Second, :Millisecond, :Microsecond, :Nanosecond)
  @eval Hour(x::$P) = Hour(canonical(x))
end
=#
  
  
