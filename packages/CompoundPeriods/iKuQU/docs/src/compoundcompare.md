```julia
julia> using CompoundPeriods, Dates

julia> cperiod1 = Month(4)+Hour(1)+Microsecond(567)
4 months, 1 hour, 567 microseconds

julia> cperiod2 = Month(4)+Hour(1)+Second(1)+Microsecond(5)
4 months, 1 hour, 1 second, 5 microseconds

julia> period1 = Hour(15)
15 hours

julia> cperiod1 < cperiod2
true

julia> cperiod1 > period1
true

julia> Minute(15)+Second(150) < period1
true
```
