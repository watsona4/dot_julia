```julia
julia> using CompoundPeriods, Dates

julia> cperiod = Day(5) + Hour(17) + Minute(35)
5 days, 17 hours, 35 minutes

julia> rperiod = reverse(cperiod)
35 minutes, 17 hours, 5 days

julia> cperiod == reverse(rperiod)
true

julia> min(cperiod), max(rperiod)
(35 minutes, 5 days)

julia> minmax(cperiod) == minmax(rperiod)
true
```
