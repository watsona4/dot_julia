# rounding.jl

function Base.floor(qdt::QDate, p::Dates.Year)
    value(p) < 1 && throw(DomainError())
    years = year(qdt)
    return QDate(years - mod(years, value(p)))
end

function Base.floor(qdt::QDate, p::Dates.Month)
    value(p) < 1 && throw(DomainError())
    y, m, l = yearmonthleap(qdt)
    qdt0 = QDate(y, m, l, 1)
    if value(p) == 1
        return qdt0
    end
    months = round(Int, (value(qdt0) - FIRST_VALUE) / _DAYS_IN_MONTH_F)
    return qdt0 - Dates.Month(mod(months, value(p)))
end

function Base.floor(qdt::QDate, p::Day)
    value(p) < 1 && throw(DomainError())
    days = value(qdt) - FIRST_VALUE
    return QDate(UTD(days - mod(days, value(p)) + FIRST_VALUE))
end
