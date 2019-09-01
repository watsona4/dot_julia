using Filetimes
using Test
using Dates

filetime()

@test filetime(Dates.DateTime(1601, 1, 1)) == 0
@test filetime(Dates.DateTime(1601, 1, 2)) == convert(UInt64, 24 * 60 * 60 * 1000 * 1000 * 10)

@test Dates.year(Filetimes.datetime(131259265027478363)) == 2016

x = now()
@test Dates.year(Filetimes.datetime(Filetimes.filetime(x))) == Dates.year(x)
