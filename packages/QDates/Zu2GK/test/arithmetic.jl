# arithmetic.jl

module ArithmeticTest

using Test
using Dates
using QDates

@testset "basic arithmetic" begin

qdt = QDates.QDate(1999,12,27)
@test qdt + Dates.Year(1) == QDates.QDate(2000,12,27)
@test qdt + Dates.Year(100) == QDates.QDate(2099,12,27)
@test_throws ArgumentError qdt + Dates.Year(1000)
@test qdt - Dates.Year(1) == QDates.QDate(1998,12,27)
@test qdt - Dates.Year(100) == QDates.QDate(1899,12,27)
@test qdt - Dates.Year(1000) == QDates.QDate(999,12,27)
qdt = QDates.QDate(2017,2,30)
@test qdt + Dates.Year(1) == QDates.QDate(2018,2,30)
@test qdt - Dates.Year(1) == QDates.QDate(2016,2,29)
qdt = QDates.QDate(2017,5,true,1)
@test_broken qdt + Dates.Year(1) == QDates.QDate(2018,6,1)
@test qdt + Dates.Year(1) == QDates.QDate(2018,5,1)
@test qdt + Dates.Year(11) == QDates.QDate(2028,5,true,1)
@test_broken qdt - Dates.Year(1) == QDates.QDate(2016,6,1)
@test qdt - Dates.Year(1) == QDates.QDate(2016,5,1)
@test qdt - Dates.Year(8) == QDates.QDate(2009,5,true,1)

qdt = QDates.QDate(1999,12,27)
@test qdt + Dates.Month(1) == QDates.QDate(2000,1,27)
@test qdt + Dates.Month(100) == QDates.QDate(2008,1,27)
@test qdt + Dates.Month(1000) == QDates.QDate(2080,10,27)
@test qdt - Dates.Month(1) == QDates.QDate(1999,11,27)
@test qdt - Dates.Month(100) == QDates.QDate(1991,11,27)
@test qdt - Dates.Month(1000) == QDates.QDate(1919,2,27)
qdt = QDates.QDate(2017,2,30)
@test qdt + Dates.Month(1) == QDates.QDate(2017,3,29)
@test qdt + Dates.Month(4) == QDates.QDate(2017,5,true,29)
@test qdt - Dates.Month(1) == QDates.QDate(2017,1,29)
@test qdt - Dates.Month(3) == QDates.QDate(2016,11,30)
qdt = QDates.QDate(2017,5,true,1)
@test qdt + Dates.Month(1) == QDates.QDate(2017,6,1)
@test qdt - Dates.Month(1) == QDates.QDate(2017,5,1)

# @test_throws MethodError qdt + Dates.Week(1)

qdt = QDates.QDate(1999,12,27)
@test qdt + Dates.Day(1) == QDates.QDate(1999,12,28)
@test qdt + Dates.Day(100) == QDates.QDate(2000,4,9)
@test qdt + Dates.Day(1000) == QDates.QDate(2002,9,24)
@test qdt - Dates.Day(1) == QDates.QDate(1999,12,26)
@test qdt - Dates.Day(100) == QDates.QDate(1999,9,17)
@test qdt - Dates.Day(1000) == QDates.QDate(1997,4,2)

end

# Vectorized arithmetic
@testset "Vectorized arithmetic" begin

a = QDates.QDate(2014,1,1)
dr = [a,a,a,a,a,a,a,a,a,a]
b = a + Dates.Year(1)
@test dr .+ Dates.Year(1) == repeat([b],10)
b = a + Dates.Month(1)
@test dr .+ Dates.Month(1) == repeat([b],10)
b = a + Dates.Day(1)
@test dr .+ Dates.Day(1) == repeat([b],10)
b = a - Dates.Year(1)
@test dr .- Dates.Year(1) == repeat([b],10)
b = a - Dates.Month(1)
@test dr .- Dates.Month(1) == repeat([b],10)
b = a - Dates.Day(1)
@test dr .- Dates.Day(1) == repeat([b],10)

# Month arithmetic minimizes "edit distance", or number of changes
# needed to get a correct answer
# This approach results in a few cases of non-associativity
a = QDates.QDate(2012,1,29)
@test (a+Dates.Day(1))+Dates.Month(1) != (a+Dates.Month(1))+Dates.Day(1)
a = QDates.QDate(2012,2,29)
@test (a+Dates.Day(1))+Dates.Month(1) != (a+Dates.Month(1))+Dates.Day(1)
a = QDates.QDate(2012,4,29)
@test (a+Dates.Day(1))+Dates.Month(1) != (a+Dates.Month(1))+Dates.Day(1)
a = QDates.QDate(2012,5,29)
@test (a+Dates.Day(1))+Dates.Month(1) != (a+Dates.Month(1))+Dates.Day(1)
a = QDates.QDate(2012,6,29)
@test (a+Dates.Day(1))+Dates.Month(1) != (a+Dates.Month(1))+Dates.Day(1)
a = QDates.QDate(2012,8,29)
@test (a+Dates.Day(1))+Dates.Month(1) != (a+Dates.Month(1))+Dates.Day(1)
a = QDates.QDate(2012,9,29)
@test (a+Dates.Day(1))+Dates.Month(1) != (a+Dates.Month(1))+Dates.Day(1)
a = QDates.QDate(2012,10,29)
@test (a+Dates.Day(1))+Dates.Month(1) != (a+Dates.Month(1))+Dates.Day(1)
a = QDates.QDate(2012,11,29)
@test (a+Dates.Day(1))+Dates.Month(1) != (a+Dates.Month(1))+Dates.Day(1)
a = QDates.QDate(2012,12,29)
@test (a+Dates.Day(1))+Dates.Month(1) != (a+Dates.Month(1))+Dates.Day(1)

