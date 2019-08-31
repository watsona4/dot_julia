# CompoundPeriods

This package enhances the `CompoundPeriod` type defined within `Dates` (`Dates.CompoundPeriod`).  A `CompoundPeriod` is formed by attaching (_adding_) two or more distinct `Periods`:
```julia
julia> using Dates

julia> typeof( Year(1999) ), typeof( Hour(15) )
Year, Hour

julia> typeof( Year(1999) + Hour(15) )
Dates.CompoundPeriod

julia> typeof( Year(1999) + Month(12) + Day(5) + Hour(15) + Nanosecond(25) )
Dates.CompoundPeriod

julia> dump(ans)
Dates.CompoundPeriod <: Dates.AbstractTime
  periods::Array{Period,1}

````

## get the package

```julia
julia> ]
pkg> add CompoundPeriods
pkg> <backspace>
```

## use the package

Note that `typeof( <Period>(n) + <Period>(n) )` is shown as `CompoundPeriod` rather than `Dates.CompoundPeriod`.
This lets you know that enhanced CompoundPeriods are in use.

```julia
julia> using CompoundPeriods, Dates

julia> typeof( Year(1999) ), typeof( Hour(15) )
Year, Hour

julia> typeof( Year(1999) + Hour(15) )
CompoundPeriod

julia> typeof( Year(1999) + Month(12) + Day(5) + Hour(15) + Nanosecond(25) )
CompoundPeriod
```
