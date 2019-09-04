using TimeSeries: TimeArray, collapse
using TimeSeries: timestamp, values, colnames
using TimeFrames: TimeFrame, dt_grouper, Begin, End
import Base: sum, getindex
import Statistics: mean
import Statistics: std

abstract type AbstractAction end

struct TimeArrayResampler <: AbstractAction
    ta::TimeArray
    tf::TimeFrame
end

struct GroupBy
    action::AbstractAction
    by::Vector{Symbol}
end

function resample(ta::TimeArray, tf::TimeFrame)
    TimeArrayResampler(ta, tf)
end

function resample(ta::TimeArray, tf)
    resample(ta, TimeFrame(tf))
end

function getindex(action::TimeArrayResampler, by...)
    action = TimeArrayResampler(action.ta[by...], action.tf)
    by = collect(by)
    GroupBy(action, by)
end

function ohlc(grp::GroupBy)
    ohlc(grp.action)
end

function ohlc(resampler::TimeArrayResampler)
    ta = resampler.ta
    f_group = dt_grouper(resampler.tf, eltype(timestamp(ta)))
    ta_o = collapse(ta, f_group, first, first)
    ta_h = collapse(ta, f_group, first, maximum)
    ta_l = collapse(ta, f_group, first, minimum)
    ta_c = collapse(ta, f_group, first, last)
    a_ohlc = hcat(values(ta_o), values(ta_h), values(ta_l), values(ta_c))
    ts = map(f_group, timestamp(ta_o))
    col_ohlc = [:Open, :High, :Low, :Close]
    if length(colnames(ta)) == 1
        _colnames = col_ohlc
    else
        _colnames = Symbol[]
        for col in colnames(ta)
            for col2 in col_ohlc
                new_col = String(col) * "_" * String(col2)
                push!(_colnames, Symbol(new_col))
            end
        end
    end
    ta_ohlc = TimeArray(ts, a_ohlc, _colnames)
end

function mean(grp::GroupBy)
    mean(grp.action)
end

function mean(resampler::TimeArrayResampler)
    f_group = dt_grouper(resampler.tf, eltype(timestamp(resampler.ta)))
    collapse(resampler.ta, f_group, dt -> f_group(first(dt)), mean)
end

function sum(grp::GroupBy)
    sum(grp.action)
end

function sum(resampler::TimeArrayResampler)
    f_group = dt_grouper(resampler.tf, eltype(timestamp(resampler.ta)))
    collapse(resampler.ta, f_group, dt -> f_group(first(dt)), sum)
end

function std(grp::GroupBy)
    std(grp.action)
end

function std(resampler::TimeArrayResampler)
    f_group = dt_grouper(resampler.tf, eltype(timestamp(resampler.ta)))
    collapse(resampler.ta, f_group, dt -> f_group(first(dt)), std)
end
