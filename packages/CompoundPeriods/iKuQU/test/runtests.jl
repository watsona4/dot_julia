using CompoundPeriods, Dates
using Test

cperiod = Day(5) + Hour(17) + Minute(35)
rperiod = reverse(cperiod)

@test rperiod.cperiod == cperiod

cperiod = canonical(Minute(-3600) + Second(22))
@test (cperiod - Day(cperiod)) > Hour(12)

@test TimeUnits(Minute(10)+Microsecond(100)) == Microsecond(600000100)

@test Month(Year(3)+Month(2)) == Month(2)
@test hour(Day(5)+Hour(3)+Second(1)) == 3

@test isempty(Hour(0) + Minute(0))
@test canonical(Hour(0)+Minute(0)) == Nanosecond(0)

@test Year(2)+Month(12)+Hour(7) > Year(1)+Month(24)+Minute(5)
@test Year(2)+Month(12)+Hour(7) == Year(1)+Month(24)+Hour(7)
