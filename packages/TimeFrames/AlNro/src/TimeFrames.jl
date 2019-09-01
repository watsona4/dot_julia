module TimeFrames

import Base: range, +, -, *

using Dates

export TimeFrame, Boundary
export YearBegin, YearEnd
export MonthBegin, MonthEnd
# export Millisecond, Second, Minute, Hour, Day, Week
export NoTimeFrame
export apply, range
export Begin, End
export @tf_str

abstract type TimeFrame end

@enum(Boundary,
    UndefBoundary = 0,  # Undefined boundary
    Begin = 1,  # begin of interval
    End   = 2,  # end of interval
)

#T should be Dates.TimePeriod

abstract type AbstractPeriodFrame <: TimeFrame end
abstract type AbstractTimePeriodFrame <: AbstractPeriodFrame end
abstract type AbstractDatePeriodFrame <: AbstractPeriodFrame end

struct TimePeriodFrame{T <: Dates.TimePeriod} <: AbstractTimePeriodFrame
    period::T
    boundary::Boundary
end
TimePeriodFrame{T}(; boundary=Begin::Boundary) where T<:Dates.TimePeriod = TimePeriodFrame(T(1), boundary)
TimePeriodFrame{T}(n::Integer; boundary=Begin::Boundary) where T<:Dates.TimePeriod = TimePeriodFrame(T(n), boundary)

struct DatePeriodFrame{T <: Dates.DatePeriod} <: AbstractDatePeriodFrame
    period::T
    boundary::Boundary
end
DatePeriodFrame{T}(; boundary=Begin::Boundary) where T<:Dates.DatePeriod = DatePeriodFrame(T(1), boundary)
DatePeriodFrame{T}(n::Integer; boundary=Begin::Boundary) where T<:Dates.DatePeriod = DatePeriodFrame(T(n), boundary)

struct NoTimeFrame <: TimeFrame
    NoTimeFrame(args...; kwargs...) = new()
end
TimeFrame() = NoTimeFrame()

# Base.hash(tf::TimePeriodFrame, h::UInt) = hash(tf.period, hash(tf.boundary))
# Base.:(==)(tf1::TimePeriodFrame, tf2::TimePeriodFrame) = hash(tf1) == hash(tf2)

function _period_step(::Type{Date})
    Dates.Day(1)
end

const period_step = Dates.Millisecond(1)

function _period_step(::Type{DateTime})
    period_step
end

#struct Microsecond <: AbstractTimePeriodFrame
#    period::Dates.TimePeriod
#    boundary::Boundary
#end
#Microsecond() = Microsecond(Dates.Microsecond(1), Begin)
#Microsecond(n::Integer) = Microsecond(Dates.Microsecond(n), Begin)

struct Millisecond <: AbstractTimePeriodFrame
    period::Dates.Millisecond
    boundary::Boundary
end
Millisecond() = Millisecond(Dates.Millisecond(1), Begin)
Millisecond(n::Integer) = Millisecond(Dates.Millisecond(n), Begin)

struct Second <: AbstractTimePeriodFrame
    period::Dates.Second
    boundary::Boundary
end
Second() = Second(Dates.Second(1), Begin)
Second(n::Integer) = Second(Dates.Second(n), Begin)

struct Minute <: AbstractTimePeriodFrame
    period::Dates.Minute
    boundary::Boundary
end
Minute() = Minute(Dates.Minute(1), Begin)
Minute(n::Integer) = Minute(Dates.Minute(n), Begin)

struct Hour <: AbstractTimePeriodFrame
    period::Dates.Hour
    boundary::Boundary
end
Hour() = Hour(Dates.Hour(1), Begin)
Hour(n::Integer) = Hour(Dates.Hour(n), Begin)

struct Day <: AbstractDatePeriodFrame
    period::Dates.Day
    boundary::Boundary
end
Day() = Day(Dates.Day(1), Begin)
Day(n::Integer) = Day(Dates.Day(n), Begin)

struct Week <: AbstractDatePeriodFrame
    period::Dates.Week
    boundary::Boundary
end
Week() = Week(Dates.Week(1), Begin)
Week(n::Integer) = Week(Dates.Week(n), Begin)

struct MonthEnd <: AbstractDatePeriodFrame
    period::Dates.Month
    boundary::Boundary
end
MonthEnd() = MonthEnd(Dates.Month(1), End)
MonthEnd(n::Integer) = MonthEnd(Dates.Month(n), End)

struct MonthBegin <: AbstractDatePeriodFrame
    period::Dates.Month
    boundary::Boundary
end
MonthBegin() = MonthBegin(Dates.Month(1), Begin)
MonthBegin(n::Integer) = MonthBegin(Dates.Month(n), Begin)

struct YearEnd <: AbstractDatePeriodFrame
    period::Dates.Year
    boundary::Boundary
end
YearEnd() = YearEnd(Dates.Year(1), End)
YearEnd(n::Integer) = YearEnd(Dates.Year(n), End)

struct YearBegin <: AbstractDatePeriodFrame
    period::Dates.Year
    boundary::Boundary
end
YearBegin() = YearBegin(Dates.Year(1), Begin)
YearBegin(n::Integer) = YearBegin(Dates.Year(n), Begin)

const _D_STR2TIMEFRAME = Dict(
    "A"=>YearEnd,
    "AS"=>YearBegin,
    "M"=>MonthEnd,
    "MS"=>MonthBegin,
    "W"=>Week,
    "D"=>Day,
    "H"=>Hour,
    "T"=>Minute,
    "S"=>Second,
    "L"=>Millisecond,
    #"U"=>Microsecond,
    ""=>NoTimeFrame
)
# Reverse key/value
const _D_TIMEFRAME2STR = Dict{DataType,String}()
for (key, typ) in _D_STR2TIMEFRAME
    _D_TIMEFRAME2STR[typ] = key
