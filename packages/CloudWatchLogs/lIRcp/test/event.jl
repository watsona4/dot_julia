@testset "LogEvent" begin

@testset "Timestamp" begin
    time_in_ms = round(Int, time() * 1000)

    event = LogEvent("Foo", time_in_ms)
    @test CloudWatchLogs.timestamp(event) == time_in_ms

    dt = DateTime(Dates.UTM(time_in_ms + Dates.UNIXEPOCH))
    event = LogEvent("Foo", dt)
    @test CloudWatchLogs.timestamp(event) == time_in_ms

    zdt = ZonedDateTime(dt, tz"UTC")
    event = LogEvent("Foo", zdt)
    @test CloudWatchLogs.timestamp(event) == time_in_ms

    event = LogEvent("Foo")
    one_hour = Dates.value(Millisecond(Hour(1)))
    @test time_in_ms <= CloudWatchLogs.timestamp(event) <= time_in_ms + one_hour
end

@testset "Message" begin
    @test CloudWatchLogs.message(LogEvent("Foo")) == "Foo"
end

@testset "Bad construction" begin
    @test_throws ArgumentError LogEvent("")
    @test_throws ArgumentError LogEvent("Foo", -45)
    @test_warn getlogger("CloudWatchLogs") "Log Event message cannot be more than" begin
        LogEvent("A" ^ (MAX_EVENT_SIZE - 25))
    end
end

end
