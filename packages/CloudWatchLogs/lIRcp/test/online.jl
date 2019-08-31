@testset "Online" begin

CI_USER_CFG = aws_config()
# do not set this variable in CI; it should be versioned with the code
# this is for locally overriding the stack used in testing
TEST_STACK_NAME = get(ENV, "CLOUDWATCHLOGSJL_STACK_NAME", "CloudWatchLogs-jl-00015")
TEST_RESOURCE_PREFIX = "pubci-$TEST_STACK_NAME-cwl-test"
TEST_LOG_GROUP = "$TEST_RESOURCE_PREFIX-group"
FORBIDDEN_LOG_GROUP = "$TEST_RESOURCE_PREFIX-group-forbidden"
FORBIDDEN_GROUP_LOG_STREAM = "$TEST_RESOURCE_PREFIX-group-forbidden-stream"
BAD_STREAM_LOG_GROUP = "$TEST_RESOURCE_PREFIX-group-badstream"
FORBIDDEN_LOG_STREAM = "$TEST_RESOURCE_PREFIX-stream-forbidden"
TEST_ROLE = stack_output(CI_USER_CFG, TEST_STACK_NAME)["LogTestRoleArn"]
CFG = aws_config(creds=assume_role(CI_USER_CFG, TEST_ROLE; DurationSeconds=7200))
LOG_RUN_ID = uuid1()

new_stream = let
    counter = 1

    function new_stream(category::AbstractString)
        stream_name = @sprintf "pubci-%s-%03d-%s" category counter LOG_RUN_ID
        counter += 1
        return stream_name
    end
end

new_group = let
    counter = 1

    function new_group(category::AbstractString)
        stream_name = @sprintf "pubci-%s-%03d-%s" category counter LOG_RUN_ID
        counter += 1
        return stream_name
    end
end

@testset "Create/delete groups and streams" begin
    @testset "Named group" begin
        group_name = new_group("create_group")
        @test create_group(CFG, group_name; tags=Dict("Temporary"=>"true")) == group_name

        response = logs(
            CFG,
            "DescribeLogGroups";
            logGroupNamePrefix=group_name,
            limit=1,
        )

        groups = response["logGroups"]

        @test !isempty(groups)
        @test groups[1]["logGroupName"] == group_name

        delete_group(CFG, group_name)

        response = logs(
            CFG,
            "DescribeLogGroups";
            logGroupNamePrefix=group_name,
            limit=1,
        )

        groups = response["logGroups"]

        @test isempty(groups) || groups[1]["logGroupName"] != group_name
    end

    @testset "Named group no tags" begin
        group_name = new_group("create_group_no_tags")
        @test create_group(CFG, group_name) == group_name

        response = logs(
            CFG,
            "DescribeLogGroups";
            logGroupNamePrefix=group_name,
            limit=1,
        )

        groups = response["logGroups"]

        @test !isempty(groups)
        @test groups[1]["logGroupName"] == group_name

        delete_group(CFG, group_name)

        response = logs(
            CFG,
            "DescribeLogGroups";
            logGroupNamePrefix=group_name,
            limit=1,
        )

        groups = response["logGroups"]

        @test isempty(groups) || groups[1]["logGroupName"] != group_name
    end

    @testset "Unnamed group" begin
        group_name = create_group(CFG; tags=Dict("Temporary"=>"true"))

        response = logs(
            CFG,
            "DescribeLogGroups";
            logGroupNamePrefix=group_name,
            limit=1,
        )

        groups = response["logGroups"]

        @test !isempty(groups)
        @test groups[1]["logGroupName"] == group_name

        delete_group(CFG, group_name)

        response = logs(
            CFG,
            "DescribeLogGroups";
            logGroupNamePrefix=group_name,
            limit=1,
        )

        groups = response["logGroups"]

        @test isempty(groups) || groups[1]["logGroupName"] != group_name
    end

    @testset "Not allowed" begin
        @test_throws AWSException create_group(CFG, "delta∆")  # invalid characters
        @test_throws AWSException delete_group(CFG, TEST_LOG_GROUP)  # explicitly forbidden
    end

    @testset "Named stream" begin
        stream_name = new_stream("create_stream")
        @test create_stream(CFG, TEST_LOG_GROUP, stream_name) == stream_name

        response = logs(
            CFG,
            "DescribeLogStreams";
            logGroupName=TEST_LOG_GROUP,
            logStreamNamePrefix=stream_name,
            orderBy="LogStreamName",  # orderBy and limit will ensure we get just the one
            limit=1,                  # matching result
        )

        streams = response["logStreams"]

        @test !isempty(streams)
        @test streams[1]["logStreamName"] == stream_name

        delete_stream(CFG, TEST_LOG_GROUP, stream_name)

        response = logs(
            CFG,
            "DescribeLogStreams";
            logGroupName=TEST_LOG_GROUP,
            logStreamNamePrefix=stream_name,
            orderBy="LogStreamName",  # orderBy and limit will ensure we get just the one
            limit=1,                  # matching result
        )

        streams = response["logStreams"]

        @test isempty(streams) || streams[1]["logStreamName"] != stream_name
    end

    @testset "Unnamed stream" begin
        stream_name = create_stream(CFG, TEST_LOG_GROUP)

        response = logs(
            CFG,
            "DescribeLogStreams";
            logGroupName=TEST_LOG_GROUP,
            logStreamNamePrefix=stream_name,
            orderBy="LogStreamName",  # orderBy and limit will ensure we get just the one
            limit=1,                  # matching result
        )

        streams = response["logStreams"]

        @test !isempty(streams)
        @test streams[1]["logStreamName"] == stream_name

        delete_stream(CFG, TEST_LOG_GROUP, stream_name)

        response = logs(
            CFG,
            "DescribeLogStreams";
            logGroupName=TEST_LOG_GROUP,
            logStreamNamePrefix=stream_name,
            orderBy="LogStreamName",  # orderBy and limit will ensure we get just the one
            limit=1,                  # matching result
        )

        streams = response["logStreams"]

        @test isempty(streams) || streams[1]["logStreamName"] != stream_name
    end

    @testset "Not allowed" begin
        @test_throws AWSException create_stream(CFG, FORBIDDEN_LOG_GROUP)
        @test_throws AWSException delete_stream(CFG, FORBIDDEN_LOG_GROUP, FORBIDDEN_GROUP_LOG_STREAM)
    end
