```julia
julia> using Dates, CompoundPeriods

julia> cperiod = Day(2) - Hour(18) + Second(3605)
2 days, -18 hours, 3605 seconds

julia> Day(cperiod), Hour(cperiod), Second(cperiod)
(2 days, -18 hours, 3605 seconds)

julia> day(cperiod), hour(cperiod), second(cperiod)
(2, -18, 3605)

julia> cperiod = canonical(cperiod)
1 day, 7 hours, 5 seconds

julia> Day(cperiod), Hour(cperiod), Second(cperiod)
(1 day, 7 hours, 5 seconds)

julia> day(cperiod), hour(cperiod), second(cperiod)
(1, 7, 5)

julia> cperiod[1], cperiod[end]
1 day, 5 seconds
```
