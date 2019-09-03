# conversions.jl

@inline date2jdn(dt::Union{Date,QDate}) = value(dt) + DAYS_OFFSET
@inline qdate2jdn(qdt::QDate) = date2jdn(qdt)

@inline jdn2date(j::Integer) = Dates.Date(Dates.UTD(j - DAYS_OFFSET))
@inline jdn2qdate(j::Integer) = QDates.QDate(Dates.UTD(j - DAYS_OFFSET))

Base.convert(::Type{Date}, qdt::QDate) = Date(qdt.instant)
Base.convert(::Type{QDate}, dt::Date) = QDate(dt.instant)
Base.convert(::Type{DateTime}, qdt::QDate) = DateTime(Dates.UTM(value(qdt)*86400000))
Base.convert(::Type{QDate}, dt::DateTime) = QDate(UTD(days(dt)))

Base.convert(::Type{R}, qdt::QDate) where {R<:Real} = convert(R, value(qdt))
Base.convert(::Type{QDate}, x::R) where {R<:Real} = QDate(UTD(x))

@inline Date(qdt::QDate) = convert(Date, qdt)
@inline QDate(dt::Date) = convert(QDate, dt)
@inline DateTime(qdt::QDate) = convert(DateTime, qdt)
@inline QDate(dt::DateTime) = convert(QDate, dt)

today() = QDate(Dates.now())
@inline today(::Type{QDate}) = today()
today(::Type{Date}) = Dates.today()
Dates.today(::Type{QDate}) = today()
@inline Dates.today(::Type{Date}) = Dates.today()