end

@testset "CloudWatchLogStream" begin
    @testset "Normal log submission" begin
        start_time = CloudWatchLogs.unix_timestamp_ms()
        stream_name = new_stream("stream_type")
        @test create_stream(CFG, TEST_LOG_GROUP, stream_name) == stream_name

        stream = CloudWatchLogStream(CFG, TEST_LOG_GROUP, stream_name)
        @test submit_log(stream, LogEvent("Hello AWS")) == 1
        @test submit_logs(stream, LogEvent.(["Second log", "Third log"])) == 2

        sleep(2)  # wait until AWS has injested the logs; this may or may not be enough
        response = logs(
            CFG,
            "GetLogEvents";
            logGroupName=TEST_LOG_GROUP,
            logStreamName=stream_name,
            startFromHead=true,
        )

        time_range = (start_time - 10):(CloudWatchLogs.unix_timestamp_ms() + 10)

        @test length(response["events"]) == 3
        messages = map(response["events"]) do event
            @test round(Int, event["timestamp"]) in time_range
            event["message"]
        end

        @test messages == ["Hello AWS", "Second log", "Third log"]
        delete_stream(CFG, TEST_LOG_GROUP, stream_name)
    end

    @testset "Not allowed" begin
        @test_throws AWSException CloudWatchLogStream(CFG, FORBIDDEN_LOG_GROUP, FORBIDDEN_GROUP_LOG_STREAM)

        stream = CloudWatchLogStream(CFG, BAD_STREAM_LOG_GROUP, FORBIDDEN_LOG_STREAM, nothing)
        @test_throws AWSException submit_log(stream, LogEvent("Foo"))
    end

    @testset "Too many logs" begin
        start_time = CloudWatchLogs.unix_timestamp_ms()

        stream = CloudWatchLogStream(
            CFG,
            TEST_LOG_GROUP,
            create_stream(CFG, TEST_LOG_GROUP, new_stream("too_many_logs")),
        )

        events = map(Iterators.take(Iterators.countfrom(start_time), 10001)) do ts
            LogEvent("A", ts)
        end

        @test_throws LOGGER LogSubmissionException submit_logs(stream, events)
    end

    @testset "Logs too big" begin
        stream = CloudWatchLogStream(
            CFG,
            TEST_LOG_GROUP,
            create_stream(CFG, TEST_LOG_GROUP, new_stream("logs_too_big")),
        )

        event_size = CloudWatchLogs.MAX_EVENT_SIZE - 26
        events = map(1:(div(CloudWatchLogs.MAX_BATCH_SIZE, event_size) + 1)) do i
            LogEvent("A" ^ event_size)
        end
        @test_throws LOGGER LogSubmissionException submit_logs(stream, events)
    end

    @testset "Logs too spread" begin
        stream = CloudWatchLogStream(
            CFG,
            TEST_LOG_GROUP,
            create_stream(CFG, TEST_LOG_GROUP, new_stream("logs_too_spread")),
        )

        last_time = Dates.now(tz"UTC")
        first_time = last_time - Hour(25)

        events = [LogEvent("First", first_time), LogEvent("Last", last_time)]

        @test_throws LOGGER LogSubmissionException submit_logs(stream, events)
    end

    @testset "Invalid sequence token" begin
        stream = CloudWatchLogStream(
            CFG,
            TEST_LOG_GROUP,
            create_stream(CFG, TEST_LOG_GROUP, new_stream("invalid_token")),
        )

        @test submit_log(stream, LogEvent("Foo")) == 1
        CloudWatchLogs.update_sequence_token!(stream, "oops_invalid")
        setlevel!(LOGGER, "debug") do
            @test_log LOGGER "debug" "InvalidSequenceTokenException" begin
                submit_log(stream, LogEvent("Second time's the charm"))
            end
        end
    end

    @testset "Unsorted logs" begin
        stream_name = new_stream("unsorted")
        stream = CloudWatchLogStream(
            CFG,
            TEST_LOG_GROUP,
            create_stream(CFG, TEST_LOG_GROUP, stream_name),
        )

        current_time = Dates.now(tz"UTC")
        events = [
            LogEvent("First hey", current_time),
            LogEvent("Second hey", current_time + Second(1)),
            LogEvent("Third hey", current_time - Second(1)),
        ]

        setlevel!(LOGGER, "debug") do
            @test_log LOGGER "debug" "sorted" begin
                @test submit_logs(stream, events) == 3
            end
        end

        sleep(1)  # wait until AWS has injested the logs; this may or may not be enough
        response = logs(
            CFG,
            "GetLogEvents";
            logGroupName=TEST_LOG_GROUP,
            logStreamName=stream_name,
            startFromHead=true,
        )

        @test length(response["events"]) == 3
        messages = [event["message"] for event in response["events"]]
        @test messages == ["Third hey", "First hey", "Second hey"]
        delete_stream(CFG, TEST_LOG_GROUP, stream_name)
    end

    @testset "Rejected Logs" begin
        stream_name = new_stream("out_of_bounds")
        stream = CloudWatchLogStream(
            CFG,
            TEST_LOG_GROUP,
            create_stream(CFG, TEST_LOG_GROUP, stream_name),
        )

        current_time = Dates.now(tz"UTC")

        @test_warn LOGGER "retention policy" begin
            @test submit_log(stream, LogEvent("Way old", current_time - Day(8))) == 0
        end

        @test_warn LOGGER "days old" begin
            @test submit_log(stream, LogEvent("Too old", current_time - Day(15))) == 0
        end

        @test_warn LOGGER "hours in the future" begin
            @test submit_log(stream, LogEvent("Too new", current_time + Hour(3))) == 0
        end

        delete_stream(CFG, TEST_LOG_GROUP, stream_name)
    end

    @testset "Stream not found" begin
        @test_throws LOGGER StreamNotFoundException CloudWatchLogStream(
            CFG,
            TEST_LOG_GROUP,
            "made-up-stream-that-doesnt-exist",
        )
    end
