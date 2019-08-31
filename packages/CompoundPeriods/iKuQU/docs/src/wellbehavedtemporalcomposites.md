```julia
julia>  time_translation = canonical(Minute(-3600) + Second(22))
-2 days, -11 hours, -59 minutes, -38 seconds

julia> temporal_algebra = fldmod(time_translation)
-3 days, 12 hours, 22 seconds

julia> cperiod = canonical(Day(2)-Hour(18)+Second(3605))
1 day, 7 hours, 5 seconds

julia> Second(cperiod), Minute(cperiod), Hour(cperiod), Day(cperiod)
(5 seconds, 0 minutes, 7 hours, 1 day)

julia> Seconds(cperiod), Minutes(cperiod), Hours(cperiod), Days(cperiod)
(111605 seconds, 1860 minutes, 31 hours, 1 day)

julia> TimeUnits(Day(2)+Hour(12))
60 hours

julia> TimeUnits(Minute(10)+Microsecond(100))
600000100 microseconds
```
