# accessors.jl

module AccessorsTest

using Dates
using QDates
using Test

@testset "accessors" begin

function test_qdates(from,to)
    ds = QDates.days(QDates.QDate(from,1,1))
    y = m = d = 0; l = false
    for y in from:to
        for m = 1:12
            for l = false:true
                for d = 1:QDates.daysinmonth(y,m,l)
                    qdt = QDates.QDate(y,m,l,d)
                    @test ds == Dates.days(qdt) == QDates.days(qdt)
                    @test y == Dates.year(qdt)== QDates.year(qdt)
                    @test m == Dates.month(qdt)== QDates.month(qdt)
                    @test l == QDates.isleapmonth(qdt)
                    @test d == Dates.day(qdt)== QDates.day(qdt)
                    @test (y, m) == Dates.yearmonth(qdt)== QDates.yearmonth(qdt)
                    @test (m, d) == Dates.monthday(qdt)== QDates.monthday(qdt)
                    @test (y, m, d) == Dates.yearmonthday(qdt)== QDates.yearmonthday(qdt)
                    @test (y, m, l) == QDates.yearmonthleap(qdt)
                    @test (m, l, d) == QDates.monthleapday(qdt)
                    @test (y, m, l, d) == QDates.yearmonthleapday(qdt)
                    ds += 1
                end
            end
        end
    end
end
# test_qdates(445,2100)
test_qdates(1970,2020)

end

# broadcasting
@testset "Vectorized accessors" begin

a = QDates.QDate(2014,1,1)
dr = [a,a,a,a,a,a,a,a,a,a]
@test QDates.year.(dr) == repeat([2014],10)
@test QDates.month.(dr) == repeat([1],10)
@test QDates.isleapmonth.(dr) == repeat([false],10)
@test QDates.day.(dr) == repeat([1],10)

end

end