end
# Additional shortcuts
const _D_STR2TIMEFRAME_ADDITIONAL = Dict(
    "MIN"=>Minute,
)
for (key, value) in _D_STR2TIMEFRAME_ADDITIONAL
    _D_STR2TIMEFRAME[key] = value
end

# To string
function String(tf::TimeFrame)
    s_tf = _D_TIMEFRAME2STR[typeof(tf)]
    if tf.period.value == 1
        s_tf
    else
        "$(tf.period.value)$(s_tf)"
    end
end

# Parse
function TimeFrame(s::String; boundary=UndefBoundary)
    freq_pattern = join(keys(_D_STR2TIMEFRAME), "|")
    #pattern = r"^([\d]*)([Y|M|W|D|H|T])$"
    pattern = Regex("^([\\d]*)([$freq_pattern]*)\$", "i")
    m = match(pattern, s)
    if m == nothing
        error("Can't parse '$s' to TimeFrame")
    else
        s_freq = uppercase(m[2])
        tf_typ = _D_STR2TIMEFRAME[s_freq]
        if m[1] != ""
            value = parse(Int, m[1])
        else
            value = 1
        end
        tf = tf_typ(value)
        if boundary != UndefBoundary
            tf.boundary = boundary
        end
        tf
    end
end

# grouper
function dt_grouper(tf::AbstractPeriodFrame)
    dt -> _d_f_boundary[tf.boundary](dt, tf.period)
end

function dt_grouper(tf::AbstractPeriodFrame, t::Type)
    if tf.boundary == Begin
        dt -> _d_f_boundary[tf.boundary](dt, tf.period)
    elseif tf.boundary == End
        dt -> _d_f_boundary[tf.boundary](dt, tf.period) - _period_step(t)
    else
        error("Unsupported boundary $(tf.boundary)")
    end
end

struct CustomTimeFrame <: TimeFrame
    f_group::Function
end

function TimeFrame(f_group::Function)
    CustomTimeFrame(f_group)
end

function TimeFrame(td::Dates.TimePeriod; boundary=Begin::Boundary)
    T = typeof(td)
    TimePeriodFrame{T}(td.value, boundary=boundary)
end

function TimeFrame(td::Dates.DatePeriod; boundary=Begin::Boundary)
    T = typeof(td)
    DatePeriodFrame{T}(td.value, boundary=boundary)
end

function dt_grouper(tf::CustomTimeFrame, ::Type)
    tf.f_group
end

const _d_f_boundary = Dict(
    Begin::Boundary => floor,
    End::Boundary => ceil
)

function apply(tf::TimeFrame, dt)
    dt_grouper(tf, typeof(dt))(dt)
end

function tonext(tf::TimeFrame, dt::Dates.TimeType; same=false)
    dt2 = apply(tf, dt)
    if dt2 < dt
        dt2 + tf
    else
        if !same && dt2 == dt
            dt2 + tf
        else
            dt2
        end
    end
end

# range
function range(dt1::Dates.TimeType, tf::AbstractPeriodFrame, dt2::Dates.TimeType; apply_tf=true)
    td = _period_step(typeof(dt2))
    if apply_tf
        apply(tf, dt1):tf.period:apply(tf, dt2-td)
    else
        dt1:tf.period:dt2-td
    end
end

function range(dt1::Dates.TimeType, tf::AbstractPeriodFrame, len::Integer)
    range(dt1, step=tf.period, length=len)
end

function range(tf::AbstractPeriodFrame, dt2::Dates.TimeType, len::Integer)
    range(dt2 - len * tf.period, step=tf.period, length=len)
end

range(dt1::DateTime, tf::NoTimeFrame, dt2::DateTime) = [dt1]

macro tf_str(tf)
  :(TimeFrame($tf))
end

promote_timetype(::Type{DateTime}, ::Type) = DateTime

promote_timetype(::Type{Date}, ::Type)              = Date
promote_timetype(::Type{Date}, ::Type{Hour})        = DateTime
promote_timetype(::Type{Date}, ::Type{Minute})      = DateTime
promote_timetype(::Type{Date}, ::Type{Second})      = DateTime
promote_timetype(::Type{Date}, ::Type{Millisecond}) = DateTime

promote_timetype(::Type{Dates.Time}, ::Type)             = Dates.Time
promote_timetype(::Type{Dates.Time}, ::Type{YearBegin})  = throw(InexactError(:none, Any, nothing))
promote_timetype(::Type{Dates.Time}, ::Type{YearEnd})    = throw(InexactError(:none, Any, nothing))
promote_timetype(::Type{Dates.Time}, ::Type{MonthBegin}) = throw(InexactError(:none, Any, nothing))
promote_timetype(::Type{Dates.Time}, ::Type{MonthEnd})   = throw(InexactError(:none, Any, nothing))
promote_timetype(::Type{Dates.Time}, ::Type{Week})       = throw(InexactError(:none, Any, nothing))
promote_timetype(::Type{Dates.Time}, ::Type{Day})        = throw(InexactError(:none, Any, nothing))

+(t::T, tf::TF) where {T<:Dates.TimeType, TF<:TimeFrame} =
  convert(promote_timetype(T, TF), t) + tf.period

+(tf::TimeFrame, t::TimeType) = t + tf

-(t::T, tf::TF) where {T<:Dates.TimeType, TF<:TimeFrame} =
  convert(promote_timetype(T, TF), t) - tf.period


*(tf::AbstractPeriodFrame, n::Int) = typeof(tf)(tf.period * n, tf.boundary)
*(n::Int, tf::AbstractPeriodFrame) = *(tf, n)


end # module