end

@testset "CloudWatchLogHandler" begin
    @testset "Normal logging" begin
        start_time = CloudWatchLogs.unix_timestamp_ms()
        stream_name = new_stream("handler_type")

        handler = setlevel!(LOGGER, "debug") do
            @test_log LOGGER "debug" "initiated" begin
                handler = CloudWatchLogHandler(
                    CFG,
                    TEST_LOG_GROUP,
                    create_stream(CFG, TEST_LOG_GROUP, stream_name),
                    DefaultFormatter("{level} | {msg}"),
                )
                sleep(1)
            end

            handler
        end
        logger = Logger("CWLHLive.Normal"; propagate=false)
        push!(logger, handler)

        info(logger, "First log")
        warn(logger, "Second log")

        sleep(1)   # wait for the handler to submit the logs
        @test !isready(handler.channel)

        sleep(1)  # wait until AWS has injested the logs; this may or may not be enough
        response = logs(
            CFG,
            "GetLogEvents";
            logGroupName=TEST_LOG_GROUP,
            logStreamName=stream_name,
            startFromHead=true,
        )

        time_range = (start_time - 10):(CloudWatchLogs.unix_timestamp_ms() + 10)

        @test length(response["events"]) == 2
        messages = map(response["events"]) do event
            @test round(Int, event["timestamp"]) in time_range
            event["message"]
        end

        @test messages == ["info | First log", "warn | Second log"]

        setlevel!(LOGGER, "debug") do
            # should cause the task to terminate with a debug message
            @test_log LOGGER "debug" "terminated normally" begin
                close(handler.channel)
                sleep(1)
            end
        end

        delete_stream(CFG, TEST_LOG_GROUP, stream_name)
    end

    @testset "Big logs" begin
        stream_name = new_stream("handler_big_logs")
        handler = CloudWatchLogHandler(
            CFG,
            TEST_LOG_GROUP,
            create_stream(CFG, TEST_LOG_GROUP, stream_name),
            DefaultFormatter("{msg}"),
        )
        logger = Logger("CWLHLive.Big"; propagate=false)
        push!(logger, handler)

        log_size = CloudWatchLogs.MAX_EVENT_SIZE - 26

        num_events = 26
        for (c, i) in zip('A':'Z', 1:num_events)
            info(logger, "$c" ^ log_size)
        end

        # wait for the logs to be submitted and for AWS to injest them
        sleep(10)
        response = logs(
            CFG,
            "GetLogEvents";
            logGroupName=TEST_LOG_GROUP,
            logStreamName=stream_name,
        )
        prev_token = ""
        num_events_injested = 0
        while prev_token != response["nextBackwardToken"]
            prev_token = response["nextBackwardToken"]
            @test length(response["events"]) <= 4
            num_events_injested += length(response["events"])

            response = logs(
                CFG,
                "GetLogEvents";
                logGroupName=TEST_LOG_GROUP,
                logStreamName=stream_name,
                nextToken=prev_token,
            )
        end
        @test num_events_injested == num_events
        delete_stream(CFG, TEST_LOG_GROUP, stream_name)
    end

    @testset "So many logs" begin
        start_time = CloudWatchLogs.unix_timestamp_ms()
        stream_name = new_stream("handler_so_many_logs")
        handler = CloudWatchLogHandler(
            CFG,
            TEST_LOG_GROUP,
            create_stream(CFG, TEST_LOG_GROUP, stream_name),
            DefaultFormatter("{msg}"),
        )
        logger = Logger("CWLHLive.SoMany"; propagate=false)
        push!(logger, handler)

        # not sure if this will actually go over the batch limit but we'll try
        max_num = CloudWatchLogs.MAX_BATCH_LENGTH * 2
        for i = 1:max_num
            info(logger, "$i")
        end

        # wait for the logs to be submitted
        for delay in CloudWatchLogs.PUTLOGEVENTS_DELAYS
            isready(handler.channel) || break
            sleep(delay)
        end

        sleep(1)  # wait until AWS has injested the logs; this may or may not be enough
        response = logs(
            CFG,
            "GetLogEvents";
            logGroupName=TEST_LOG_GROUP,
            logStreamName=stream_name,
            startFromHead=true,
            limit=1,
        )

        @test length(response["events"]) == 1
        event = response["events"][1]
        @test event["message"] == "1"

        sleep(5)  # wait until AWS has injested the logs; this may or may not be enough
        response = logs(
            CFG,
            "GetLogEvents";
            logGroupName=TEST_LOG_GROUP,
            logStreamName=stream_name,
            startFromHead=false,
            limit=1,
        )

        @test length(response["events"]) == 1
        event = response["events"][1]
        @test event["message"] == "$max_num"

        delete_stream(CFG, TEST_LOG_GROUP, stream_name)
    end
end

end
