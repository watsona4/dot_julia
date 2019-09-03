# query.jl

### Days of week
const 先勝,友引,先負,仏滅,大安,赤口 = 1,2,3,4,5,6
const qdaysofweek = Dict(1=>"先勝",2=>"友引",3=>"先負",4=>"仏滅",5=>"大安",6=>"赤口")

dayname(dt::Integer) = qdaysofweek[dt]
dayabbr(dt::Integer) = qdaysofweek[dt]
dayname(qdt::QDate) = qdaysofweek[dayofweek(qdt)]
dayabbr(qdt::QDate) = qdaysofweek[dayofweek(qdt)]

# Days of week from 先勝 = 1 to 赤口 = 6
function dayofweek(qdt::QDate)
    qdinfo = QREF.qref(qdt)
    mod1(qdinfo.m + qdinfo.md - 1, 6)
end

# define is先勝/is友引/is先負/is仏滅/is大安/is赤口
for (dow, nm) in qdaysofweek
    @eval ($(Symbol("is$nm")))(qdt::QDate) = dayofweek(qdt) == $dow
end

### Months
const 睦月,如月,弥生,卯月,皐月,水無月 = 1,2,3,4,5,6
const 文月,葉月,長月,神無月,霜月,師走 = 7,8,9,10,11,12
const qmonths = Dict(1=>"睦月",2=>"如月",3=>"弥生",4=>"卯月",5=>"皐月",6=>"水無月",
                     7=>"文月",8=>"葉月",9=>"長月",10=>"神無月",11=>"霜月",12=>"師走")
const leap_prefix = "閏"
monthname(dt::Integer, leap::Bool=false) = leap ? (leap_prefix * qmonths[dt]) : qmonths[dt]
@inline monthabbr(dt::Integer, leap::Bool=false) = monthname(dt, leap)
function monthname(qdt::QDate)
    qdinfo = QREF.qref(qdt)
    monthname(qdinfo.m, qdinfo.leap)
end
function monthabbr(qdt::QDate)
    qdinfo = QREF.qref(qdt)
    monthname(qdinfo.m, qdinfo.leap)
end

function daysinmonth(y::Integer, m::Integer, leap::Bool=false)
    qdinfo = QREF.rqref(y, m, leap)
    QREF.daysinmonth(qdinfo)
end
function daysinmonth(qdt::QDate)
    qdinfo = QREF.qref(qdt)
    QREF.daysinmonth(qdinfo)
end

function isleapyear(qdt::QDate)
    qdinfo = QREF.qref(qdt)
    return QREF.daysinyear(qdinfo) > 360
end

function daysinyear(qdt::QDate)
    qdinfo = QREF.qref(qdt)
    QREF.daysinyear(qdinfo)
end

function monthsinyear(qdt::QDate)
    daysinyear(qdt) ÷ 29
end

dayofyear(y::Integer, m::Integer, d::Integer) = dayofyear(y, m, false, d)
function dayofyear(y::Integer, m::Integer, l::Bool, d::Integer=1)
    QREF.dayofyear(QREF.rqref(y, m, l, d))
end
function dayofyear(qdt::QDate)
    QREF.dayofyear(QREF.qref(qdt))
end
