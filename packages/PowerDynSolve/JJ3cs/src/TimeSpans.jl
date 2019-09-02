
# TODO: use time span for normal GridSolution and solve

abstract type AbstractTimeSpan end
abstract type AbstractSingleTimeSpan <: AbstractTimeSpan end
Base.convert(::Type{T}, ts) where {T <: AbstractSingleTimeSpan} = T(ts...)
Base.convert(::Type{T}, ts::T) where {T <: AbstractSingleTimeSpan} = ts

# exceptions of the PowerDynamics naming convention in order to follow the naming convention of Base
@inline Base.issorted(::AbstractSingleTimeSpan) = true
@inline iscontinuous(::AbstractSingleTimeSpan) = true

struct TimeSpan <: AbstractSingleTimeSpan
    tBegin::Time
    tEnd::Time
    function TimeSpan(tBegin::Time, tEnd::Time)
        @assert tBegin <= tEnd # We will always go forward in time.
        new(tBegin, tEnd)
    end
end
TimeSpan(tBegin, tEnd) = TimeSpan(convert(Time, tBegin), convert(Time, tEnd))

Base.in(t, tSpan::TimeSpan) = tSpan.tBegin <= t <= tSpan.tEnd
Base.convert(::Type{Tuple}, tSpan::TimeSpan) = (tSpan.tBegin, tSpan.tEnd)

function areContinuousTimeSpans(tss::Tuple{Vararg{AbstractSingleTimeSpan}})
    if length(tss) < 2 return true end # empty set of time spans and single time span are considered as continuous
    allTBegin = (ts->ts.tBegin).(tss)
    allTEnd = (ts->ts.tEnd).(tss)
    all( allTEnd[1:end-1] .== allTBegin[2:end] )
end

function areSortedTimeSpans(tss::Tuple{Vararg{AbstractSingleTimeSpan}})
    if length(tss) < 2 return true end # empty set of time spans and single time span are considered as sorted
    allTBegin = (ts->ts.tBegin).(tss)
    allTEnd = (ts->ts.tEnd).(tss)
    all( allTEnd[1:end-1] .<= allTBegin[2:end] )
end

abstract type AbstractMultipleTimeSpans{isSorted,isContinuous} <: AbstractTimeSpan end
# TODO: Implement Iteration Protocol for AbstractMultipleTimeSpans

struct MultipleTimeSpans{isSorted,isContinuous} <: AbstractMultipleTimeSpans{isSorted,isContinuous}
    tSpans::Tuple{Vararg{AbstractSingleTimeSpan}}
end
function MultipleTimeSpans(tSpans::Tuple{Vararg{AbstractSingleTimeSpan}})
    isSorted = areSortedTimeSpans(tSpans)
    isContinuous = areContinuousTimeSpans(tSpans)
    MultipleTimeSpans{isSorted,isContinuous}(tSpans)
end
MultipleTimeSpans(tss) = convert.(TimeSpan, tss) |> MultipleTimeSpans

# exceptions of the PowerDynamics naming convention in order to follow the naming convention of Base
@inline Base.issorted(::AbstractMultipleTimeSpans{isSorted}) where {isSorted} = isSorted
@inline iscontinuous(::AbstractMultipleTimeSpans{isSorted, isContinuous}) where {isSorted, isContinuous} = isContinuous

@inline Base.in(t, tSpans::AbstractMultipleTimeSpans) = any(map(ts -> in(t, ts), tSpans.tSpans))
@inline Base.getindex(tss::AbstractMultipleTimeSpans, i) = getindex(tss.tSpans, i)
@inline Base.lastindex(tss::AbstractMultipleTimeSpans) = lastindex(tss.tSpans)
@inline Base.iterate(tss::AbstractMultipleTimeSpans, args...) = Base.iterate(tss.tSpans, args...)

# convert a continuous set of time spans to a single long one
@inline Base.convert(::Type{T}, tSpans::AbstractMultipleTimeSpans{true, true}) where {T <: AbstractSingleTimeSpan} = T(tSpans[1].tBegin, tSpans[end].tEnd)

@inline Base.convert(::Type{Tuple{Vararg{TimeSpan}}}, tSpans::AbstractMultipleTimeSpans) = tSpans.tSpans
@inline Base.convert(::Type{Tuple}, tSpans::AbstractMultipleTimeSpans) = map(tSpan -> convert(Tuple, tSpan), tSpans.tSpans)

@inline Base.convert(::Type{T}, tss::Tuple) where {T <: AbstractMultipleTimeSpans} = T(map(ts -> convert(TimeSpan, ts), tss))
# to avoid error due to ambiguity:
# @inline Base.convert(::Type{T}, tss::T) where {T <: AbstractMultipleTimeSpans} = tss

# only for sorted time spans
@inline Base.findfirst(t, tSpans::MultipleTimeSpans{true}) = findfirst(ts -> t in ts, tSpans.tSpans)
