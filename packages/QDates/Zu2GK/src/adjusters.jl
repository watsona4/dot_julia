# adjusters.jl
using Dates: UTD, value

### truncation
Base.trunc(qdt::QDate, ::Type{Year}) = firstdayofyear(qdt)
Base.trunc(qdt::QDate, ::Type{Month}) = firstdayofmonth(qdt)
Base.trunc(qdt::QDate, ::Type{Day}) = qdt

firstdayofyear(qdt::QDate) = QDate(UTD(value(qdt) - dayofyear(qdt) + 1))
function lastdayofyear(qdt::QDate)
    # cqdate = _qref(qdt)
    # return QDate(UTD(value(qdt) + daysinyear(qdt) - cqdate[3]))
    qdinfo = QREF.qref(qdt)
    jdn2qdate(QREF.lastjdninyear(qdinfo))
end
@inline Dates.firstdayofyear(qdt::QDate) = firstdayofyear(qdt)
@inline Dates.lastdayofyear(qdt::QDate) = lastdayofyear(qdt)

firstdayofmonth(qdt::QDate) = QDate(UTD(value(qdt) - day(qdt) + 1))
@inline Dates.firstdayofmonth(qdt::QDate) = firstdayofmonth(qdt)

function lastdayofmonth(qdt::QDate)
    y, m, l, d = yearmonthleapday(qdt)
    return QDate(UTD(value(qdt) + daysinmonth(y, m, l) - d))
end
@inline Dates.lastdayofmonth(qdt::QDate) = lastdayofmonth(qdt)

# Return the next TimeType that falls on dow
ISQDAYOFWEEK = Dict(先勝 => Dates.DateFunction(is先勝, Base.typemin(QDate)),
                    友引 => Dates.DateFunction(is友引, Base.typemin(QDate)),
                    先負 => Dates.DateFunction(is先負, Base.typemin(QDate)),
                    仏滅 => Dates.DateFunction(is仏滅, Base.typemin(QDate)),
                    大安 => Dates.DateFunction(is大安, Base.typemin(QDate)),
                    赤口 => Dates.DateFunction(is赤口, Base.typemin(QDate)))

Dates.tonext(qdt::QDate, dow::Int; same::Bool=false) = Dates.adjust(ISQDAYOFWEEK[dow], same ? qdt : qdt + Day(1), Day(1), 12)

Dates.toprev(qdt::QDate, dow::Int; same::Bool=false) = Dates.adjust(ISQDAYOFWEEK[dow], same ? qdt : qdt + Day(-1), Day(-1), 12)

function Dates.tofirst(qdt::QDate, dow::Int; of::Union{Type{Year},Type{Month}}=Month)
    qdt = of <: Month ? firstdayofmonth(qdt) : firstdayofyear(qdt)
    return Dates.adjust(ISQDAYOFWEEK[dow], qdt, Day(1), 385)
end

function Dates.tolast(qdt::QDate, dow::Int; of::Union{Type{Year},Type{Month}}=Month)
    qdt = of <: Month ? lastdayofmonth(qdt) : lastdayofyear(qdt)
    return Dates.adjust(ISQDAYOFWEEK[dow], qdt, Day(-1), 385)
end
