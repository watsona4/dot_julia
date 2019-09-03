# ranges.jl

module RangesTest

using Test
using Dates
using QDates

@testset "ranges" begin

let T=QDates.QDate
    local f, l, dr, dr1
    f1 = T(1914); l1 = T(1913,12,30)
    f2 = T(2014); l2 = T(2014)
    f3 = T(1970); l3 = T(2020)
    # f4 = typemin(T); l4 = typemax(T)

    for P in (Dates.Day, Dates.Month, Dates.Year)
        for pos_step in (P(1),P(2),P(50))
            # empty range
            let dr = f1:pos_step:l1
                @test length(dr) == 0
                @test isempty(dr)
                @test first(dr) == f1
                @test last(dr) < f1
                @test length([i for i in dr]) == 0
                @test_throws ArgumentError minimum(dr)
                @test_throws ArgumentError maximum(dr)
                @test_throws BoundsError dr[1]
                @test findall(in(dr),dr) == Int64[]
                @test [dr;] == T[]
                @test isempty(reverse(dr))
                @test length(reverse(dr)) == 0
                @test first(reverse(dr)) < f1
                @test last(reverse(dr)) >= f1
                @test issorted(dr)
                @test sortperm(dr) == 1:1:0
                @test !(f1 in dr)
                @test !(l1 in dr)
                @test !(f1-pos_step in dr)
                @test !(l1+pos_step in dr)
            end

            # for (f,l) in ((f2,l2),(f3,l3),(f4,l4))
            for (f,l) in ((f2,l2),(f3,l3))
                let dr = f:pos_step:l, len = length(dr)
                    @test len > 0
                    @test typeof(len) <: Int64
                    @test !isempty(dr)
                    @test first(dr) == f
                    @test last(dr) <= l
                    @test minimum(dr) == first(dr)
                    @test maximum(dr) == last(dr)
                    @test dr[1] == f
                    @test dr[end] <= l
                    @static if VERSION < v"1.1.0-DEV.480"
                        @test iterate(dr) == (first(dr), 1)
                    else
                        @test iterate(dr) == (first(dr), (length(dr), 1))
                    end

                    if len < 10000
                        dr1 = [i for i in dr]
                        @test length(dr1) == len
                        @test findall(in(dr),dr) == [1:len;]
                        @test length([dr;]) == len
                    end
                    @test !isempty(reverse(dr))
                    @test length(reverse(dr)) == len
                    @test last(reverse(dr)) == f
                    @test issorted(dr)
                    @test f in dr
                end

            end
        end
        for neg_step in (P(-1),P(-2),P(-50))
            # empty range
            let dr = l1:neg_step:f1
                @test length(dr) == 0
                @test isempty(dr)
                @test first(dr) == l1
                @test last(dr) > l1
                @test length([i for i in dr]) == 0
                @test_throws ArgumentError minimum(dr)
                @test_throws ArgumentError maximum(dr)
                @test_throws BoundsError dr[1]
                @test findall(in(dr),dr) == Int64[]
                @test [dr;] == T[]
                @test isempty(reverse(dr))
                @test length(reverse(dr)) == 0
                @test first(reverse(dr)) > l1
                @test last(reverse(dr)) <= l1
                # @test !issorted(dr)
                # @test sortperm(dr) == 0:-1:1
                @test !(l1 in dr)
                @test !(l1 in dr)
                @test !(l1-neg_step in dr)
                @test !(l1+neg_step in dr)
            end

            # for (f,l) in ((f2,l2),(f3,l3),(f4,l4))
            for (f,l) in ((f2,l2),(f3,l3))
                let dr = l:neg_step:f, len = length(dr)
                    @test len > 0
                    @test typeof(len) <: Int64
                    @test !isempty(dr)
                    @test first(dr) == l
                    @test last(dr) >= f
                    @test minimum(dr) == last(dr)
                    @test maximum(dr) == first(dr)
                    @test dr[1] == l
                    @test dr[end] >= f
                    @static if VERSION < v"1.1.0-DEV.480"
                        @test iterate(dr) == (first(dr), 1)
                    else
                        @test iterate(dr) == (first(dr), (length(dr), 1))
                    end

                    if len < 10000
                        dr1 = [i for i in dr]
                        @test length(dr1) == len
                        @test findall(in(dr),dr) == [1:len;]
                        @test length([dr;]) == len
                    end
                    @test !isempty(reverse(dr))
                    @test length(reverse(dr)) == len
                    # @test !issorted(dr)
                    @test l in dr
                end
            end
        end
    end
end

# All the range representations we want to test
# Date ranges
dr  = QDates.QDate(2014,1,1):QDates.QDate(2014,2,1)
dr1 = QDates.QDate(2014,1,1):QDates.QDate(2014,1,1)
dr2 = QDates.QDate(2014,1,1):QDates.QDate(2013,2,1) # empty range
dr3 = QDates.QDate(2014,1,1):Dates.Day(-1):QDates.QDate(2013,1,1) # negative step
# Big ranges
dr4 = QDates.QDate(500):QDates.QDate(2000,1,1)
dr9 = typemin(QDates.QDate):typemax(QDates.QDate)
# Non-default steps
dr10 = typemax(QDates.QDate):Dates.Day(-1):typemin(QDates.QDate)
dr12 = typemin(QDates.QDate):Dates.Month(1):typemax(QDates.QDate)
dr13 = typemin(QDates.QDate):Dates.Year(1):typemax(QDates.QDate)
dr15 = typemin(QDates.QDate):Dates.Month(100):typemax(QDates.QDate)
dr16 = typemin(QDates.QDate):Dates.Year(1000):typemax(QDates.QDate)
dr20 = typemin(QDates.QDate):Dates.Day(2):typemax(QDates.QDate)

