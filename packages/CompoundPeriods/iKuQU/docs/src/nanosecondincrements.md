```julia
julia> using Dates, CompoundPeriods

julia> dyhr = Day(5) + Hour(79)
5 days, 79 hours

julia> dyhr = canonical(dyhr)
1 week, 1 day, 7 hours

julia> mnsc = canonical(Minute(-3600) + Second(22))
-2 days, -11 hours, -59 minutes, -38 seconds

julia> adatetime = DateTime("2004-03-02")
2004-03-02T00:00:00

julia> Time(adatetime) + Nanosecond(4321)
00:00:00.000004321

julia> adatetime + mnsc
2004-02-28T12:00:22
```
