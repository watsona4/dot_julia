using Test

using TimeSeries: TimeArray, timestamp
using TimeSeriesResampler: resample, TimeFrame, ohlc, mean, sum, std
using TimeFrames
using Dates

function variation(a; n=1)
    a[1+n:end] - a[1:end-n]
end

@testset "resample" begin
    # Define a sample timeseries (prices for example)
    idx = DateTime(2010,1,1):Dates.Minute(1):DateTime(2010,4,1)
    idx = idx[1:end-1]
    N = length(idx)
    y1 = rand(-1.0:0.01:1.0, N)
    y1 = 1000 .+ cumsum(y1)
    y2 = rand(-1.0:0.01:1.0, N)
    y2 = 500 .+ cumsum(y2)

    ta1 = TimeArray(collect(idx), y1, [:y1])

    #df = DataFrame(Date=idx, y=y)
    ta2 = TimeArray(collect(idx), hcat(y1, y2), [:y1, :y2])
    #println("ta=")
    #println(ta)

    a_ta = [ta1, ta2]

    # Define how datetime should be grouped (timeframe)
    a_tf = [
        TimeFrame(dt -> floor(dt, Dates.Minute(15))),  # using a lambda function
        TimeFrame(Minute(15)),  # using a TimeFrame object (from TimeFrames.jl)
        TimeFrame("15T"),  # using a string TimeFrame shortcut to create a TimeFrame
        "15T",  # using a string TimeFrame shortcut
    ]

    for ta in a_ta
        #println("ta=")
        #println(ta)

        for tf in a_tf
            println(tf)

            # resample using OHLC values
            ta_ohlc = ohlc(resample(ta, tf))
            #println("ta_ohlc=")
            #println(ta_ohlc)
            @test mean(variation(timestamp(ta_ohlc))) == Dates.Minute(15)

            ## group-by by 1 column
            ta_ohlc = ohlc(resample(ta2, tf)[:y1])
            #println("ta_ohlc=")
            #println(ta_ohlc)
            @test mean(variation(timestamp(ta_ohlc))) == Dates.Minute(15)

            ## group-by by 2 columns
            ta_ohlc = ohlc(resample(ta2, tf)[:y1, :y2])
            #println("ta_ohlc=")
            #println(ta_ohlc)
            @test mean(variation(timestamp(ta_ohlc))) == Dates.Minute(15)

            # resample using mean values
            ta_mean = mean(resample(ta, tf))
            #println("ta_mean=")
            #println(ta_mean)
            @test mean(variation(timestamp(ta_mean))) == Dates.Minute(15)

            # Define an other sample timeseries (volume for example)
            vol = rand(0:0.01:1.0, N)
            ta_vol = TimeArray(collect(idx), vol, [:vol])
            #println("ta_vol=")
            #println(ta_vol)
            @test mean(variation(timestamp(ta_vol))) == Dates.Minute(1)

            # resample using sum values
            ta_vol_sum = sum(resample(ta_vol, tf))
            #println("ta_vol_sum=")
            #println(ta_vol_sum)
            @test mean(variation(timestamp(ta_vol_sum))) == Dates.Minute(15)

            # resample using std values
            ta_vol_std = std(resample(ta_vol, tf))
            #println("ta_vol_std=")
            #println(ta_vol_std)
            @test mean(variation(timestamp(ta_vol_std))) == Dates.Minute(15)
        end
    end
end