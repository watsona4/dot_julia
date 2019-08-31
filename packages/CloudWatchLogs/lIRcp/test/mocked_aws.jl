# These tests should never contact AWS

@testset "Mocked AWS Interactions" begin

CFG = AWSConfig()

function dls_patch(output)
    @patch function describe_log_streams(config; kwargs...)
        output
    end
end

put_patch = @patch function _put_log_events(stream::CloudWatchLogStream, events::AbstractVector{CloudWatchLogs.LogEvent})
    return Dict("nextSequenceToken" => "3")
end

function submit_patch(log_dump)
    @patch function submit_logs(stream::CloudWatchLogStream, events::AbstractVector{CloudWatchLogs.LogEvent})
        append!(log_dump, events)
        return length(events)
    end
end

function throttle_patch()
    first_time = true
    @patch function _put_log_events(stream::CloudWatchLogStream, events::AbstractVector{CloudWatchLogs.LogEvent})
        if first_time
            first_time = false
            response = HTTP.Messages.Response(400, "")
            http_error = HTTP.ExceptionRequest.StatusError(400, "", "", response)
            throw(AWSException("ThrottlingException", "", "", http_error))
        end 
        
        return Dict()
    end
end
            
streams = [
    Dict(
        "storageBytes" => 1048576,
        "arn" => "arn:aws:logs:us-east-1:123456789012:log-group:my-log-group-1:log-stream:my-log-stream-1",
        "creationTime" => 1393545600000,
        "firstEventTimestamp" => 1393545600000,
        "lastEventTimestamp" => 1393567800000,
        "lastIngestionTime" => 1393589200000,
        "logStreamName" => "my-log-stream-1",
        "uploadSequenceToken" => "88602967394531410094953670125156212707622379445839968487",
    ),
    Dict(
        "storageBytes" => 5242880,
        "arn" => "arn:aws:logs:us-east-1:123456789012:log-group:my-log-group-2:log-stream:my-log-stream-2",
        "creationTime" => 1396224000000,
        "firstEventTimestamp" => 1396224000000,
        "lastEventTimestamp" => 1396235500000,
        "lastIngestionTime" => 1396225560000,
        "logStreamName" => "my-log-stream-2",
        "uploadSequenceToken" => "07622379445839968487886029673945314100949536701251562127",
    ),
]

@testset "Sequence Token" begin
    # no streams
    apply(dls_patch(Dict("logStreams" => []))) do
        @test_throws LOGGER StreamNotFoundException CloudWatchLogs.new_sequence_token(CFG, "group", "stream")
    end

    # prefix-only match
    apply(dls_patch(Dict("logStreams" => streams))) do
        @test_throws LOGGER StreamNotFoundException CloudWatchLogs.new_sequence_token(CFG, "my-log-group-1", "my-log-stream")
    end

    # match
    apply(dls_patch(Dict("logStreams" => streams[1:1]))) do
        @test CloudWatchLogs.new_sequence_token(CFG, "my-log-group-1", "my-log-stream-1") == "88602967394531410094953670125156212707622379445839968487"
    end
end

@testset "CloudWatchLogStream" begin
    apply([dls_patch(Dict("logStreams" => streams)), put_patch]) do
        stream = CloudWatchLogStream(CFG, "my-log-group-1", "my-log-stream-1")
        @test CloudWatchLogs.sequence_token(stream) == "88602967394531410094953670125156212707622379445839968487"
        # no AWS requests are sent so it shouldn't matter that these timestamps are so small
        @test submit_logs(stream, [CloudWatchLogs.LogEvent("Help", 10), CloudWatchLogs.LogEvent("Alert", 124)]) == 2
        # should be the sequence token returned from the API call in put_patch
        @test CloudWatchLogs.sequence_token(stream) == "3"
    end
end

@testset "CloudWatchLogHandler" begin
    logs = CloudWatchLogs.LogEvent[]
    apply([dls_patch(Dict("logStreams" => streams[1:1])), submit_patch(logs)]) do
        cwlh = CloudWatchLogHandler(CFG, "my-log-group-1", "my-log-stream-1", DefaultFormatter("{msg}"))
        logger = Logger("CWLHTest"; propagate=false)
        push!(logger, cwlh)
        for c = 'a':'e'
            warn(logger, "$c")
        end
        sleep(5 * CloudWatchLogs.PUTLOGEVENTS_RATE_LIMIT)  # probably max time we might have to wait

        messages = map(le -> le.message, logs)
        timestamps = map(le -> le.timestamp, logs)

        @test messages == map(string, 'a':'e')
        @test issorted(timestamps)
    end
end

@testset "Throttled" begin
    start_time = CloudWatchLogs.unix_timestamp_ms()
    apply([dls_patch(Dict("logStreams" => streams)), throttle_patch()]) do
        stream = CloudWatchLogStream(CFG, "my-log-group-1", "my-log-stream-1")
        event = LogEvent("log", start_time)

        setlevel!(LOGGER, "debug") do
            @test_log LOGGER "debug" "ThrottlingException" begin
                submit_log(stream, event)
            end
        end
    end 
end

end
