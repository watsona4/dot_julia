# types.jl
using Dates:
    Date,
    DateTime,
    Period,
    Year,
    Month,
    Day,
    TimeType,
    UTInstant,
    value

struct QDate <: TimeType
    instant::UTInstant{Day}
    QDate(instant::UTInstant{Day}) = new(_check_instant(instant))
end
@inline function _check_instant(instant::UTInstant{Day})
    val = instant.periods.value
    if !(FIRST_VALUE <= val <= LAST_VALUE)
        throw(ArgumentError("Instant value: $val out of range ($FIRST_VALUE:$LAST_VALUE)"))
    end
    instant
end

@inline QDate(year::Integer, month::Integer=1, day::Integer=1) = QDate(year, month, false, day)
function QDate(year::Integer, month::Integer, leap::Bool, day::Integer)
    qdinfo = QREF.rqref_strict(year, month, leap, day)
    QDate(UTD(qdinfo.j - DAYS_OFFSET))
end
@inline _ci(x) = convert(Int, x)
@inline QDate(y,m=1,d=1) = QDate(_ci(y), _ci(m), _ci(d))
@inline QDate(y,m,l::Bool,d) = QDate(_ci(y), _ci(m), l, _ci(d))
@inline QDate(qdt::QDate) = qdt

@inline QDate(y::Year, m::Month=Month(1), d::Day=Day(1)) = QDate(value(y), value(m), false, value(d))
@inline QDate(y::Year, m::Month, l::Bool, d::Day=Day(1)) = QDate(value(y), value(m), l, value(d))

function QDate(periods::Union{Period,Bool}...)
    y = Year(0); m = Month(1); l = false; d = Day(1)
    _isyearspecified = false
    for p in periods
        isa(p, Year) && (_isyearspecified = true; y = p::Year)
        isa(p, Month) && (m = p::Month)
        isa(p, Bool) && (l = p::Bool)
        isa(p, Day) && (d = p::Day)
    end
    if !_isyearspecified
        throw(ArgumentError("Dates.Year must be specified"))
    end
    return QDate(y, m, l, d)
end

Base.eps(::QDate) = Day(1)

Base.typemax(::Union{QDate,Type{QDate}}) = QDate(UTD(LAST_VALUE))
Base.typemin(::Union{QDate,Type{QDate}}) = QDate(UTD(FIRST_VALUE))

Base.isless(x::QDate, y::QDate) = isless(value(x), value(y))

Base.promote_rule(::Type{QDate}, x::Type{Date}) = Date
Base.promote_rule(::Type{QDate}, x::Type{DateTime}) = DateTime

# for convenience
function QREF.qref(qdt::QDate)
    QREF.qref(value(qdt) + DAYS_OFFSET)
end