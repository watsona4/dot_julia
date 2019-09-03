# rounding.jl

module RoundingTests

using Test
using Dates
using QDates

# Basic rounding tests
@testset "Basic rounding" begin

qdt = QDates.QDate(2016, 2, 28)
@test floor(qdt, Dates.Year) == QDates.QDate(2016)
@test floor(qdt, Dates.Year(5)) == QDates.QDate(2015)
@test floor(qdt, Dates.Year(10)) == QDates.QDate(2010)
@test floor(qdt, Dates.Month) == QDates.QDate(2016, 2)
@test floor(qdt, Dates.Month(6)) == QDates.QDate(2015, 10)
@test floor(qdt, Dates.Day) == qdt
@test floor(qdt, Dates.Day(3)) == QDates.QDate(2016, 2, 26)
@test ceil(qdt, Dates.Year) == QDates.QDate(2017)
@test ceil(qdt, Dates.Year(5)) == QDates.QDate(2020)
@test ceil(qdt, Dates.Month) == QDates.QDate(2016, 3)
@test ceil(qdt, Dates.Month(6)) == QDates.QDate(2016, 4)
@test ceil(qdt, Dates.Day) == qdt
@test ceil(qdt, Dates.Day(3)) == QDates.QDate(2016, 2, 29)
@test round(qdt, Dates.Year) == QDates.QDate(2016)
@test round(qdt, Dates.Month) == QDates.QDate(2016, 3)

end

end