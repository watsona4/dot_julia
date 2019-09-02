const days_per_year = 365.2422
const global_base_date = Date(2000,1,1)
const global_base_date_as_day = convert(Dates.Day, global_base_date)

"""
    years_between(until::Date, from::Date)
    years_between(until::Dates.Day, from::Dates.Day)

Returns the number of years between two dates. For the purposes of this calculation
there are 365.2422 days in a year.
"""
function years_between(until::Date, from::Date)
    return (Dates.days(until) -Dates.days(from))/ days_per_year
end
function years_between(until::Dates.Day, from::Dates.Day)
    return (convert(Int, until)-convert(Int, from))/ days_per_year
end

"""
    years_between(a::Date, b::Date)
    years_between(a::Dates.Day, b::Dates.Day)

Returns the number of years that have elapsed since 1-Jan-2000. For the purposes of this calculation
there are 365.2422 days in a year.
"""
function years_from_global_base(a::Date)
    return years_between(a, global_base_date)
end

function years_from_global_base(a::Dates.Day)
    return years_between(a, global_base_date_as_day)
end

"""
    Period length is designed to convert TimePeriod objects to a float in a consistent way to years_from_global_base
"""
function period_length(a::Dates.DatePeriod, base::Date = global_base_date)
    return years_between(base+a, base)
end