t1 = [QDates.QDate(2009,1,1) QDates.QDate(2009,1,2) QDates.QDate(2009,1,3); QDates.QDate(2009,2,1) QDates.QDate(2009,2,2) QDates.QDate(2009,2,3)]
t2 = [QDates.QDate(2009,1,2) QDates.QDate(2009,2,2) QDates.QDate(2010,1,3); QDates.QDate(2010,2,1) QDates.QDate(2009,3,2) QDates.QDate(2009,2,4)]

# TimeType, Array{TimeType}
@test QDates.QDate(2010,1,1) .- t1 == [Dates.Day(384) Dates.Day(383) Dates.Day(382); Dates.Day(354) Dates.Day(353) Dates.Day(352)]
@test t1 .- QDates.QDate(2010,1,1) == [Dates.Day(-384) Dates.Day(-383) Dates.Day(-382); Dates.Day(-354) Dates.Day(-353) Dates.Day(-352)]

# GeneralPeriod, Array{TimeType}
@test Dates.Day(1) .+ t1 == [QDates.QDate(2009,1,2) QDates.QDate(2009,1,3) QDates.QDate(2009,1,4); QDates.QDate(2009,2,2) QDates.QDate(2009,2,3) QDates.QDate(2009,2,4)]
@test t1 .+ Dates.Day(1) == [QDates.QDate(2009,1,2) QDates.QDate(2009,1,3) QDates.QDate(2009,1,4); QDates.QDate(2009,2,2) QDates.QDate(2009,2,3) QDates.QDate(2009,2,4)]
# @test Dates.Day(1) + t1 == [QDates.QDate(2009,1,2) QDates.QDate(2009,1,3) QDates.QDate(2009,1,4); QDates.QDate(2009,2,2) QDates.QDate(2009,2,3) QDates.QDate(2009,2,4)]
# @test t1 + Dates.Day(1) == [QDates.QDate(2009,1,2) QDates.QDate(2009,1,3) QDates.QDate(2009,1,4); QDates.QDate(2009,2,2) QDates.QDate(2009,2,3) QDates.QDate(2009,2,4)]

@test (Dates.Month(1) + Dates.Day(1)) .+ t1 == [QDates.QDate(2009,2,2) QDates.QDate(2009,2,3) QDates.QDate(2009,2,4); QDates.QDate(2009,3,2) QDates.QDate(2009,3,3) QDates.QDate(2009,3,4)]
@test t1 .+ (Dates.Month(1) + Dates.Day(1)) == [QDates.QDate(2009,2,2) QDates.QDate(2009,2,3) QDates.QDate(2009,2,4); QDates.QDate(2009,3,2) QDates.QDate(2009,3,3) QDates.QDate(2009,3,4)]
# @test (Dates.Month(1) + Dates.Day(1)) + t1 == [QDates.QDate(2009,2,2) QDates.QDate(2009,2,3) QDates.QDate(2009,2,4); QDates.QDate(2009,3,2) QDates.QDate(2009,3,3) QDates.QDate(2009,3,4)]
# @test t1 + (Dates.Month(1) + Dates.Day(1)) == [QDates.QDate(2009,2,2) QDates.QDate(2009,2,3) QDates.QDate(2009,2,4); QDates.QDate(2009,3,2) QDates.QDate(2009,3,3) QDates.QDate(2009,3,4)]

@test t1 .- Dates.Day(1) == [QDates.QDate(2008,12,30) QDates.QDate(2009,1,1) QDates.QDate(2009,1,2); QDates.QDate(2009,1,30) QDates.QDate(2009,2,1) QDates.QDate(2009,2,2)]
# @test t1 - Dates.Day(1) == [QDates.QDate(2008,12,30) QDates.QDate(2009,1,1) QDates.QDate(2009,1,2); QDates.QDate(2009,1,30) QDates.QDate(2009,2,1) QDates.QDate(2009,2,2)]

@test t1 .- (Dates.Month(1) + Dates.Day(1)) == [QDates.QDate(2008,11,29) QDates.QDate(2008,12,1) QDates.QDate(2008,12,2); QDates.QDate(2008,12,30) QDates.QDate(2009,1,1) QDates.QDate(2009,1,2)]
# @test t1 - (Dates.Month(1) + Dates.Day(1)) == [QDates.QDate(2008,11,29) QDates.QDate(2008,12,1) QDates.QDate(2008,12,2); QDates.QDate(2008,12,30) QDates.QDate(2009,1,1) QDates.QDate(2009,1,2)]

# Array{TimeType}, Array{TimeType}
@test t2 .- t1 == [Dates.Day(1) Dates.Day(30) Dates.Day(384); Dates.Day(384) Dates.Day(30) Dates.Day(1)]
@test t2 - t1 == [Dates.Day(1) Dates.Day(30) Dates.Day(384); Dates.Day(384) Dates.Day(30) Dates.Day(1)]

end

end