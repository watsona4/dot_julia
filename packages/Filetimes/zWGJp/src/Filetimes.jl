module Filetimes

export filetime, datetime, EPOCH

using Dates

const EPOCH =  Dates.DateTime(1601, 1, 1)

"""
    filetime()

Returns the current time as the number of 100 nanosecond intervals
since January 1, 1601.

"""
function filetime()
    filetime(now())
end

"""
    filetime(d::Dates.DateTime)

Returns the number of 100 nanosecond intervals since January 1, 1601
for the given DateTime.

"""
function filetime(d::Dates.DateTime)
    Dates.value(d - EPOCH) * 10000
end

"""
    datetime(f::Integer)

Returns a DateTime object given a filetime f, being the number of 100
nanosecond intervals since January 1, 1601.

N.B. Possible loss of precision.

"""
function datetime(f::Integer)
    EPOCH + Dates.Microsecond(f/10)
end

"""
    filetime(s::AbstractString)

Returns the number of 100 nanosecond intervals since January 1, 1601,
for the given ISO8601 string.

    filetime("2014-09-02T08:20:07")

"""
function filetime(s::AbstractString)
    filetime(DateTime(s))
end
 
end # module