drs = Any[dr,dr1,dr2,dr3,dr4,dr9,dr10,
          dr12,dr13,dr15,dr16,dr20]

@test map(length,drs) == map(x->size(x)[1],drs)
@test all(x->findall(in(x),x) == [1:length(x);], drs[1:4])
@test isempty(dr2)
@test all(x->reverse(x) == last(x):-step(x):first(x),drs)
@test all(x->minimum(x) == (step(x) < zero(step(x)) ? last(x) : first(x)),drs[4:end])
@test all(x->maximum(x) == (step(x) < zero(step(x)) ? first(x) : last(x)),drs[4:end])
@test all(drs[1:3]) do dd
    for (i,d) in enumerate(dd)
        @test d == (first(dd) + Dates.Day(i-1))
    end
    true
end
# @test_throws MethodError dr + 1
a = QDates.QDate(2014,1,1)
b = QDates.QDate(2014,2,1)
@test map!(x->x+Dates.Day(1),Array{QDates.QDate}(undef, 30),dr) == [(a+Dates.Day(1)):(b+Dates.Day(1));]
@test map(x->x+Dates.Day(1),dr) == [(a+Dates.Day(1)):(b+Dates.Day(1));]

@test map(x->a in x,drs[1:4]) == [true,true,false,true]
@test a in dr
@test b in dr
@test QDates.QDate(2014,1,3) in dr
@test QDates.QDate(2014,1,15) in dr
@test QDates.QDate(2014,1,26) in dr
@test !(QDates.QDate(2013,1,1) in dr)

@test all(x->sort(x) == (step(x) < zero(step(x)) ? reverse(x) : x),drs)
@test all(x->step(x) < zero(step(x)) ? issorted(reverse(x)) : issorted(x),drs)

@test length(b:Dates.Day(-1):a) == 30
@test length(b:a) == 0
@test length(b:Dates.Day(1):a) == 0
@test length(a:Dates.Day(2):b) == 15
@test last(a:Dates.Day(2):b) == QDates.QDate(2014,1,29)
@test length(a:Dates.Day(7):b) == 5
@test last(a:Dates.Day(7):b) == QDates.QDate(2014,1,29)
@test length(a:Dates.Day(30):b) == 1
@test last(a:Dates.Day(30):b) == QDates.QDate(2014,1,1)
@test (a:b)[1] == QDates.QDate(2014,1,1)
@test (a:b)[2] == QDates.QDate(2014,1,2)
@test (a:b)[7] == QDates.QDate(2014,1,7)
@test (a:b)[end] == b
@test first(a:QDates.QDate(2099,1,1)) == a
@test first(a:typemax(QDates.QDate)) == a
@test first(typemin(QDates.QDate):typemax(QDates.QDate)) == typemin(QDates.QDate)

# Non-default step sizes
@test length(typemin(QDates.QDate):Dates.Month(1):typemax(QDates.QDate)) == QDates.QREF.LAST_RECORD  # == 21719
@test length(typemin(QDates.QDate):Dates.Year(1):typemax(QDates.QDate)) == QDates.QREF.LAST_YEAR - QDates.QREF.FIRST_YEAR + 1  # == 1756

c = QDates.QDate(2014,6,1)
@test length(a:Dates.Month(1):c) == 6
@test [a:Dates.Month(1):c;] == [a + Dates.Month(1)*i for i in 0:5]
@test [a:Dates.Month(2):QDates.QDate(2014,1,2);] == [a]
@test [c:Dates.Month(-1):a;] == reverse([a:Dates.Month(1):c;])
@test length(a:Dates.Month(1):QDates.QDate(2014,10,1)) == 11

d = QDates.QDate(2020,1,1)
@test length(a:Dates.Year(1):d) == 7
@test first(a:Dates.Year(1):d) == a
@test last(a:Dates.Year(1):d) == d
@test length(a:Dates.Month(12):d) == 7
@test first(a:Dates.Month(12):d) == a
@test last(a:Dates.Month(12):d) == QDates.QDate(2019,11,1)
@test length(a:Dates.Day(365):d) == 6
@test first(a:Dates.Day(365):d) == a
@test last(a:Dates.Day(365):d) == QDates.QDate(2018,12,25)

@test length(a:Dates.Year(1):QDates.QDate(2020,2,1)) == 7
@test length(a:Dates.Year(1):QDates.QDate(2020,6,1)) == 7
@test length(a:Dates.Year(1):QDates.QDate(2020,11,1)) == 7
@test length(a:Dates.Year(1):QDates.QDate(2020,12,30)) == 7
@test length(a:Dates.Year(1):QDates.QDate(2021,1,1)) == 8
@test length(QDates.QDate(2000):Dates.Year(-10):QDates.QDate(1900)) == 11
@test length(QDates.QDate(2000,6,23):Dates.Year(-10):QDates.QDate(1900,2,28)) == 11
@test length(QDates.QDate(2000,1,1):Dates.Year(1):QDates.QDate(2000,2,1)) == 1

# All leap months/years in 20th century
@test length(filter(QDates.isleapmonth, QDates.QDate(1901):Dates.Month(1):QDates.QDate(2000))) == 
      length(filter(QDates.isleapyear, QDates.QDate(1901):Dates.Year(1):QDates.QDate(2000))) == 36

end

end