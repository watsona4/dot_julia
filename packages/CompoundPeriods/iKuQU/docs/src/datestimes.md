```julia
julia> using Dates, CompoundPeriods

julia> dtm = DateTime("2011-02-04T10:11:12.345")
2011-02-04T10:11:12.345

julia> dt, tm = Date(dtm), Time(dtm)
(2011-02-04, 10:11:12.345)

julia> dt, CompoundPeriod(dt), dt == Date(CompoundPeriod(dt))
(2011-02-04, 2011 years, 2 months, 4 days, true)

julia> tm, CompoundPeriod(tm), tm == Time(CompoundPeriod(tm))
(10:11:12.345, 10 hours, 11 minutes, 12 seconds, 345 milliseconds, true)

julia> CompoundPeriod(dtm)
(2011 years, 2 months, 4 days, 10 hours, 11 minutes, 12 seconds, 345 milliseconds)

julia> dtm == DateTime(CompoundPeriod(dtm))
true
```
