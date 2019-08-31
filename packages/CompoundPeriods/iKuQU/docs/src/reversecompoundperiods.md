```julia
julia> using CompoundPeriods, Dates

julia> cperiod = Day(5) + Hour(17) + Minute(35)
5 days, 17 hours, 35 minutes

julia> rperiod = reverse(cperiod)
35 minutes, 17 hours, 5 days

julia> [typeof(aperiod) for aperiod in cperiod]
3-element Array{DataType,1}:
 Day   
 Hour  
 Minute
 
julia> result = [];

julia> for aperiod in rperiod
            push!(result,(aperiod, aperiod.value))
       end

julia> result
3-element Array{Any,1}:
 (35 minutes, 35)
 (17 hours, 17)  
 (5 days, 5)     
```
